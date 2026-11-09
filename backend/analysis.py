"""محرك الإشارة: دمج التحليل الفني، الدولار، الفائدة، والأخبار.

كل النصوص تُبنى بلغتين حسب lang في الطلب (ar/en).
"""
from datetime import datetime, timezone

from .config import DISCLAIMER, DISCLAIMER_EN
from .forecast import build_forecast
from .i18n import t
from .market import indicators, macro_snapshot, market_snapshot, gold_history
from .mentor import build_mentor
from .news import get_news

ACTION_META = {
    "BUY": {
        "label_ar": "شراء",
        "label_en": "Buy",
        "bias_ar": "إيجابي قوي",
        "bias_en": "Strongly bullish",
        "tone": "green",
        "horizon_ar": "1–3 أسابيع",
        "horizon_en": "1–3 weeks",
    },
    "ACCUMULATE": {
        "label_ar": "تجميع تدريجي",
        "label_en": "Accumulate",
        "bias_ar": "إيجابي",
        "bias_en": "Bullish",
        "tone": "teal",
        "horizon_ar": "1–3 أسابيع",
        "horizon_en": "1–3 weeks",
    },
    "WAIT": {
        "label_ar": "انتظار ومراقبة",
        "label_en": "Wait & watch",
        "bias_ar": "محايد",
        "bias_en": "Neutral",
        "tone": "amber",
        "horizon_ar": "1–7 أيام",
        "horizon_en": "1–7 days",
    },
    "REDUCE": {
        "label_ar": "تخفيف",
        "label_en": "Reduce",
        "bias_ar": "سلبي",
        "bias_en": "Bearish",
        "tone": "orange",
        "horizon_ar": "1–2 أسابيع",
        "horizon_en": "1–2 weeks",
    },
    "SELL": {
        "label_ar": "بيع",
        "label_en": "Sell",
        "bias_ar": "سلبي قوي",
        "bias_en": "Strongly bearish",
        "tone": "red",
        "horizon_ar": "1–2 أسابيع",
        "horizon_en": "1–2 weeks",
    },
}

CATEGORY_LABELS = {
    "fed": ("الفيدرالي", "Fed"),
    "inflation": ("التضخم", "Inflation"),
    "jobs": ("الوظائف", "Jobs"),
    "election": ("الانتخابات", "Elections"),
    "geopolitics": ("الجيوسياسة", "Geopolitics"),
    "dollar": ("الدولار", "Dollar"),
    "technical": ("فني", "Technical"),
    "other": ("عام", "General"),
}


def _meta(action: str, lang: str) -> dict:
    meta = ACTION_META.get(action, ACTION_META["WAIT"])
    return {
        "action": action,
        "action_label": meta["label_en"] if lang == "en" else meta["label_ar"],
        "bias": meta["bias_en"] if lang == "en" else meta["bias_ar"],
        "tone": meta["tone"],
        "horizon": meta["horizon_en"] if lang == "en" else meta["horizon_ar"],
    }


def _clamp(value: float, low: float = -100, high: float = 100) -> float:
    return max(low, min(high, value))


def _sign(value: float) -> int:
    if value > 0.05:
        return 1
    if value < -0.05:
        return -1
    return 0


def _action_for(score: float) -> str:
    if score >= 35:
        return "BUY"
    if score >= 12:
        return "ACCUMULATE"
    if score > -12:
        return "WAIT"
    if score > -35:
        return "REDUCE"
    return "SELL"


def _confidence(score: float, components: list[dict], news_count: int) -> int:
    total_weight = sum(c["weight"] for c in components if c["weight"] > 0)
    if total_weight == 0:
        return 50
    direction = _sign(score)
    if direction == 0:
        agreement = 0.5
    else:
        agreement = (
            sum(
                c["weight"]
                for c in components
                if c["weight"] > 0 and _sign(c["score"]) == direction
            )
            / total_weight
        )
    confidence = 42 + abs(score) * 0.32 + agreement * 20
    if abs(score) < 12:
        confidence = min(confidence, 56)
    if news_count < 6:
        confidence -= 4
    return int(round(_clamp(confidence, 45, 88)))


