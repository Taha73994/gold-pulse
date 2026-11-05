"""مرشد التداول: يحوّل الإشارة إلى خطة عملية بعقلية مضارب ذهب محترف."""
from .i18n import t


def _levels_list(levels: dict, lang: str) -> list[dict]:
    en = lang == "en"
    return [
        {
            "type": "support",
            "label": "Support" if en else "الدعم الرئيسي",
            "price": levels["support"],
            "note": "A close below weakens the bullish case."
            if en
            else "الإغلاق تحته يضعف السيناريو الصاعد.",
        },
        {
            "type": "resistance",
            "label": "Resistance" if en else "المقاومة الرئيسية",
            "price": levels["resistance"],
            "note": "A confirmed close above opens more upside."
            if en
            else "الاختراق المؤكد يفتح مجالاً لمزيد من الصعود.",
        },
        {
            "type": "entry",
            "label": "Preferred entry zone" if en else "منطقة الدخول المفضلة",
            "price": levels["entry_low"],
            "price_high": levels["entry_high"],
            "note": "Scale in; do not use the full amount at once."
            if en
            else "ادخل على دفعات ولا تستخدم كامل المبلغ مرة واحدة.",
        },
        {
            "type": "stop",
            "label": "Invalidation / stop" if en else "وقف الخسارة / إبطال السيناريو",
            "price": levels["stop"],
            "note": "Place it before entering, not after."
            if en
            else "حدده قبل الدخول وليس بعده.",
        },
        {
            "type": "target",
            "label": "Targets" if en else "الأهداف",
            "price": levels["target1"],
            "price_high": levels["target2"],
            "note": "Take partial profit at the first target."
            if en
            else "اجنِ جزءاً من الربح عند الهدف الأول.",
        },
    ]


def _scenarios(levels: dict, lang: str) -> list[dict]:
    en = lang == "en"
    support = f"{levels['support']:,.0f}"
    resistance = f"{levels['resistance']:,.0f}"
    target2 = f"{levels['target2']:,.0f}"
    stop = f"{levels['stop']:,.0f}"
    downside = levels["support"] - (levels["resistance"] - levels["support"]) * 0.5
    return [
        {
            "title": f"Break above ${resistance}" if en else f"اختراق فوق {resistance}$",
            "trigger": "A daily close above resistance."
            if en
            else "إغلاق يومي فوق المقاومة.",
            "action": "Wait for a retest, then add gradually; do not chase the first candle."
            if en
            else "انتظر إعادة اختبار المستوى ثم أضف تدريجياً؛ لا تطارد الشمعة الأولى.",
            "target": f"${target2}",
            "risk": f"Back below ${resistance} invalidates the breakout."
            if en
            else f"العودة تحت {resistance}$ تبطل الاختراق.",
        },
        {
            "title": f"Break below ${support}" if en else f"كسر تحت {support}$",
            "trigger": "A daily close below support."
            if en
            else "إغلاق يومي تحت الدعم.",
            "action": "Reduce exposure and stay out of new buys until it stabilises."
            if en
            else "قلّل التعرض وابقَ خارج الشراء حتى يستقر السعر.",
            "target": f"${downside:,.0f}",
            "risk": f"A close back above ${support} cancels the bearish scenario."
            if en
            else f"الإغلاق فوق {support}$ يلغي السيناريو الهابط.",
        },
        {
            "title": "Range between support and resistance"
            if en
            else "تداول عرضي بين الدعم والمقاومة",
            "trigger": f"Price stays between ${support} and ${resistance}."
            if en
            else f"بقاء السعر بين {support}$ و{resistance}$.",
            "action": "Trade small near the edges only, or wait for a clean break."
            if en
            else "تداول بكميات صغيرة قرب الأطراف فقط، أو انتظر اختراقاً واضحاً.",
            "target": "Range edges" if en else "أطراف النطاق",
            "risk": f"Stop ${stop} on any position."
            if en
            else f"وقف الخسارة عند {stop}$ لأي صفقة.",
        },
    ]


def _rules(lang: str) -> list[str]:
    return [
        t(
            lang,
            "لا تخاطر بأكثر من 1–2% من رأس مالك في صفقة واحدة، مهما كانت الإشارة قوية.",
            "Never risk more than 1–2% of your capital on one trade, however strong the signal.",
        ),
        t(
            lang,
            "ادخل على دفعتين أو ثلاث؛ المضارب المحترف لا يشتري بكامل المبلغ مرة واحدة.",
            "Scale in over two or three tranches; a professional never buys the full size at once.",
        ),
        t(
            lang,
            "حدد وقف الخسارة قبل التنفيذ، ولا تنقله للأسفل أبداً.",
            "Set your stop before execution and never move it lower.",
        ),
        t(
            lang,
            "لا تطارد السعر بعد قفزة قوية. انتظر تصحيحاً أو إعادة اختبار.",
            "Do not chase after a strong jump. Wait for a pullback or retest.",
        ),
        t(
            lang,
            "تجنب الدخول في أول 15 دقيقة بعد بيانات التضخم أو الوظائف أو قرار الفيدرالي.",
            "Avoid entering in the first 15 minutes after inflation, jobs or Fed data.",
        ),
        t(
            lang,
            "سجّل سبب كل صفقة، وراجعها أسبوعياً. الانضباط أهم من التوقع.",
            "Journal the reason for every trade and review weekly. Discipline beats prediction.",
        ),
    ]


