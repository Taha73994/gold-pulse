"""توليد التنبيهات عند تغيّر الإشارة أو تحرك السعر."""
import json
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from .config import ALERT_MINUTES, DISCLAIMER, PRICE_ALERT_MINUTES, PRICE_ALERT_PCT
from .models import Alert, SignalSnapshot

ACTION_AR = {
    "BUY": "شراء",
    "ACCUMULATE": "تجميع تدريجي",
    "WAIT": "انتظار ومراقبة",
    "REDUCE": "تخفيف",
    "SELL": "بيع",
}
ACTION_EN = {
    "BUY": "Buy",
    "ACCUMULATE": "Accumulate",
    "WAIT": "Wait & watch",
    "REDUCE": "Reduce",
    "SELL": "Sell",
}


def _fmt(value: float) -> str:
    return f"{value:,.0f}"


def record_analysis(db: Session, analysis: dict) -> list[Alert]:
    now = datetime.utcnow()
    last = db.query(SignalSnapshot).order_by(SignalSnapshot.id.desc()).first()
    price = float(analysis.get("price") or 0)
    action = analysis.get("action", "WAIT")
    score = float(analysis.get("score") or 0)
    confidence = int(analysis.get("confidence") or 0)

    if last and last.created_at and now - last.created_at < timedelta(minutes=ALERT_MINUTES):
        if last.action == action and abs(score - last.score) < 5:
            return []

    snapshot = SignalSnapshot(
        created_at=now,
        action=action,
        action_label=ACTION_AR.get(action, action),
        score=score,
        confidence=confidence,
        price=price,
        horizon=analysis.get("horizon", ""),
        payload=json.dumps(
            {
                "short_score": analysis.get("short_term", {}).get("score"),
                "swing_score": analysis.get("swing", {}).get("score"),
                "regime": analysis.get("regime"),
            },
            ensure_ascii=False,
        ),
    )
    db.add(snapshot)

    alerts: list[Alert] = []

    if not last:
        alerts.append(
            Alert(
                created_at=now,
                kind="system",
                severity="info",
                title="بدأ نبض الذهب بمراقبة السوق",
                title_en="Gold Pulse started monitoring the market",
                body=(
                    f"الإشارة الحالية: {ACTION_AR.get(action, action)} — السعر {_fmt(price)}$ للأونصة. "
                    "سننبهك عند تغيّر الإشارة أو تحرك سعر مؤثر."
                ),
                body_en=(
                    f"Current signal: {ACTION_EN.get(action, action)} — price ${_fmt(price)}/oz. "
                    "We will alert you when the signal changes or a material move happens."
                ),
                action=action,
                price=price,
            )
        )
    else:
        last_ar = ACTION_AR.get(last.action, last.action_label or last.action)
        last_en = ACTION_EN.get(last.action, last.action_label or last.action)
        new_ar = ACTION_AR.get(action, action)
        new_en = ACTION_EN.get(action, action)

        if last.action != action:
            severity = "high" if action in ("BUY", "SELL") else "medium"
            alerts.append(
                Alert(
                    created_at=now,
                    kind="signal",
                    severity=severity,
                    title=f"تغيّرت الإشارة: {new_ar}",
                    title_en=f"Signal changed: {new_en}",
                    body=(
                        f"الانتقال من «{last_ar}» إلى «{new_ar}» عند {_fmt(price)}$ للأونصة. "
                        f"الثقة {confidence}%. راجع خطة الأسبوع قبل التنفيذ."
                    ),
                    body_en=(
                        f"Moved from “{last_en}” to “{new_en}” at ${_fmt(price)}/oz. "
                        f"Confidence {confidence}%. Review the weekly plan before acting."
                    ),
                    action=action,
                    price=price,
                )
            )
        else:
            if last.score < 30 <= score:
                alerts.append(
                    Alert(
                        created_at=now,
                        kind="momentum",
                        severity="high",
                        title="تحسّن الزخم: الإشارة تجاوزت +30",
                        title_en="Momentum improved: score crossed +30",
                        body=(
                            f"درجة الإشارة ارتفعت من {last.score:.0f} إلى {score:.0f}. "
                            f"السعر {_fmt(price)}$ — راقب تأكيد الاختراق قبل الدخول الكامل."
                        ),
                        body_en=(
                            f"The signal score rose from {last.score:.0f} to {score:.0f}. "
                            f"Price ${_fmt(price)} — watch for breakout confirmation before a full entry."
                        ),
                        action=action,
                        price=price,
                    )
                )
            if last.score > -30 >= score:
                alerts.append(
                    Alert(
                        created_at=now,
                        kind="momentum",
                        severity="high",
                        title="تدهور الزخم: الإشارة كسرت -30",
                        title_en="Momentum deteriorated: score broke -30",
                        body=(
                            f"درجة الإشارة انخفضت من {last.score:.0f} إلى {score:.0f}. "
                            f"السعر {_fmt(price)}$ — راجع وقف الخسارة وقلّل المخاطرة."
                        ),
                        body_en=(
                            f"The signal score fell from {last.score:.0f} to {score:.0f}. "
                            f"Price ${_fmt(price)} — review your stop loss and cut risk."
                        ),
                        action=action,
                        price=price,
                    )
                )

        if last.price and price:
            move = (price - last.price) / last.price * 100
            cutoff = now - timedelta(minutes=PRICE_ALERT_MINUTES)
            recent = (
                db.query(Alert)
                .filter(Alert.kind == "price", Alert.created_at >= cutoff)
                .first()
            )
            if abs(move) >= PRICE_ALERT_PCT and not recent:
                rising = move > 0
                if rising:
                    title = f"ارتفاع سعر الأونصة {move:+.2f}%"
                    title_en = f"Gold ounce rose {move:+.2f}%"
                    body = (
                        f"صعد السعر من {_fmt(last.price)}$ إلى {_fmt(price)}$ للأونصة. "
                        "لا تطارد الارتفاع؛ انتظر تهدئة أو اختراقاً مؤكداً قبل الشراء، "
                        "وجهّز هدف بيع إن كنت تحتفظ بمركز رابح."
                    )
                    body_en = (
                        f"Price rose from ${_fmt(last.price)} to ${_fmt(price)}/oz. "
                        "Do not chase the move; wait for a pause or a confirmed breakout before buying, "
                        "and prepare a profit target if you already hold."
                    )
                else:
                    title = f"انخفاض سعر الأونصة {move:+.2f}%"
                    title_en = f"Gold ounce fell {move:+.2f}%"
                    body = (
                        f"هبط السعر من {_fmt(last.price)}$ إلى {_fmt(price)}$ للأونصة. "
                        "تصحيح محتمل: راقب الدعم القريب قبل الشراء التدريجي، ولا تبع بدافع الخوف "
                        "إذا كانت خطتك طويلة الأمد."
                    )
                    body_en = (
                        f"Price fell from ${_fmt(last.price)} to ${_fmt(price)}/oz. "
                        "A possible pullback: watch nearby support before scaling in, and do not sell "
                        "out of fear if your plan is long term."
                    )
                alerts.append(
                    Alert(
                        created_at=now,
                        kind="price",
                        severity="medium" if abs(move) < 1.8 else "high",
                        title=title,
                        title_en=title_en,
                        body=body,
                        body_en=body_en,
                        action=action,
                        price=price,
                    )
                )

    forecast = analysis.get("forecast") or {}
    fsummary = forecast.get("summary") or {}
    prepare = fsummary.get("prepare")
    if prepare in ("prepare_buy", "prepare_sell") and forecast.get("ok"):
        direction_action = "BUY" if prepare == "prepare_buy" else "SELL"
        cutoff = now - timedelta(hours=24)
        exists = (
            db.query(Alert)
            .filter(
                Alert.kind == "forecast",
                Alert.action == direction_action,
                Alert.created_at >= cutoff,
            )
            .first()
        )
        if not exists:
            days = int(fsummary.get("days") or 5)
            up = float(fsummary.get("up_probability") or 0)
            down = float(fsummary.get("down_probability") or 0)
            low = float(fsummary.get("range_low") or 0)
            high = float(fsummary.get("range_high") or 0)
            expected = float(fsummary.get("expected") or 0)
            fconf = int(fsummary.get("confidence") or 0)
            if direction_action == "BUY":
                title = f"استعد للشراء خلال {days} جلسات — احتمال الصعود {up:.0f}%"
                title_en = f"Prepare to buy within {days} sessions — {up:.0f}% upside odds"
                body = (
                    f"النموذج يقدّر نطاقاً بين {_fmt(low)}$ و{_fmt(high)}$، بسعر متوقع {_fmt(expected)}$ "
                    f"وثقة {fconf}%. جهّز دفعة أولى ولا تشترِ كامل المبلغ. هذه احتمالات وليست ضماناً."
                )
                body_en = (
                    f"The model estimates a range of ${_fmt(low)}–${_fmt(high)}, an expected price of "
                    f"${_fmt(expected)}, and {fconf}% model confidence. Prepare a first tranche; do not buy "
                    "the full amount. These are probabilities, not a guarantee."
                )
            else:
                title = f"استعد للبيع/التخفيف خلال {days} جلسات — احتمال الهبوط {down:.0f}%"
                title_en = f"Prepare to sell/trim within {days} sessions — {down:.0f}% downside odds"
                body = (
                    f"النموذج يقدّر نطاقاً بين {_fmt(low)}$ و{_fmt(high)}$، بسعر متوقع {_fmt(expected)}$ "
                    f"وثقة {fconf}%. راجع وقف الخسارة وجهّز خطة تخفيف. هذه احتمالات وليست ضماناً."
                )
                body_en = (
                    f"The model estimates a range of ${_fmt(low)}–${_fmt(high)}, an expected price of "
                    f"${_fmt(expected)}, and {fconf}% model confidence. Review your stop and prepare a trim "
                    "plan. These are probabilities, not a guarantee."
                )
            alerts.append(
                Alert(
                    created_at=now,
                    kind="forecast",
                    severity="high" if direction_action != action else "medium",
                    title=title,
                    title_en=title_en,
                    body=body,
                    body_en=body_en,
                    action=direction_action,
                    price=price,
                )
            )

    if alerts:
        db.add_all(alerts)
    db.commit()
    return alerts


def list_alerts(db: Session, limit: int = 60) -> dict:
    rows = db.query(Alert).order_by(Alert.id.desc()).limit(limit).all()
    snapshots = (
        db.query(SignalSnapshot).order_by(SignalSnapshot.id.desc()).limit(30).all()
    )
    unread = db.query(Alert).filter(Alert.is_read.is_(False)).count()
    return {
        "ok": True,
        "unread": unread,
        "items": [
            {
                "id": a.id,
                "created_at": a.created_at.isoformat() if a.created_at else None,
                "kind": a.kind,
                "severity": a.severity,
                "title": a.title,
                "title_en": a.title_en or a.title,
                "body": a.body,
                "body_en": a.body_en or a.body,
                "action": a.action,
                "price": a.price,
                "is_read": a.is_read,
            }
            for a in rows
        ],
        "signal_history": [
            {
                "id": s.id,
                "created_at": s.created_at.isoformat() if s.created_at else None,
                "action": s.action,
                "action_label": s.action_label,
                "score": s.score,
                "confidence": s.confidence,
                "price": s.price,
            }
            for s in reversed(snapshots)
        ],
        "disclaimer": DISCLAIMER,
    }