def _component(key: str, label: str, detail: str, score: float, weight: float) -> dict:
    score = max(-1.0, min(1.0, score))
    impact = "positive" if score > 0.12 else "negative" if score < -0.12 else "neutral"
    return {
        "key": key,
        "label": label,
        "detail": detail,
        "score": round(score, 3),
        "weight": weight,
        "impact": impact,
    }


def _format(value: float | None, digits: int = 0) -> str:
    if value is None:
        return "—"
    return f"{value:,.{digits}f}"


def _rsi_component(rsi_value: float | None, weight: float, lang: str) -> dict:
    label = "RSI"
    if rsi_value is None:
        return _component(
            "rsi",
            label,
            t(lang, "بيانات غير كافية", "Not enough data"),
            0,
            weight,
        )
    if rsi_value > 72:
        return _component(
            "rsi",
            label,
            t(
                lang,
                f"RSI عند {rsi_value:.1f} — تشبع شرائي يرفع احتمال التصحيح",
                f"RSI at {rsi_value:.1f} — overbought, correction risk is elevated",
            ),
            -0.8,
            weight,
        )
    if rsi_value > 60:
        return _component(
            "rsi",
            label,
            t(
                lang,
                f"RSI عند {rsi_value:.1f} — زخم إيجابي لكنه يقترب من التشبع",
                f"RSI at {rsi_value:.1f} — positive momentum, nearing overbought",
            ),
            0.25,
            weight,
        )
    if rsi_value >= 45:
        return _component(
            "rsi",
            label,
            t(
                lang,
                f"RSI عند {rsi_value:.1f} — زخم متوازن",
                f"RSI at {rsi_value:.1f} — balanced momentum",
            ),
            0.0,
            weight,
        )
    if rsi_value >= 35:
        return _component(
            "rsi",
            label,
            t(
                lang,
                f"RSI عند {rsi_value:.1f} — ضعف نسبي",
                f"RSI at {rsi_value:.1f} — relative weakness",
            ),
            -0.25,
            weight,
        )
    return _component(
        "rsi",
        label,
        t(
            lang,
            f"RSI عند {rsi_value:.1f} — تشبع بيعي قد يسبق ارتداداً",
            f"RSI at {rsi_value:.1f} — oversold, a rebound is possible",
        ),
        0.7,
        weight,
    )


