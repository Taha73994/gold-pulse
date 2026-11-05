"""أخبار السوق العربي والعالمي مع تحليل معنويات مبسط وشفاف."""
import html
import re
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime

from .config import HTTP_TIMEOUT, NEWS_CACHE_SECONDS, USER_AGENT

GOOGLE_NEWS = "https://news.google.com/rss/search"

QUERIES = [
    ("سعر الذهب الفيدرالي", "ar", "fed"),
    ("الذهب التضخم الدولار", "ar", "inflation"),
    ("الذهب الانتخابات", "ar", "election"),
    ("الذهب أسعار الفائدة", "ar", "fed"),
    ("gold price Federal Reserve", "en", "fed"),
    ("gold forecast inflation dollar", "en", "inflation"),
    ("gold election geopolitics", "en", "election"),
    ("gold safe haven war", "en", "geopolitics"),
]

POSITIVE_AR = [
    "ارتفاع الذهب", "ترتفع الذهب", "صعود الذهب", "مكاسب الذهب", "قفزة الذهب",
    "ملاذ آمن", "تراجع الدولار", "ضعف الدولار", "خفض الفائدة", "خفض أسعار الفائدة",
    "توقعات بخفض", "تضخم", "توتر", "أزمة", "حرب", "صراع", "عزوف عن المخاطرة",
    "طلب قوي", "شراء الذهب", "مكاسب", "يقفز", "يسجل ارتفاعاً", "قياسي",
    "تخفيف السياسة", "ركود", "مخاطر", "ملاذ",
]
NEGATIVE_AR = [
    "هبوط الذهب", "تراجع الذهب", "انخفاض الذهب", "خسائر الذهب", "ضغط على الذهب",
    "بيع الذهب", "جني أرباح", "قوة الدولار", "ارتفاع الدولار", "دولار قوي",
    "رفع الفائدة", "رفع أسعار الفائدة", "تشديد", "تفاؤل", "تهدئة", "وقف إطلاق النار",
    "اتفاق", "استقرار", "بيانات وظائف قوية", "بيانات قوية", "سندات مرتفعة",
    "عوائد مرتفعة", "تراجع الطلب", "هبوط", "انخفاض", "خسائر", "يتراجع",
]
POSITIVE_EN = [
    "gold rises", "gold rallies", "gold gains", "gold surges", "gold jumps",
    "record high", "safe haven", "weaker dollar", "dollar falls", "rate cut",
    "inflation", "geopolitical", "war", "tension", "recession", "strong demand",
    "bullish", "buy gold", "gold climbs", "gold hits high", "haven demand",
]
NEGATIVE_EN = [
    "gold falls", "gold drops", "gold declines", "gold slips", "gold loses",
    "strong dollar", "dollar rises", "dollar strengthens", "rate hike",
    "hawkish", "profit-taking", "sell-off", "ceasefire", "risk-on",
    "strong jobs", "hot inflation", "gold pulls back", "bearish", "gold retreats",
]

CATEGORY_LABELS = {
    "fed": ("الفيدرالي والفائدة", "Fed & rates"),
    "inflation": ("التضخم", "Inflation"),
    "jobs": ("سوق العمل", "Jobs"),
    "election": ("الانتخابات والسياسة", "Elections & politics"),
    "geopolitics": ("الجيوسياسة", "Geopolitics"),
    "dollar": ("الدولار", "Dollar"),
    "technical": ("تحليل فني", "Technical"),
    "other": ("سوق عام", "General market"),
}

