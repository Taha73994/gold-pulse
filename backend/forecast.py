"""توقعات احتمالية قصيرة المدى للذهب (مونت كارلو) — تقديرات وليست ضمانات."""
import math
import random
from datetime import datetime, timezone
from statistics import mean, pstdev

from .i18n import t


def _percentile(sorted_values: list[float], p: float) -> float:
    if not sorted_values:
        return 0.0
    index = int(round(p * (len(sorted_values) - 1)))
    return sorted_values[max(0, min(len(sorted_values) - 1, index))]


def _log_returns(closes: list[float]) -> list[float]:
    out = []
    for i in range(1, len(closes)):
        if closes[i - 1] > 0 and closes[i] > 0:
            out.append(math.log(closes[i] / closes[i - 1]))
    return out


def _prepare(direction: str, action: str, lang: str) -> tuple[str, str]:
    """لا نوصي بشراء/بيع إلا إذا اتفق سيناريو التوقع مع إشارة التحليل.

    هذا يمنع التناقض الذي كان يحدث سابقاً: توقع هبوط بينما الإشارة
    قصيرة المدى صاعدة (أو العكس)، فيظهر تنبيه مضلل للمستخدم.
    """
    bullish = action in ("BUY", "ACCUMULATE")
    bearish = action in ("REDUCE", "SELL")
    if direction == "up" and bullish:
        return (
            "prepare_buy",
            t(
                lang,
                "استعد للشراء على دفعات — ولا تطارد السعر.",
                "Prepare to buy in tranches — do not chase the price.",
            ),
        )
    if direction == "down" and bearish:
        return (
            "prepare_sell",
            t(
                lang,
                "استعد لتخفيف المركز أو البيع — واحمِ رأس المال.",
                "Prepare to trim or sell — protect your capital.",
            ),
        )
    if direction == "up":
        return (
            "wait",
            t(
                lang,
                "هناك ميل صاعد طفيف لكنه لا يتفق مع الإشارة الحالية؛ انتظر تأكيداً.",
                "There is a slight upside tilt, but it does not agree with the current signal; wait for confirmation.",
            ),
        )
    if direction == "down":
        return (
            "wait",
            t(
                lang,
                "هناك ميل هابط طفيف لكنه لا يتفق مع الإشارة الحالية؛ انتظر تأكيداً.",
                "There is a slight downside tilt, but it does not agree with the current signal; wait for confirmation.",
            ),
        )
    return (
        "wait",
        t(
            lang,
            "لا توجد أفضلية واضحة؛ انتظر تأكيداً قبل التحرك.",
            "No clear edge; wait for confirmation before acting.",
        ),
    )