def _technical_components(
    ind: dict, news_score: float, macro: dict, short_term: bool, lang: str
) -> list[dict]:
    close = ind["close"]
    components: list[dict] = []

    sma20 = ind.get("sma20")
    if sma20:
        above = close >= sma20
        components.append(
            _component(
                "trend20",
                t(lang, "الاتجاه قصير المدى", "Short-term trend"),
                t(
                    lang,
                    f"السعر {'فوق' if above else 'تحت'} متوسط 20 يوم ({_format(sma20)}$)",
                    f"Price is {'above' if above else 'below'} the 20-day average (${_format(sma20)})",
                ),
                1 if above else -1,
                16 if short_term else 10,
            )
        )

    macd_hist = ind.get("macd_hist")
    if macd_hist is not None:
        components.append(
            _component(
                "macd",
                "MACD",
                t(
                    lang,
                    f"هيستوغرام MACD {'إيجابي' if macd_hist >= 0 else 'سلبي'} ({macd_hist:.2f})",
                    f"MACD histogram is {'positive' if macd_hist >= 0 else 'negative'} ({macd_hist:.2f})",
                ),
                1 if macd_hist >= 0 else -1,
                16 if short_term else 12,
            )
        )

    components.append(_rsi_component(ind.get("rsi14"), 10 if short_term else 6, lang))

    if short_term:
        ret = ind.get("return_5d", 0)
        components.append(
            _component(
                "momentum",
                t(lang, "الزخم (5 أيام)", "Momentum (5d)"),
                t(
                    lang,
                    f"تغيّر السعر {ret:+.2f}% خلال 5 جلسات",
                    f"Price changed {ret:+.2f}% over 5 sessions",
                ),
                1 if ret > 0 else -1,
                12,
            )
        )
        day = ind.get("return_1d", 0)
        if abs(day) > 0.05:
            components.append(
                _component(
                    "day",
                    t(lang, "جلسة اليوم", "Today's session"),
                    t(
                        lang,
                        f"تحرك السعر {day:+.2f}% في آخر جلسة",
                        f"Price moved {day:+.2f}% in the latest session",
                    ),
                    _clamp(day / 1.8, -1, 1),
                    7,
                )
            )
        support = ind.get("support20")
        resistance = ind.get("resistance20")
        if support and resistance and resistance > support:
            position = (close - support) / (resistance - support)
            if position < 0.25:
                pscore = 0.7
                ptext = t(
                    lang,
                    "قريب من الدعم — مخاطرة/عائد أفضل للمشترين",
                    "Near support — better risk/reward for buyers",
                )
            elif position > 0.85:
                pscore = -0.6
                ptext = t(
                    lang,
                    "قريب من المقاومة — احتمال جني أرباح",
                    "Near resistance — profit-taking risk",
                )
            else:
                pscore = 0.15
                ptext = t(lang, "داخل نطاق التداول", "Inside the trading range")
            components.append(
                _component(
                    "position",
                    t(lang, "موقع السعر", "Price position"),
                    t(
                        lang,
                        f"{ptext} ({position * 100:.0f}% من النطاق)",
                        f"{ptext} ({position * 100:.0f}% of range)",
                    ),
                    pscore,
                    8,
                )
            )
    else:
        sma50 = ind.get("sma50")
        sma200 = ind.get("sma200")
        if sma50:
            above = close >= sma50
            components.append(
                _component(
                    "trend50",
                    t(lang, "الاتجاه متوسط المدى", "Medium-term trend"),
                    t(
                        lang,
                        f"متوسط 50 يوم عند {_format(sma50)}$ — السعر {'فوقه' if above else 'تحته'}",
                        f"50-day average at ${_format(sma50)} — price is {'above' if above else 'below'} it",
                    ),
                    1 if above else -1,
                    16,
                )
            )
        if sma200:
            above = close >= sma200
            components.append(
                _component(
                    "trend200",
                    t(lang, "الاتجاه طويل المدى", "Long-term trend"),
                    t(
                        lang,
                        f"متوسط 200 يوم عند {_format(sma200)}$ — السعر {'فوقه' if above else 'تحته'}",
                        f"200-day average at ${_format(sma200)} — price is {'above' if above else 'below'} it",
                    ),
                    1 if above else -1,
                    14,
                )
            )
        ret = ind.get("return_20d", 0)
        components.append(
            _component(
                "momentum",
                t(lang, "الزخم (20 يوم)", "Momentum (20d)"),
                t(
                    lang,
                    f"تغيّر السعر {ret:+.2f}% خلال 20 جلسة",
                    f"Price changed {ret:+.2f}% over 20 sessions",
                ),
                1 if ret > 0 else -1,
                12,
            )
        )

    dxy = macro.get("dxy", {})
    if dxy.get("ok") and abs(dxy.get("change_5d_pct", 0)) > 0.05:
        change = dxy["change_5d_pct"]
        components.append(
            _component(
                "dxy",
                t(lang, "مؤشر الدولار DXY", "US Dollar Index (DXY)"),
                t(
                    lang,
                    f"الدولار {'صاعد' if change > 0 else 'هابط'} {change:+.2f}% خلال 5 أيام — العلاقة عكسية مع الذهب",
                    f"Dollar {'rising' if change > 0 else 'falling'} {change:+.2f}% over 5 days — inverse to gold",
                ),
                _clamp(-change / 1.5, -1, 1),
                10 if short_term else 9,
            )
        )

    if not short_term:
        us10y = macro.get("us10y", {})
        if us10y.get("ok") and abs(us10y.get("change_5d_pct", 0)) > 0.1:
            change = us10y["change_5d_pct"]
            components.append(
                _component(
                    "us10y",
                    t(lang, "عائد السندات الأمريكية 10 سنوات", "US 10Y Treasury yield"),
                    t(
                        lang,
                        f"العائد {'مرتفع' if change > 0 else 'منخفض'} {change:+.2f}% — ارتفاعه يضغط على الذهب",
                        f"Yield {'rising' if change > 0 else 'falling'} {change:+.2f}% — higher yields pressure gold",
                    ),
                    _clamp(-change / 2.0, -1, 1),
                    7,
                )
            )
        sp500 = macro.get("sp500", {})
        if sp500.get("ok") and abs(sp500.get("change_5d_pct", 0)) > 0.1:
            change = sp500["change_5d_pct"]
            components.append(
                _component(
                    "sp500",
                    t(lang, "شهية المخاطرة", "Risk appetite"),
                    t(
                        lang,
                        f"S&P 500 {'صاعد' if change > 0 else 'هابط'} {change:+.2f}% — الهبوط يدعم الملاذ الآمن",
                        f"S&P 500 {'up' if change > 0 else 'down'} {change:+.2f}% — weakness supports safe havens",
                    ),
                    _clamp(-change / 2.5, -1, 1),
                    5,
                )
            )
        vix = macro.get("vix", {})
        if vix.get("ok") and abs(vix.get("change_5d_pct", 0)) > 1:
            change = vix["change_5d_pct"]
            components.append(
                _component(
                    "vix",
                    t(lang, "مؤشر الخوف VIX", "VIX fear index"),
                    t(
                        lang,
                        f"VIX {'مرتفع' if change > 0 else 'منخفض'} {change:+.1f}% — التوتر يدعم الذهب",
                        f"VIX {'up' if change > 0 else 'down'} {change:+.1f}% — stress supports gold",
                    ),
                    _clamp(change / 12, -1, 1),
                    4,
                )
            )

    components.append(
        _component(
            "news",
            t(lang, "معنويات الأخبار", "News sentiment"),
            t(
                lang,
                f"متوسط معنويات العناوين {news_score:+.2f} "
                f"({'إيجابي' if news_score > 0.12 else 'سلبي' if news_score < -0.12 else 'متوازن'})",
                f"Average headline sentiment {news_score:+.2f} "
                f"({'positive' if news_score > 0.12 else 'negative' if news_score < -0.12 else 'balanced'})",
            ),
            news_score,
            18 if short_term else 14,
        )
    )
    return components


