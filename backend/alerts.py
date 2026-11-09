"""توليد التنبيهات عند تغيّر الإشارة أو تحرك السعر."""
import json
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from .config import (
    ALERT_MINUTES,
    DISCLAIMER,
    OUNCE_GRAMS,
    PRICE_ALERT_MINUTES,
    PRICE_ALERT_PCT,
    RATE_ALERT_COOLDOWN_MINUTES,
    RATE_ALERT_IQD,
    RATE_ALERT_WINDOW_MINUTES,
    RATE_SNAPSHOT_MINUTES,
)
from .models import Alert, RateSnapshot, SignalSnapshot

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
    # لا نرسل تنبيه توقع إلا عند أفضلية واضحة وثقة كافية، وبعد اتفاق
    # سيناريو التوقع مع الإشارة (يمنعه _prepare مسبقاً).
    up_now = float(fsummary.get("up_probability") or 0)
    down_now = float(fsummary.get("down_probability") or 0)
    edge_now = max(up_now, down_now)
    fconf_now = int(fsummary.get("confidence") or 0)
    if (
        prepare in ("prepare_buy", "prepare_sell")
        and forecast.get("ok")
        and edge_now >= 60.0
        and fconf_now >= 52
    ):
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
            up = up_now
            down = down_now
            low = float(fsummary.get("range_low") or 0)
            high = float(fsummary.get("range_high") or 0)
            expected = float(fsummary.get("expected") or 0)
            fconf = fconf_now
            if direction_action == "BUY":
                title = f"سيناريو صاعد خلال {days} جلسات — احتمال الصعود {up:.0f}%"
                title_en = f"Upside scenario over {days} sessions — {up:.0f}% upside odds"
                body = (
                    f"النموذج يقدّر نطاقاً بين {_fmt(low)}$ و{_fmt(high)}$، بسعر متوقع {_fmt(expected)}$ "
                    f"وثقة {fconf}%. الاحتمال {up:.0f}% صعود مقابل {down:.0f}% هبوط — "
                    "جهّز دفعة أولى ولا تشترِ كامل المبلغ. هذه احتمالات وليست ضماناً."
                )
                body_en = (
                    f"The model estimates a range of ${_fmt(low)}–${_fmt(high)}, an expected price of "
                    f"${_fmt(expected)}, and {fconf}% model confidence. Odds are {up:.0f}% up vs {down:.0f}% down — "
                    "prepare a first tranche; do not buy the full amount. These are probabilities, not a guarantee."
                )
            else:
                title = f"سيناريو هابط خلال {days} جلسات — احتمال الهبوط {down:.0f}%"
                title_en = f"Downside scenario over {days} sessions — {down:.0f}% downside odds"
                body = (
                    f"النموذج يقدّر نطاقاً بين {_fmt(low)}$ و{_fmt(high)}$، بسعر متوقع {_fmt(expected)}$ "
                    f"وثقة {fconf}%. الاحتمال {down:.0f}% هبوط مقابل {up:.0f}% صعود — "
                    "راجع وقف الخسارة وجهّز خطة تخفيف. هذه احتمالات وليست ضماناً."
                )
                body_en = (
                    f"The model estimates a range of ${_fmt(low)}–${_fmt(high)}, an expected price of "
                    f"${_fmt(expected)}, and {fconf}% model confidence. Odds are {down:.0f}% down vs {up:.0f}% up — "
                    "review your stop and prepare a trim plan. These are probabilities, not a guarantee."
                )
            alerts.append(
                Alert(
                    created_at=now,
                    kind="forecast",
                    severity="high" if edge_now >= 65 and fconf >= 60 else "medium",
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


def record_rate(db: Session, fx: dict, usd_oz: float = 0) -> dict:
    """يراقب سعر صرف السوق الموازي ويولّد تنبيهاً عند صعوده أو نزوله.

    المقارنة تكون مع قراءة قديمة لا تقل عن RATE_ALERT_WINDOW_MINUTES،
    مع كتم التنبيهات المتكررة خلال RATE_ALERT_COOLDOWN_MINUTES.
    """
    now = datetime.utcnow()
    parallel = float(fx.get("parallel_sell") or fx.get("parallel_mid") or 0)
    official = float(fx.get("official") or 0)
    gap = float(fx.get("gap_pct") or 0)
    source = str(fx.get("source") or "")
    info = {
        "parallel": round(parallel, 2),
        "official": round(official, 2),
        "gap_pct": round(gap, 2),
        "previous": None,
        "change": 0.0,
        "change_pct": 0.0,
        "change_today": 0.0,
        "change_today_pct": 0.0,
        "published_at": fx.get("published_at") or "",
        "estimated": bool(fx.get("estimated")),
        "source": source,
    }
    if parallel <= 0:
        return info

    last = db.query(RateSnapshot).order_by(RateSnapshot.id.desc()).first()
    day_start = datetime(now.year, now.month, now.day)
    today_first = (
        db.query(RateSnapshot)
        .filter(RateSnapshot.created_at >= day_start)
        .order_by(RateSnapshot.id.asc())
        .first()
    )
    if today_first and today_first.parallel > 0:
        diff_today = parallel - today_first.parallel
        info["change_today"] = round(diff_today, 2)
        info["change_today_pct"] = round(diff_today / today_first.parallel * 100, 2)

    window_start = now - timedelta(minutes=RATE_ALERT_WINDOW_MINUTES)
    ref = (
        db.query(RateSnapshot)
        .filter(RateSnapshot.created_at <= window_start)
        .order_by(RateSnapshot.id.desc())
        .first()
    )

    alerts: list[Alert] = []
    if ref and ref.parallel > 0:
        diff = parallel - ref.parallel
        pct = diff / ref.parallel * 100
        info["previous"] = round(ref.parallel, 2)
        info["change"] = round(diff, 2)
        info["change_pct"] = round(pct, 2)

        cooldown = now - timedelta(minutes=RATE_ALERT_COOLDOWN_MINUTES)
        recent = (
            db.query(Alert)
            .filter(Alert.kind == "rate", Alert.created_at >= cooldown)
            .first()
        )
        if abs(diff) >= RATE_ALERT_IQD and not recent:
            rising = diff > 0
            severity = "high" if abs(diff) >= RATE_ALERT_IQD * 3 else "medium"
            direction_ar = "صعد" if rising else "نزل"
            direction_en = "rose" if rising else "fell"
            title = f"سعر السوق الموازي {direction_ar} {abs(diff):,.0f} د.ع"
            title_en = f"Parallel dollar rate {direction_en} {abs(diff):,.0f} IQD"
            gram_note_ar = ""
            gram_note_en = ""
            if usd_oz > 0:
                gram_delta = usd_oz / OUNCE_GRAMS * diff
                gram_note_ar = (
                    f" يعني تغيّراً بنحو {abs(gram_delta):,.0f} د.ع في غرام عيار 24."
                )
                gram_note_en = (
                    f" That is about {abs(gram_delta):,.0f} IQD per 24K gram."
                )
            body = (
                f"انتقل سعر الدولار في السوق الموازي من {_fmt(ref.parallel)} إلى "
                f"{_fmt(parallel)} د.ع، أي {diff:+,.0f} د.ع ({pct:+.2f}%). "
                f"السعر الرسمي {_fmt(official)} د.ع والفارق {gap:.1f}%."
                f"{gram_note_ar} راقب الأثر على سعر الذهب قبل الشراء أو البيع."
            )
            body_en = (
                f"The parallel USD/IQD rate moved from {_fmt(ref.parallel)} to "
                f"{_fmt(parallel)}, a change of {diff:+,.0f} IQD ({pct:+.2f}%). "
                f"The official rate is {_fmt(official)} with a {gap:.1f}% gap."
                f"{gram_note_en} Watch the impact on gold before buying or selling."
            )
            alerts.append(
                Alert(
                    created_at=now,
                    kind="rate",
                    severity=severity,
                    title=title,
                    title_en=title_en,
                    body=body,
                    body_en=body_en,
                    action="RATE_UP" if rising else "RATE_DOWN",
                    price=usd_oz,
                )
            )

    should_store = last is None or (
        now - last.created_at >= timedelta(minutes=RATE_SNAPSHOT_MINUTES)
    )
    if should_store:
        db.add(
            RateSnapshot(
                created_at=now,
                parallel=parallel,
                official=official,
                gap_pct=gap,
                source=source,
            )
        )
    if alerts:
        db.add_all(alerts)
    try:
        db.commit()
    except Exception:
        db.rollback()
    return info


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