CATEGORY_WHY = {
    "fed": (
        "قرارات الفائدة الأمريكية تحدد تكلفة الفرصة البديلة لحيازة الذهب؛ خفض الفائدة يدعم المعدن ورفعها يضغط عليه.",
        "US rate decisions set the opportunity cost of holding gold; cuts support it, hikes pressure it.",
    ),
    "inflation": (
        "التضخم يرفع الطلب على الذهب كتحوّط، لكنه قد يدفع الفيدرالي للتشديد إذا كان مرتفعاً جداً.",
        "Inflation boosts hedging demand for gold, but may force the Fed to tighten if it runs too hot.",
    ),
    "jobs": (
        "بيانات الوظائف القوية تقوّي الدولار وتزيد احتمالية رفع الفائدة، بينما الضعف يدعم الذهب.",
        "Strong jobs data lifts the dollar and hike odds; weakness supports gold.",
    ),
    "election": (
        "الانتخابات وعدم اليقين السياسي يدفعان المستثمرين نحو الملاذات الآمنة مثل الذهب.",
        "Elections and political uncertainty push investors toward safe havens such as gold.",
    ),
    "geopolitics": (
        "الحروب والتوترات الجيوسياسية تزيد الطلب على الذهب كملاذ آمن.",
        "Wars and geopolitical tension increase safe-haven demand for gold.",
    ),
    "dollar": (
        "العلاقة بين الذهب والدولار عكسية غالباً؛ ضعف الدولار يدعم الذهب.",
        "Gold and the dollar are usually inversely correlated; a weaker dollar supports gold.",
    ),
    "technical": (
        "مستويات الدعم والمقاومة والاتجاه قصير المدى تؤثر على قرارات المتداولين.",
        "Support, resistance and the short-term trend shape trader decisions.",
    ),
    "other": (
        "خبر عام قد يؤثر على شهية المخاطرة وبالتالي على تدفقات الذهب.",
        "A general story that may affect risk appetite and therefore gold flows.",
    ),
}

_cache: dict[str, tuple[float, object]] = {}


def _fetch_rss(query: str, lang: str) -> list[dict]:
    if lang == "ar":
        params = {"q": query, "hl": "ar", "gl": "IQ", "ceid": "IQ:ar"}
    else:
        params = {"q": query, "hl": "en-US", "gl": "US", "ceid": "US:en"}
    url = f"{GOOGLE_NEWS}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as res:
        raw = res.read()
    root = ET.fromstring(raw)
    out = []
    for item in root.iter("item"):
        title = html.unescape((item.findtext("title") or "").strip())
        link = (item.findtext("link") or "").strip()
        pub = (item.findtext("pubDate") or "").strip()
        source_node = item.find("source")
        source = html.unescape(source_node.text.strip()) if source_node is not None and source_node.text else ""
        published = None
        try:
            published = parsedate_to_datetime(pub)
            if published.tzinfo is None:
                published = published.replace(tzinfo=timezone.utc)
        except Exception:
            published = None
        if title:
            out.append(
                {
                    "title": title,
                    "link": link,
                    "source": source,
                    "published_at": published.isoformat() if published else "",
                    "_published": published,
                }
            )
    return out