def _score_components(components: list[dict]) -> float:
    total = sum(c["weight"] for c in components if c["weight"] > 0)
    if total == 0:
        return 0
    return _clamp(sum(c["score"] * c["weight"] for c in components) / total * 100)


def _levels(action: str, close: float, atr_value: float, support: float, resistance: float) -> dict:
    atr_value = max(atr_value, close * 0.008)
    if action in ("BUY", "ACCUMULATE"):
        entry_low = close - 0.65 * atr_value
        entry_high = close - 0.10 * atr_value
        target1 = close + 1.6 * atr_value
        target2 = close + 3.0 * atr_value
        stop = min(close - 1.2 * atr_value, support - 0.2 * atr_value)
        risk = close - stop
        reward = target1 - close
        rr = reward / risk if risk > 0 else None
    elif action in ("REDUCE", "SELL"):
        entry_low = close + 0.10 * atr_value
        entry_high = close + 0.65 * atr_value
        target1 = close - 1.6 * atr_value
        target2 = close - 3.0 * atr_value
        stop = max(close + 1.2 * atr_value, resistance + 0.2 * atr_value)
        risk = stop - close
        reward = close - target1
        rr = reward / risk if risk > 0 else None
    else:
        entry_low = support
        entry_high = (support + resistance) / 2
        target1 = resistance
        target2 = resistance + (resistance - support) * 0.5
        stop = support - 0.6 * atr_value
        rr = None

    return {
        "entry_low": round(entry_low, 2),
        "entry_high": round(entry_high, 2),
        "target1": round(target1, 2),
        "target2": round(target2, 2),
        "stop": round(stop, 2),
        "support": round(support, 2),
        "resistance": round(resistance, 2),
        "risk_reward": round(rr, 1) if rr else None,
        "atr": round(atr_value, 2),
    }