def build_forecast(
    candles: list[dict],
    score: float,
    action: str,
    confidence: int,
    rsi_value: float | None,
    lang: str = "ar",
    agreement: float = 1.0,
) -> dict:
    closes = [float(c["close"]) for c in candles if c.get("close")]
    if len(closes) < 40:
        return {
            "ok": False,
            "horizons": [],
            "summary": {
                "direction": "neutral",
                "headline": t(lang, "بيانات غير كافية للتوقع", "Not enough data to forecast"),
                "note": "",
            },
        }

    last = closes[-1]
    returns = _log_returns(closes)[-120:]
    sigma = max(0.0035, pstdev(returns) if len(returns) > 2 else 0.01)

    # تعارض الأطر الزمنية يوسّع عدم اليقين بدل اختلاق اتجاه وهمي.
    agreement = max(0.0, min(1.0, float(agreement)))
    sigma *= 1.0 + 0.35 * (1.0 - agreement)

    hist_drift = mean(returns[-20:]) if len(returns) >= 20 else 0.0
    hist_drift = max(-sigma * 0.6, min(sigma * 0.6, hist_drift))

    # ميل الإشارة: الدرجة تعدّل الانجراف اليومي بشكل محدود
    signal_drift = (score / 100.0) * sigma * 0.30

    # تصحيح بسيط عند التشبع
    if rsi_value is not None:
        if rsi_value > 72:
            signal_drift -= sigma * 0.12
        elif rsi_value < 30:
            signal_drift += sigma * 0.12

    conflict_shrink = 0.55 + 0.45 * agreement
    mu = (0.45 * hist_drift + 0.55 * signal_drift) * conflict_shrink
    mu = max(-sigma * 0.45, min(sigma * 0.45, mu))

    day_seed = datetime.now(timezone.utc).timetuple().tm_yday
    seed = int(last * 97) + day_seed * 31
    rng = random.Random(seed)

    horizons = []
    paths = 1600
    for days in (2, 5, 7):
        finals = []
        for _ in range(paths):
            price = last
            for _ in range(days):
                price *= math.exp(mu + sigma * rng.gauss(0, 1))
            finals.append(price)
        finals.sort()
        up_prob = sum(1 for value in finals if value > last) / paths
        down_prob = 1 - up_prob
        expected = sum(finals) / paths
        low = _percentile(finals, 0.10)
        high = _percentile(finals, 0.90)
        expected_change = (expected - last) / last * 100
        # لا نعلن اتجاهاً إلا عند أفضلية واضحة (60/40)، وإلا نبقى محايدين.
        direction = "up" if up_prob >= 0.60 else "down" if up_prob <= 0.40 else "neutral"
        prepare_code, prepare_text = _prepare(direction, action, lang)
        edge = abs(up_prob - 0.5) * 100

        if direction == "up":
            label = t(
                lang,
                f"احتمال الصعود {up_prob * 100:.0f}%",
                f"{up_prob * 100:.0f}% upside probability",
            )
            narrative = t(
                lang,
                f"خلال {days} جلسات تداول، يرجّح النموذج الصعود بنسبة {up_prob * 100:.0f}%، "
                f"مع نطاق متوقع بين {low:,.0f}$ و{high:,.0f}$.",
                f"Over {days} trading sessions the model favours upside at {up_prob * 100:.0f}%, "
                f"with an expected range of ${low:,.0f}–${high:,.0f}.",
            )
        elif direction == "down":
            label = t(
                lang,
                f"احتمال الهبوط {down_prob * 100:.0f}%",
                f"{down_prob * 100:.0f}% downside probability",
            )
            narrative = t(
                lang,
                f"خلال {days} جلسات تداول، يرجّح النموذج الهبوط بنسبة {down_prob * 100:.0f}%، "
                f"مع نطاق متوقع بين {low:,.0f}$ و{high:,.0f}$.",
                f"Over {days} trading sessions the model favours downside at {down_prob * 100:.0f}%, "
                f"with an expected range of ${low:,.0f}–${high:,.0f}.",
            )
        else:
            label = t(
                lang,
                f"احتمال الصعود {up_prob * 100:.0f}%",
                f"{up_prob * 100:.0f}% upside probability",
            )
            narrative = t(
                lang,
                f"خلال {days} جلسات، الإشارة غير حاسمة (صعود {up_prob * 100:.0f}% / هبوط {down_prob * 100:.0f}%). "
                f"النطاق المتوقع {low:,.0f}$–{high:,.0f}$.",
                f"Over {days} sessions the signal is inconclusive (upside {up_prob * 100:.0f}% / downside {down_prob * 100:.0f}%). "
                f"Expected range ${low:,.0f}–${high:,.0f}.",
            )

        horizons.append(
            {
                "days": days,
                "up_probability": round(up_prob * 100, 1),
                "down_probability": round(down_prob * 100, 1),
                "expected": round(expected, 2),
                "low": round(low, 2),
                "high": round(high, 2),
                "expected_change_pct": round(expected_change, 2),
                "direction": direction,
                "edge": round(edge, 1),
                "label": label,
                "prepare": prepare_code,
                "prepare_text": prepare_text,
                "narrative": narrative,
            }
        )

    focus = horizons[1] if len(horizons) > 1 else horizons[0]
    summary_direction = focus["direction"]
    if summary_direction == "up" and focus["prepare"] == "prepare_buy":
        headline = t(
            lang,
            f"سيناريو صاعد خلال {focus['days']} جلسات — احتمال الصعود {focus['up_probability']:.0f}%",
            f"Upside scenario over {focus['days']} sessions — {focus['up_probability']:.0f}% upside odds",
        )
    elif summary_direction == "down" and focus["prepare"] == "prepare_sell":
        headline = t(
            lang,
            f"سيناريو هابط خلال {focus['days']} جلسات — احتمال الهبوط {focus['down_probability']:.0f}%",
            f"Downside scenario over {focus['days']} sessions — {focus['down_probability']:.0f}% downside odds",
        )
    elif summary_direction == "up":
        headline = t(
            lang,
            f"ميل صاعد طفيف ({focus['up_probability']:.0f}%) دون تأكيد من الإشارة — انتظر",
            f"Slight upside tilt ({focus['up_probability']:.0f}%) without signal confirmation — wait",
        )
    elif summary_direction == "down":
        headline = t(
            lang,
            f"ميل هابط طفيف ({focus['down_probability']:.0f}%) دون تأكيد من الإشارة — انتظر",
            f"Slight downside tilt ({focus['down_probability']:.0f}%) without signal confirmation — wait",
        )
    else:
        headline = t(
            lang,
            "لا توجد أفضلية واضحة خلال الأسبوع — انتظر تأكيداً",
            "No clear weekly edge — wait for confirmation",
        )

    model_confidence = int(
        max(
            38,
            min(
                78,
                confidence * (0.55 + 0.25 * agreement)
                + max(0.0, focus["up_probability"] - 50.0) * 0.5,
            ),
        )
    )

    return {
        "ok": True,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "basis": {
            "daily_volatility_pct": round(sigma * 100, 2),
            "daily_drift_pct": round(mu * 100, 3),
            "paths": paths,
            "timeframe_agreement": round(agreement, 2),
            "method": t(
                lang,
                "محاكاة مونت كارلو على التقلب التاريخي مع ميل من الإشارة الفنية والأساسية. "
                "عند تعارض الإشارتين قصيرة ومتوسطة المدى يُقلَّص الميل ويُوسَّع نطاق الاحتمال.",
                "Monte Carlo simulation on historical volatility with a tilt from the technical and macro signal. "
                "When short- and medium-term signals conflict, the drift is shrunk and uncertainty widened.",
            ),
        },
        "horizons": horizons,
        "summary": {
            "days": focus["days"],
            "direction": summary_direction,
            "up_probability": focus["up_probability"],
            "down_probability": focus["down_probability"],
            "edge": focus["edge"],
            "headline": headline,
            "prepare": focus["prepare"],
            "prepare_text": focus["prepare_text"],
            "range_low": focus["low"],
            "range_high": focus["high"],
            "expected": focus["expected"],
            "confidence": model_confidence,
            "confidence_note": t(
                lang,
                "الاحتمالات تقديرية وليست تنبؤاً. أفضلية أقل من 10 نقاط تعني غياب اتجاه واضح.",
                "Probabilities are estimates, not predictions. An edge below 10 points means there is no clear direction.",
            ),
        },
        "disclaimer": t(
            lang,
            "هذه احتمالات إحصائية مبنية على تاريخ السعر وليست تنبؤاً مضموناً. الأسواق تتغير والأخبار المفاجئة قد تبطل النموذج.",
            "These are statistical probabilities based on price history, not guaranteed forecasts. Markets change and surprise news can invalidate the model.",
        ),
    }
