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


def _prepare(direction: str, lang: str) -> tuple[str, str]:
    if direction == "up":
        return (
            "prepare_buy",
            t(
                lang,
                "استعد للشراء على دفعات — ولا تطارد السعر.",
                "Prepare to buy in tranches — do not chase the price.",
            ),
        )
    if direction == "down":
        return (
            "prepare_sell",
            t(
                lang,
                "استعد لتخفيف المركز أو البيع — واحمِ رأس المال.",
                "Prepare to trim or sell — protect your capital.",
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

    mu = 0.45 * hist_drift + 0.55 * signal_drift
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
        direction = "up" if up_prob >= 0.55 else "down" if up_prob <= 0.45 else "neutral"
        prepare_code, prepare_text = _prepare(direction, lang)

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
                "label": label,
                "prepare": prepare_code,
                "prepare_text": prepare_text,
                "narrative": narrative,
            }
        )

    focus = horizons[1] if len(horizons) > 1 else horizons[0]
    summary_direction = focus["direction"]
    if summary_direction == "up":
        headline = t(
            lang,
            f"استعد للشراء خلال {focus['days']} جلسات — احتمال الصعود {focus['up_probability']:.0f}%",
            f"Prepare to buy within {focus['days']} sessions — {focus['up_probability']:.0f}% upside odds",
        )
    elif summary_direction == "down":
        headline = t(
            lang,
            f"استعد للبيع/التخفيف خلال {focus['days']} جلسات — احتمال الهبوط {focus['down_probability']:.0f}%",
            f"Prepare to sell/trim within {focus['days']} sessions — {focus['down_probability']:.0f}% downside odds",
        )
    else:
        headline = t(
            lang,
            "لا توجد أفضلية واضحة خلال الأسبوع — انتظر تأكيداً",
            "No clear weekly edge — wait for confirmation",
        )

    model_confidence = int(
        max(
            40,
            min(
                84,
                confidence * 0.55
                + abs(focus["up_probability"] - 50) * 0.65,
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
            "method": t(
                lang,
                "محاكاة مونت كارلو على التقلب التاريخي مع ميل من الإشارة الفنية والأساسية.",
                "Monte Carlo simulation on historical volatility with a tilt from the technical and macro signal.",
            ),
        },
        "horizons": horizons,
        "summary": {
            "days": focus["days"],
            "direction": summary_direction,
            "up_probability": focus["up_probability"],
            "down_probability": focus["down_probability"],
            "headline": headline,
            "prepare": focus["prepare"],
            "prepare_text": focus["prepare_text"],
            "range_low": focus["low"],
            "range_high": focus["high"],
            "expected": focus["expected"],
            "confidence": model_confidence,
        },
        "disclaimer": t(
            lang,
            "هذه احتمالات إحصائية مبنية على تاريخ السعر وليست تنبؤاً مضموناً. الأسواق تتغير والأخبار المفاجئة قد تبطل النموذج.",
            "These are statistical probabilities based on price history, not guaranteed forecasts. Markets change and surprise news can invalidate the model.",
        ),
    }