def _narrative(action: str, ind: dict, news_summary: dict, lang: str) -> str:
    base = t(
        lang,
        {
            "BUY": "الإشارة تميل بوضوح إلى الشراء. الأفضل الدخول على دفعات عند مناطق الدعم وعدم مطاردة السعر بعد قفزة قوية.",
            "ACCUMULATE": "الزخم إيجابي لكنه غير كافٍ لشراء كامل. التجميع التدريجي على دفعتين أو ثلاث هو الخيار الأكثر توازناً.",
            "WAIT": "الإشارات متضاربة حالياً. انتظر إغلاقاً واضحاً فوق المقاومة أو ارتداداً مؤكداً من الدعم قبل اتخاذ قرار.",
            "REDUCE": "بدأ الضغط السلبي بالظهور. تقليل التعرض تدريجياً وحماية الأرباح أفضل من زيادة الشراء الآن.",
            "SELL": "الإشارات سلبية بقوة. الأولوية للخروج أو البيع، وأي ارتداد قصير يمكن استخدامه لتخفيف المركز.",
        }[action],
        {
            "BUY": "The signal clearly leans to buying. Scale in near support rather than chasing the price after a strong jump.",
            "ACCUMULATE": "Momentum is positive but not strong enough for a full position. Accumulating in two or three tranches is the balanced choice.",
            "WAIT": "Signals are mixed. Wait for a clear close above resistance or a confirmed rebound from support before deciding.",
            "REDUCE": "Negative pressure is starting to show. Trimming exposure and protecting profits is better than adding now.",
            "SELL": "Signals are strongly negative. Prioritise exiting or selling; any short rebound can be used to lighten the position.",
        }[action],
    )

    extras = []
    rsi_value = ind.get("rsi14")
    if rsi_value and rsi_value > 72:
        extras.append(
            t(
                lang,
                f"RSI عند {rsi_value:.1f} يشير إلى تشبع شرائي واحتمال تصحيح قصير.",
                f"RSI at {rsi_value:.1f} suggests overbought conditions and a possible short-term pullback.",
            )
        )
    if rsi_value and rsi_value < 30:
        extras.append(
            t(
                lang,
                f"RSI عند {rsi_value:.1f} يشير إلى تشبع بيعي واحتمال ارتداد.",
                f"RSI at {rsi_value:.1f} suggests oversold conditions and a possible rebound.",
            )
        )
    close = ind.get("close")
    resistance = ind.get("resistance20")
    support = ind.get("support20")
    if close and resistance and resistance > 0 and abs(close - resistance) / resistance < 0.01:
        extras.append(
            t(
                lang,
                "السعر ملاصق لمقاومة قريبة، وقد يحتاج اختراقاً مؤكداً للاستمرار.",
                "Price is hugging nearby resistance and may need a confirmed breakout to continue.",
            )
        )
    if close and support and support > 0 and abs(close - support) / support < 0.01:
        extras.append(
            t(
                lang,
                "السعر قريب من دعم مهم؛ كسره يضعف السيناريو الإيجابي.",
                "Price is near an important support; a break would weaken the bullish scenario.",
            )
        )
    if news_summary.get("label"):
        extras.append(
            t(
                lang,
                f"الأخبار حالياً: {news_summary['label']}.",
                f"News now: {news_summary['label']}.",
            )
        )
    return " ".join([base] + extras)


def build_signal(
    short_term: bool, ind: dict, news_payload: dict, macro: dict, lang: str
) -> dict:
    components = _technical_components(
        ind, news_payload["summary"]["score"], macro, short_term, lang
    )
    score = _score_components(components)
    action = _action_for(score)
    meta = _meta(action, lang)
    confidence = _confidence(score, components, news_payload["summary"]["count"])
    reasons = sorted(
        components, key=lambda c: abs(c["score"] * c["weight"]), reverse=True
    )

    return {
        **meta,
        "horizon": t(lang, "1–3 أيام", "1–3 days")
        if short_term
        else t(lang, "1–3 أسابيع", "1–3 weeks"),
        "score": round(score, 1),
        "confidence": confidence,
        "components": components,
        "reasons": reasons[:6],
        "summary": _narrative(action, ind, news_payload["summary"], lang),
    }