def _normalize(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[\u064B-\u065F\u0670]", "", text)
    text = text.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").replace("ى", "ي")
    return re.sub(r"\s+", " ", text)


def _detect_category(text: str, hint: str) -> str:
    t = _normalize(text)
    if any(k in t for k in ["فيدرالي", "fomc", "powell", "باول", "الفائدة", "rate", "fed"]):
        return "fed"
    if any(k in t for k in ["تضخم", "inflation", "cpi", "pce", "اسعار المستهلك"]):
        return "inflation"
    if any(k in t for k in ["وظائف", "بطالة", "payroll", "jobs", "nfp", "unemployment"]):
        return "jobs"
    if any(k in t for k in ["انتخابات", "election", "ترامب", "trump", "congress", "الكونغرس"]):
        return "election"
    if any(k in t for k in ["حرب", "توتر", "صراع", "عقوبات", "war", "sanctions", "conflict", "geopolit"]):
        return "geopolitics"
    if any(k in t for k in ["دولار", "dollar", "dxy", "forex"]):
        return "dollar"
    if any(k in t for k in ["دعم", "مقاومة", "support", "resistance", "technical"]):
        return "technical"
    return hint


def _sentiment(text: str) -> tuple[float, int]:
    t = _normalize(text)
    score = 0.0
    hits = 0

    for phrase in POSITIVE_AR:
        if _normalize(phrase) in t:
            score += 1
            hits += 1
    for phrase in NEGATIVE_AR:
        if _normalize(phrase) in t:
            score -= 1
            hits += 1
    for phrase in POSITIVE_EN:
        if phrase in t:
            score += 1
            hits += 1
    for phrase in NEGATIVE_EN:
        if phrase in t:
            score -= 1
            hits += 1

    # قواعد دقيقة للعبارات المتضاربة
    if any(_normalize(p) in t for p in ["ارتفاع الدولار", "قوة الدولار", "دولار قوي"]) or "strong dollar" in t:
        score -= 1.5
    if any(_normalize(p) in t for p in ["تراجع الدولار", "ضعف الدولار"]) or "weak dollar" in t or "weaker dollar" in t:
        score += 1.5
    if any(_normalize(p) in t for p in ["خفض الفائدة", "خفض أسعار الفائدة"]) or "rate cut" in t:
        score += 1.0
    if any(_normalize(p) in t for p in ["رفع الفائدة", "رفع أسعار الفائدة"]) or "rate hike" in t:
        score -= 1.0
    if any(_normalize(p) in t for p in ["وقف إطلاق النار", "تهدئة", "اتفاق"]) or "ceasefire" in t:
        score -= 1.2

    score = max(-2.5, min(2.5, score))
    if abs(score) < 0.35:
        return 0.0, hits
    return score / 2.5, hits


def _impact(text: str) -> str:
    t = _normalize(text)
    high = [
        "فيدرالي", "الفائدة", "تضخم", "وظائف", "انتخابات", "حرب", "عقوبات",
        "fed", "fomc", "rate", "inflation", "cpi", "payroll", "election", "war", "sanctions",
    ]
    medium = ["دولار", "dollar", "ذهب", "gold", "سعر", "price", "توقعات", "forecast"]
    if any(k in t for k in high):
        return "high"
    if any(k in t for k in medium):
        return "medium"
    return "low"


def _clean_title(title: str, source: str) -> str:
    if source and title.endswith(f" - {source}"):
        return title[: -(len(source) + 3)].strip()
    return title


def _load_news() -> dict:
    raw: list[dict] = []
    errors = 0

    def job(entry):
        query, lang, hint = entry
        try:
            return _fetch_rss(query, lang), hint
        except Exception:
            return [], hint

    with ThreadPoolExecutor(max_workers=len(QUERIES)) as pool:
        results = list(pool.map(job, QUERIES))

    seen = set()
    for items, hint in results:
        if not items:
            errors += 1
            continue
        for item in items:
            title = item["title"]
            key = re.sub(r"\W+", "", _normalize(title))[:90]
            if key in seen:
                continue
            seen.add(key)
            published = item.get("_published")
            age_hours = 999
            if published:
                age_hours = max(0.0, (datetime.now(timezone.utc) - published).total_seconds() / 3600)
            if age_hours > 24 * 14:
                continue
            sentiment, hits = _sentiment(title)
            category = _detect_category(title, hint)
            weight = max(0.15, 1 - age_hours / (24 * 5))
            raw.append(
                {
                    "title": _clean_title(title, item.get("source", "")),
                    "link": item.get("link", ""),
                    "source": item.get("source", "") or "Google News",
                    "published_at": item.get("published_at", ""),
                    "age_hours": round(age_hours, 1),
                    "sentiment": round(sentiment, 3),
                    "keyword_hits": hits,
                    "impact": _impact(title),
                    "category": category,
                    "_weight": weight,
                }
            )

    raw.sort(key=lambda x: x["published_at"], reverse=True)
    items = raw[:50]

    weighted_sum = 0.0
    weight_total = 0.0
    positive = negative = neutral = 0
    for item in items[:35]:
        impact_weight = {"high": 1.6, "medium": 1.0, "low": 0.6}[item["impact"]]
        w = item["_weight"] * impact_weight
        weighted_sum += item["sentiment"] * w
        weight_total += w
        if item["sentiment"] > 0.15:
            positive += 1
        elif item["sentiment"] < -0.15:
            negative += 1
        else:
            neutral += 1

    news_score = (weighted_sum / weight_total) if weight_total else 0.0
    catalysts = [i for i in items if i["impact"] == "high"][:6]
    for item in items:
        item.pop("_weight", None)

    return {
        "ok": True,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "items": items,
        "summary": {
            "score": round(news_score, 3),
            "positive": positive,
            "negative": negative,
            "neutral": neutral,
            "count": len(items),
            "sources": len({i["source"] for i in items if i["source"]}),
        },
        "catalysts": catalysts,
        "errors": errors,
    }


def _sentiment_label(score: float, lang: str) -> str:
    if score > 0.15:
        return "إيجابي للذهب" if lang != "en" else "Bullish for gold"
    if score < -0.15:
        return "سلبي للذهب" if lang != "en" else "Bearish for gold"
    return "محايد" if lang != "en" else "Neutral"


def _localize(raw: dict, lang: str) -> dict:
    en = lang == "en"
    items = []
    for item in raw.get("items", []):
        copy = dict(item)
        copy["sentiment_label"] = _sentiment_label(copy.get("sentiment", 0), lang)
        category = copy.get("category", "other")
        copy["category_label"] = CATEGORY_LABELS.get(category, CATEGORY_LABELS["other"])[
            1 if en else 0
        ]
        copy["why"] = CATEGORY_WHY.get(category, CATEGORY_WHY["other"])[1 if en else 0]
        items.append(copy)

    summary = dict(raw.get("summary", {}))
    score = float(summary.get("score") or 0)
    if score > 0.15:
        summary["label"] = "إيجابية للذهب" if not en else "Bullish for gold"
    elif score < -0.15:
        summary["label"] = "سلبية للذهب" if not en else "Bearish for gold"
    else:
        summary["label"] = "متوازنة" if not en else "Balanced"

    by_title = {i["title"]: i for i in items}
    catalysts = [by_title[c["title"]] for c in raw.get("catalysts", []) if c["title"] in by_title]

    return {
        "ok": raw.get("ok", True),
        "generated_at": raw.get("generated_at", ""),
        "lang": "en" if en else "ar",
        "items": items,
        "summary": summary,
        "catalysts": catalysts,
        "errors": raw.get("errors", 0),
        **({"error": raw["error"]} if raw.get("error") else {}),
    }


def get_news(lang: str = "ar") -> dict:
    lang = "en" if lang == "en" else "ar"
    now = time.time()
    hit = _cache.get("news_raw")
    if hit and now - hit[0] < NEWS_CACHE_SECONDS:
        return _localize(hit[1], lang)
    try:
        payload = _load_news()
        _cache["news_raw"] = (now, payload)
        return _localize(payload, lang)
    except Exception as exc:
        if hit:
            cached = dict(hit[1])
            cached["ok"] = False
            cached["error"] = (
                "Could not refresh news; showing the last saved copy."
                if lang == "en"
                else "تعذر تحديث الأخبار، تُعرض آخر نسخة محفوظة."
            )
            return _localize(cached, lang)
        return {
            "ok": False,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "lang": lang,
            "items": [],
            "summary": {
                "score": 0,
                "label": "Not available" if lang == "en" else "غير متاح",
                "positive": 0,
                "negative": 0,
                "neutral": 0,
                "count": 0,
                "sources": 0,
            },
            "catalysts": [],
            "error": (
                f"Could not load news: {exc}"
                if lang == "en"
                else f"تعذر تحميل الأخبار: {exc}"
            ),
        }


def news_by_category(payload: dict, category: str) -> list[dict]:
    if category == "all":
        return payload.get("items", [])
    return [i for i in payload.get("items", []) if i.get("category") == category]


def time_ago(iso_value: str) -> str:
    if not iso_value:
        return ""
    try:
        dt = datetime.fromisoformat(iso_value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        diff = datetime.now(timezone.utc) - dt
        minutes = int(diff.total_seconds() // 60)
        if minutes < 60:
            return f"منذ {max(minutes, 1)} دقيقة"
        hours = minutes // 60
        if hours < 24:
            return f"منذ {hours} ساعة"
        return f"منذ {hours // 24} يوم"
    except Exception:
        return ""