def _checklist(action: str, ind: dict, macro: dict, levels: dict, news: dict, lang: str) -> list[dict]:
    en = lang == "en"
    dxy = macro.get("dxy", {})
    dxy_ok = dxy.get("ok") and dxy.get("change_5d_pct", 0) < 0
    items = [
        {
            "ok": ind.get("close", 0) >= (ind.get("sma20") or 0),
            "text": "Is price above the 20-day average?"
            if en
            else "هل السعر فوق متوسط 20 يوم؟",
        },
        {
            "ok": 40 <= (ind.get("rsi14") or 50) <= 70,
            "text": "Is RSI outside overbought/oversold extremes?"
            if en
            else "هل RSI بعيد عن التشبع الشرائي/البيعي؟",
        },
        {
            "ok": bool(dxy_ok),
            "text": "Is the dollar trend supportive (not rising)?"
            if en
            else "هل اتجاه الدولار داعم (غير صاعد)؟",
        },
        {
            "ok": news.get("score", 0) > -0.1,
            "text": "Is news sentiment not clearly negative?"
            if en
            else "هل معنويات الأخبار ليست سلبية بوضوح؟",
        },
        {
            "ok": action in ("BUY", "ACCUMULATE"),
            "text": "Do the signals actually support buying?"
            if en
            else "هل الإشارات تدعم الشراء فعلاً؟",
        },
        {
            "ok": levels["risk_reward"] is not None and (levels["risk_reward"] or 0) >= 1.2,
            "text": "Is risk/reward at least 1.2?"
            if en
            else "هل العائد/المخاطرة 1.2 على الأقل؟",
        },
    ]
    return items


def _mistakes(action: str, ind: dict, levels: dict, macro: dict, lang: str) -> list[str]:
    en = lang == "en"
    out: list[str] = []
    rsi = ind.get("rsi14") or 50
    close = ind.get("close") or 0
    resistance = levels.get("resistance") or 0
    sma200 = ind.get("sma200") or 0

    if rsi > 70:
        out.append(
            t(
                lang,
                "لا تشترِ في منطقة تشبع شرائي؛ احتمال التصحيح مرتفع.",
                "Do not buy into overbought conditions; pullback risk is high.",
            )
        )
    if resistance and close and resistance > 0 and (resistance - close) / resistance < 0.015:
        out.append(
            t(
                lang,
                "لا تشترِ مباشرة تحت مقاومة قوية وتنتظر اختراقاً لم يحدث.",
                "Do not buy right under strong resistance and anticipate a breakout.",
            )
        )
    if sma200 and close and close < sma200 * 0.9:
        out.append(
            t(
                lang,
                "لا تحاول التقاط القاع في اتجاه هابط؛ انتظر إشارة انعكاس واضحة.",
                "Do not try to catch the bottom in a downtrend; wait for a clear reversal.",
            )
        )
    if macro.get("vix", {}).get("change_5d_pct", 0) > 20:
        out.append(
            t(
                lang,
                "التوتر مرتفع؛ لا تتداول بحجم كبير أو بدون وقف خسارة.",
                "Stress is elevated; do not trade large size or without a stop.",
            )
        )
    if action in ("REDUCE", "SELL"):
        out.append(
            t(
                lang,
                "لا تعاند الإشارة السلبية؛ حماية رأس المال أولى من إثبات أنك على حق.",
                "Do not fight a negative signal; protecting capital matters more than being right.",
            )
        )
    if not out:
        out.append(
            t(
                lang,
                "أكبر خطأ الآن هو التسرع أو الدخول بكامل المبلغ دون تأكيد.",
                "The biggest mistake now is rushing or entering full size without confirmation.",
            )
        )
    return out