def _verdict(action: str, lang: str) -> str:
    return t(
        lang,
        {
            "BUY": "نعم — الشراء مناسب الآن على دفعات، وليس بكامل المبلغ دفعة واحدة.",
            "ACCUMULATE": "نعم جزئياً — ابدأ بجزء صغير وأضف عند التأكيد.",
            "WAIT": "لا — الأفضل الانتظار حتى تتضح الإشارة.",
            "REDUCE": "لا — الأفضل تقليل التعرض وعدم الشراء الآن.",
            "SELL": "لا — الأولوية للبيع أو الخروج، وليس للشراء.",
        }[action],
        {
            "BUY": "Yes — buying now is reasonable in tranches, not all at once.",
            "ACCUMULATE": "Partly — start small and add on confirmation.",
            "WAIT": "No — better to wait until the signal is clearer.",
            "REDUCE": "No — reduce exposure rather than buy now.",
            "SELL": "No — prioritise selling or exiting, not buying.",
        }[action],
    )


def build_analysis(lang: str = "ar") -> dict:
    lang = "en" if lang == "en" else "ar"
    market = market_snapshot(lang)
    gold = gold_history("1y")
    ind = indicators(gold["candles"])
    news = get_news(lang)
    macro = market.get("macro", macro_snapshot())

    short = build_signal(True, ind, news, macro, lang)
    swing = build_signal(False, ind, news, macro, lang)

    # اتفاق الأطر الزمنية: كلما تعارضت الإشارة قصيرة المدى مع متوسطة المدى
    # قلّت الثقة وابتعد النموذج عن إعلان اتجاه قاطع (كان هذا سبب تنبؤات مضللة).
    s_score = float(short["score"])
    w_score = float(swing["score"])
    if s_score == 0 or w_score == 0:
        agreement = 0.7
    elif s_score * w_score > 0:
        agreement = 0.75 + 0.25 * min(1.0, min(abs(s_score), abs(w_score)) / 30.0)
    else:
        agreement = max(0.2, 0.6 - (abs(s_score) + abs(w_score)) / 300.0)
    conflict = s_score * w_score < 0

    raw_overall = short["score"] * 0.45 + swing["score"] * 0.55
    overall_score = raw_overall * (0.70 + 0.30 * agreement)
    overall_action = _action_for(overall_score)
    # عند تعارض واضح ودرجة قريبة من الحياد لا نعلن شراء/بيعاً قاطعاً.
    if conflict and agreement < 0.55 and abs(overall_score) < 25:
        overall_action = "WAIT"
    overall_meta = _meta(overall_action, lang)
    overall_confidence = int(
        round((short["confidence"] + swing["confidence"]) / 2 * (0.80 + 0.20 * agreement))
    )
    if conflict:
        overall_confidence = max(42, overall_confidence - 3)
    levels = _levels(
        overall_action,
        ind["close"],
        ind.get("atr14") or ind["close"] * 0.015,
        ind.get("support20") or ind["close"] * 0.95,
        ind.get("resistance20") or ind["close"] * 1.05,
    )

    regime = t(lang, "عرضي / متذبذب", "Sideways / choppy")
    if ind.get("sma50") and ind.get("sma200"):
        if ind["close"] > ind["sma50"] > ind["sma200"]:
            regime = t(lang, "اتجاه صاعد", "Uptrend")
        elif ind["close"] < ind["sma50"] < ind["sma200"]:
            regime = t(lang, "اتجاه هابط", "Downtrend")

    overextension = None
    if ind.get("sma200"):
        distance = (ind["close"] - ind["sma200"]) / ind["sma200"] * 100
        if distance > 12:
            overextension = t(
                lang,
                f"السعر مرتفع {distance:.1f}% فوق متوسط 200 يوم — خطر تصحيح مرتفع.",
                f"Price is {distance:.1f}% above the 200-day average — elevated correction risk.",
            )
        elif distance < -12:
            overextension = t(
                lang,
                f"السعر منخفض {abs(distance):.1f}% تحت متوسط 200 يوم — قد يكون فرصة لكن الاتجاه ضعيف.",
                f"Price is {abs(distance):.1f}% below the 200-day average — potentially an opportunity, but the trend is weak.",
            )

    catalysts = [
        {
            "title": item["title"],
            "source": item["source"],
            "category": item["category"],
            "category_label": CATEGORY_LABELS.get(item["category"], CATEGORY_LABELS["other"])[
                1 if lang == "en" else 0
            ],
            "impact": item["impact"],
            "sentiment_label": item["sentiment_label"],
            "published_at": item["published_at"],
        }
        for item in news.get("catalysts", [])
    ]

    forecast = build_forecast(
        gold["candles"],
        overall_score,
        overall_action,
        overall_confidence,
        ind.get("rsi14"),
        lang,
        agreement=agreement,
    )

    plan = {
        "decision": overall_action,
        "decision_label": overall_meta["action_label"],
        "tone": overall_meta["tone"],
        "verdict": _verdict(overall_action, lang),
        "entry_low": levels["entry_low"],
        "entry_high": levels["entry_high"],
        "target1": levels["target1"],
        "target2": levels["target2"],
        "invalidation": levels["stop"],
        "risk_reward": levels["risk_reward"],
        "steps": _plan_steps(overall_action, levels, lang),
        "watch": catalysts,
        "risk_note": t(
            lang,
            "لا تستثمر أكثر مما تتحمل خسارته. هذه خطة سيناريوهات وليست ضماناً.",
            "Do not invest more than you can afford to lose. This is a scenario plan, not a guarantee.",
        ),
    }

    return {
        "ok": True,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "lang": lang,
        "price": market["usd_oz"],
        "usd_iqd": market["usd_iqd"],
        **overall_meta,
        "horizon": t(lang, "1–3 أسابيع", "1–3 weeks"),
        "score": round(overall_score, 1),
        "confidence": overall_confidence,
        "timeframe_agreement": round(agreement, 2),
        "timeframe_conflict": conflict,
        "credibility_note": t(
            lang,
            (
                "الإشارة قصيرة المدى تتعارض مع متوسطة المدى؛ لذلك خُفِّضت الثقة "
                "ولم يُعلن اتجاه قاطع. انتظر تأكيداً قبل التحرك."
                if conflict
                else "الإشارتان قصيرة ومتوسطة المدى متوافقتان، والثقة معروضة كتقدير احتمالي لا كضمان."
            ),
            (
                "The short-term signal conflicts with the medium-term signal, so confidence "
                "was reduced and no decisive direction was declared. Wait for confirmation."
                if conflict
                else "Short- and medium-term signals agree. Confidence is a probabilistic estimate, not a guarantee."
            ),
        ),
        "summary": swing["summary"],
        "verdict": plan["verdict"],
        "regime": regime,
        "overextension": overextension,
        "short_term": short,
        "swing": swing,
        "levels": levels,
        "indicators": ind,
        "macro": macro,
        "news": news.get("summary", {}),
        "top_reasons": swing["reasons"][:5],
        "plan": plan,
        "forecast": forecast,
        "mentor": build_mentor(
            overall_action,
            overall_confidence,
            ind,
            levels,
            macro,
            news.get("summary", {}),
            regime,
            lang,
        ),
        "disclaimer": DISCLAIMER_EN if lang == "en" else DISCLAIMER,
        "methodology": t(
            lang,
            "النموذج يجمع الاتجاه والمتوسطات وRSI وMACD مع الدولار وعوائد السندات "
            "ومعنويات الأخبار. النتيجة مقياس من -100 إلى +100 وليست تنبؤاً مضموناً.",
            "The model blends trend, moving averages, RSI and MACD with the dollar, "
            "bond yields and news sentiment. The score runs from -100 to +100 and is not a guaranteed forecast.",
        ),
    }


