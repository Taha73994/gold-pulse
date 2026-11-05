"""أسعار العملات وتحويلها — دولار، دينار عراقي، تومان، ليرة وأكثر."""
import time
import urllib.request
import json
from threading import Lock

from .config import CURRENCY_CACHE_SECONDS, DEFAULT_USD_IQD, HTTP_TIMEOUT, USER_AGENT

FX_URL = "https://open.er-api.com/v6/latest/USD"

CURRENCIES = [
    {"code": "USD", "ar": "دولار أمريكي", "en": "US Dollar", "symbol": "$", "flag": "🇺🇸", "decimals": 2},
    {"code": "IQD", "ar": "دينار عراقي", "en": "Iraqi Dinar", "symbol": "د.ع", "flag": "🇮🇶", "decimals": 0},
    {"code": "TOM", "ar": "تومان إيراني", "en": "Iranian Toman", "symbol": "تومان", "flag": "🇮🇷", "decimals": 0},
    {"code": "TRY", "ar": "ليرة تركية", "en": "Turkish Lira", "symbol": "₺", "flag": "🇹🇷", "decimals": 2},
    {"code": "SYP", "ar": "ليرة سورية", "en": "Syrian Pound", "symbol": "ل.س", "flag": "🇸🇾", "decimals": 0},
    {"code": "LBP", "ar": "ليرة لبنانية", "en": "Lebanese Pound", "symbol": "ل.ل", "flag": "🇱🇧", "decimals": 0},
    {"code": "EUR", "ar": "يورو", "en": "Euro", "symbol": "€", "flag": "🇪🇺", "decimals": 2},
    {"code": "GBP", "ar": "جنيه إسترليني", "en": "British Pound", "symbol": "£", "flag": "🇬🇧", "decimals": 2},
    {"code": "AED", "ar": "درهم إماراتي", "en": "UAE Dirham", "symbol": "د.إ", "flag": "🇦🇪", "decimals": 2},
    {"code": "SAR", "ar": "ريال سعودي", "en": "Saudi Riyal", "symbol": "﷼", "flag": "🇸🇦", "decimals": 2},
    {"code": "KWD", "ar": "دينار كويتي", "en": "Kuwaiti Dinar", "symbol": "د.ك", "flag": "🇰🇼", "decimals": 3},
    {"code": "JOD", "ar": "دينار أردني", "en": "Jordanian Dinar", "symbol": "د.أ", "flag": "🇯🇴", "decimals": 3},
    {"code": "EGP", "ar": "جنيه مصري", "en": "Egyptian Pound", "symbol": "ج.م", "flag": "🇪🇬", "decimals": 2},
]

_codes = {c["code"] for c in CURRENCIES}
_cache: dict[str, tuple[float, dict]] = {}
_lock = Lock()
_last_good: dict | None = None


def _fetch() -> dict:
    req = urllib.request.Request(FX_URL, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as res:
        data = json.loads(res.read().decode("utf-8"))
    rates = data.get("rates") or {}
    if not rates:
        raise RuntimeError("لا توجد أسعار عملات")
    return {
        "rates": rates,
        "updated": data.get("time_last_update_utc", ""),
        "source": "open.er-api.com",
    }


def _rates() -> dict:
    global _last_good
    now = time.time()
    hit = _cache.get("fx")
    if hit and now - hit[0] < CURRENCY_CACHE_SECONDS:
        return hit[1]
    try:
        data = _fetch()
    except Exception:
        if _last_good:
            return _last_good
        usd_rates = {"USD": 1.0, "IQD": DEFAULT_USD_IQD}
        data = {"rates": usd_rates, "updated": "", "source": "قيمة احتياطية"}
    raw = data["rates"]
    rates = {"USD": 1.0}
    for code in _codes:
        if code == "USD":
            continue
        if code == "TOM":
            irr = float(raw.get("IRR") or 0)
            if irr:
                rates["TOM"] = round(irr / 10.0, 4)
            continue
        value = raw.get(code)
        if value:
            rates[code] = float(value)
    rates["IQD"] = float(raw.get("IQD") or DEFAULT_USD_IQD)
    payload = {
        "rates": rates,
        "updated": data.get("updated", ""),
        "source": data.get("source", ""),
    }
    with _lock:
        _cache["fx"] = (now, payload)
        _last_good = payload
    return payload


def _per_usd(code: str) -> float:
    rates = _rates()["rates"]
    return float(rates.get(code) or 0)


def currency_payload() -> dict:
    data = _rates()
    rates = data["rates"]
    items = []
    for meta in CURRENCIES:
        code = meta["code"]
        per_usd = rates.get(code)
        if not per_usd:
            continue
        items.append(
            {
                "code": code,
                "name_ar": meta["ar"],
                "name_en": meta["en"],
                "symbol": meta["symbol"],
                "flag": meta["flag"],
                "decimals": meta["decimals"],
                "per_usd": round(float(per_usd), 4),
                "per_iqd": round(float(per_usd) / rates["IQD"], 8),
                "usd_rate": round(1 / float(per_usd), 8),
            }
        )
    return {
        "ok": True,
        "base": "USD",
        "updated": data.get("updated", ""),
        "source": data.get("source", ""),
        "items": items,
        "usd_iqd": round(float(rates.get("IQD") or DEFAULT_USD_IQD), 2),
        "note_ar": "الأسعار استرشادية من سوق العملات العالمي. سعر الصرف المحلي في العراق قد يختلف قليلاً.",
        "note_en": "Indicative global FX rates. Local Iraqi market rates may differ slightly.",
    }


def convert(amount: float, source: str, target: str) -> dict:
    source = source.upper()
    target = target.upper()
    if source not in _codes or target not in _codes:
        raise ValueError("عملة غير مدعومة")
    src = _per_usd(source)
    dst = _per_usd(target)
    if not src or not dst:
        raise ValueError("سعر الصرف غير متاح حالياً")
    usd_value = amount / src
    result = usd_value * dst
    return {
        "ok": True,
        "amount": round(amount, 4),
        "from": source,
        "to": target,
        "result": round(result, 4),
        "rate": round(dst / src, 8),
        "usd_value": round(usd_value, 4),
        "updated": _rates()["updated"],
    }


def gold_per_gram_local(usd_oz: float, code: str = "IQD", karat: int = 24) -> float:
    from .config import OUNCE_GRAMS

    per_usd = _per_usd(code)
    return usd_oz / OUNCE_GRAMS * per_usd * (karat / 24)