def build_mentor(
    action: str,
    confidence: int,
    ind: dict,
    levels: dict,
    macro: dict,
    news: dict,
    regime: str,
    lang: str,
) -> dict:
    en = lang == "en"
    support = f"{levels['support']:,.0f}"
    resistance = f"{levels['resistance']:,.0f}"
    entry_low = f"{levels['entry_low']:,.0f}"
    entry_high = f"{levels['entry_high']:,.0f}"
    stop = f"{levels['stop']:,.0f}"

    if confidence >= 75:
        conviction = "High" if en else "عالية"
    elif confidence >= 60:
        conviction = "Medium" if en else "متوسطة"
    else:
        conviction = "Low" if en else "منخفضة"

    headline = t(
        lang,
        {
            "BUY": "اليوم: اشترِ تدريجياً ولا تطارد السعر.",
            "ACCUMULATE": "اليوم: ابنِ مركزاً صغيراً وأضف عند التأكيد.",
            "WAIT": "اليوم: لا تشترِ. راقب وانتظر إشارة أوضح.",
            "REDUCE": "اليوم: قلّل المخاطرة ولا تضف مراكز.",
            "SELL": "اليوم: الأولوية لحماية رأس المال والخروج.",
        }[action],
        {
            "BUY": "Today: buy gradually, do not chase.",
            "ACCUMULATE": "Today: build a small position and add on confirmation.",
            "WAIT": "Today: do not buy. Watch and wait for a clearer signal.",
            "REDUCE": "Today: cut risk and do not add positions.",
            "SELL": "Today: capital protection and exiting come first.",
        }[action],
    )

    note = t(
        lang,
        {
            "BUY": (
                f"المضارب المحترف يشتري بين {entry_low}$ و{entry_high}$ على دفعتين، "
                f"ويضع وقفاً تحت {stop}$. لا يزيد الحجم إذا ارتفع السعر بسرعة، "
                "ويجنّب الربح الجزئي عند الهدف الأول."
            ),
            "ACCUMULATE": (
                f"ابدأ بثلث أو نصف المركز في نطاق {entry_low}$–{entry_high}$، "
                f"وأضف فقط بعد إغلاق مؤكد فوق المقاومة. الوقف تحت {stop}$، "
                "ولا تتحرك بناءً على شمعة واحدة."
            ),
            "WAIT": (
                f"أفضل صفقة الآن قد تكون عدم الدخول. راقب {support}$ دعمًا و{resistance}$ مقاومة. "
                "الشراء يتأكد بإغلاق فوق المقاومة، والبيع بكسر الدعم. أي دخول قبل ذلك مضاربة عشوائية."
            ),
            "REDUCE": (
                f"خفّف 25–50% من المركز في نطاق {entry_low}$–{entry_high}$، "
                f"واحمِ ما تبقى بوقف عند {stop}$. لا تضف مراكز حتى تتحسن الإشارة."
            ),
            "SELL": (
                f"لا تحاول التقاط القاع. الخروج أو البيع في نطاق {entry_low}$–{entry_high}$، "
                f"وأي ارتداد قصير يُستخدم لتخفيف المركز. لا تشترِ قبل إغلاق فوق {resistance}$."
            ),
        }[action],
        {
            "BUY": (
                f"A professional buys between ${entry_low} and ${entry_high} in two tranches, "
                f"with a stop below ${stop}. They do not add if price runs, and take partial "
                "profit at the first target."
            ),
            "ACCUMULATE": (
                f"Start with a third to half of the position in the ${entry_low}–${entry_high} zone, "
                f"and add only after a confirmed close above resistance. Stop below ${stop}; "
                "do not react to a single candle."
            ),
            "WAIT": (
                f"The best trade now may be no trade. Watch ${support} as support and ${resistance} "
                "as resistance. Buying is confirmed by a close above resistance; selling by a break "
                "of support. Entering before that is random speculation."
            ),
            "REDUCE": (
                f"Trim 25–50% of the position in the ${entry_low}–${entry_high} zone and protect "
                f"the rest with a stop at ${stop}. Do not add until the signal improves."
            ),
            "SELL": (
                f"Do not try to catch the bottom. Exit or sell in the ${entry_low}–${entry_high} zone; "
                f"use any short rebound to lighten the position. Do not buy before a close above ${resistance}."
            ),
        }[action],
    )

    weekly = [
        t(
            lang,
            f"الاتجاه الحالي: {regime}.",
            f"Current regime: {regime}.",
        ),
        t(
            lang,
            f"المستوى الحاسم: إغلاق فوق {resistance}$ يفتح الصعود، وكسر {support}$ يفتح الهبوط.",
            f"Decisive level: a close above ${resistance} opens upside; a break of ${support} opens downside.",
        ),
        t(
            lang,
            "خطة الأسبوع: لا تطارد، ادخل على دفعات، والتزم بالوقف مهما حدث.",
            "Weekly plan: do not chase, scale in, and honour the stop no matter what.",
        ),
    ]

    return {
        "headline": headline,
        "conviction": conviction,
        "note": note,
        "key_levels": _levels_list(levels, lang),
        "scenarios": _scenarios(levels, lang),
        "rules": _rules(lang),
        "checklist": _checklist(action, ind, macro, levels, news, lang),
        "mistakes": _mistakes(action, ind, levels, macro, lang),
        "weekly": weekly,
        "timing_note": t(
            lang,
            "نفّذ بعد إغلاق شمعة اليوم/الأسبوع وبعد استيعاب الأخبار. تجنب أول 15 دقيقة من بيانات التضخم والوظائف وقرار الفيدرالي.",
            "Execute after the daily/weekly close and after news is absorbed. Avoid the first 15 minutes of inflation, jobs and Fed releases.",
        ),
        "disclaimer": t(
            lang,
            "هذا مرشد قائم على قواعد تداول وبيانات السوق، وليس نصيحة استثمارية مضمونة. القرار النهائي لك.",
            "This is a rules-based trading guide built on market data, not guaranteed investment advice. The final decision is yours.",
        ),
    }