def _plan_steps(action: str, levels: dict, lang: str) -> list[str]:
    low = _format(levels["entry_low"], 0)
    high = _format(levels["entry_high"], 0)
    t1 = _format(levels["target1"], 0)
    t2 = _format(levels["target2"], 0)
    stop = _format(levels["stop"], 0)
    if action == "BUY":
        return [
            t(
                lang,
                f"ادخل على دفعتين بين {low}$ و{high}$ بدلاً من دفعة واحدة.",
                f"Enter in two tranches between ${low} and ${high} instead of one lump sum.",
            ),
            t(
                lang,
                f"الهدف الأول {t1}$ ثم {t2}$، مع رفع وقف الخسارة بعد تحقيق الهدف الأول.",
                f"First target ${t1}, then ${t2}; trail the stop after the first target.",
            ),
            t(
                lang,
                f"وقف الخسارة/إبطال السيناريو عند {stop}$.",
                f"Stop loss / invalidation at ${stop}.",
            ),
            t(
                lang,
                "لا تزد المركز إذا ارتفع السعر بسرعة دون تصحيح.",
                "Do not add if price runs up quickly without a pullback.",
            ),
        ]
    if action == "ACCUMULATE":
        return [
            t(
                lang,
                f"خصّص 30–50% فقط الآن في نطاق {low}$–{high}$.",
                f"Deploy only 30–50% now within ${low}–${high}.",
            ),
            t(
                lang,
                f"أضف الدفعة الثانية عند تأكيد فوق المقاومة أو ارتداد من الدعم، بهدف {t1}$.",
                f"Add the second tranche on a confirmed break above resistance or a support bounce, targeting ${t1}.",
            ),
            t(
                lang,
                f"أبطل السيناريو تحت {stop}$.",
                f"Invalidate below ${stop}.",
            ),
            t(
                lang,
                "راقب الدولار وأخبار الفيدرالي قبل إضافة أي دفعة.",
                "Watch the dollar and Fed news before adding any tranche.",
            ),
        ]
    if action == "WAIT":
        return [
            t(
                lang,
                f"راقب نطاق {low}$–{high}$ دون دخول كامل.",
                f"Watch the ${low}–${high} range without a full entry.",
            ),
            t(
                lang,
                f"الشراء يتأكد فقط بإغلاق فوق {t1}$، والبيع بكسر {stop}$.",
                f"Buying is confirmed only by a close above ${t1}; selling by a break below ${stop}.",
            ),
            t(
                lang,
                "اجعل حجم أي تجربة صغيراً جداً حتى تتضح الإشارة.",
                "Keep any trial position very small until the signal clears.",
            ),
            t(
                lang,
                "أعد تقييم الإشارة بعد أخبار الفيدرالي أو التضخم.",
                "Re-evaluate after Fed or inflation data.",
            ),
        ]
    if action == "REDUCE":
        return [
            t(
                lang,
                f"قلّل 25–50% من المركز في نطاق {low}$–{high}$.",
                f"Trim 25–50% of the position within ${low}–${high}.",
            ),
            t(
                lang,
                f"احتفظ بجزء فقط إذا ثبت السعر فوق {t1}$.",
                f"Keep only a portion if price holds above ${t1}.",
            ),
            t(
                lang,
                f"وقف حماية للأرباح عند {stop}$.",
                f"Profit-protection stop at ${stop}.",
            ),
            t(
                lang,
                "لا تضف مراكز جديدة حتى تتحسن معنويات الأخبار.",
                "Do not add new positions until news sentiment improves.",
            ),
        ]
    return [
        t(
            lang,
            f"الخروج/البيع في نطاق {low}$–{high}$.",
            f"Exit/sell within ${low}–${high}.",
        ),
        t(
            lang,
            f"الأهداف السلبية {t1}$ ثم {t2}$.",
            f"Downside targets ${t1}, then ${t2}.",
        ),
        t(
            lang,
            f"أبطل السيناريو بإغلاق فوق {stop}$.",
            f"Invalidate on a close above ${stop}.",
        ),
        t(
            lang,
            "أي ارتداد قصير يُستخدم لتخفيف المركز وليس لزيادته.",
            "Use any short rebound to reduce the position, not add to it.",
        ),
    ]
