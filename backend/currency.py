"""أسعار العملات وتحويلها — دولار، دينار عراقي، تومان، ليرة وأكثر."""
import time
import urllib.request
import json
from threading import Lock

from .config import (
    CURRENCY_CACHE_SECONDS,
    DEFAULT_USD_IQD,
    HTTP_TIMEOUT,
    TGJU_MIRRORS,
    TGJU_URL,
    USD_TOMAN_FALLBACK,
    USER_AGENT,
)

FX_URL = "https://open.er-api.com/v6/latest/USD"
TOMAN_SOURCE = "TGJU — السوق الحر (طهران)"

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


def _fetch_toman() -> float:
    """سعر الدولار الحر مقابل التومان (ريال ÷ 10) من TGJU.

    open.er-api يعطي سعراً رسمياً/مجمّعاً بعيداً عن سوق طهران الحر،
    لذلك نعتمد TGJU ونستخدم قيمته بالريال مقسومة على 10.
    """
    last_error: Exception | None = None
    for url in (TGJU_URL, *TGJU_MIRRORS):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as res:
                data = json.loads(res.read().decode("utf-8"))
            raw = (((data.get("current") or {}).get("price_dollar_rl") or {}).get("p"))
            if raw is None:
                raise RuntimeError("لا يوجد سعر دولار في استجابة TGJU")
            rial = float(str(raw).replace(",", "").strip())
            if rial <= 0:
                raise RuntimeError("سعر دولار غير صالح من TGJU")
            return round(rial / 10.0, 2)
        except Exception as exc:  # mirror may be blocked; try the next one
            last_error = exc
    raise RuntimeError(f"تعذر جلب سعر التومان: {last_error}")


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
        if code == "USD" or code == "TOM":
            continue
        value = raw.get(code)
        if value:
            rates[code] = float(value)
    rates["IQD"] = float(raw.get("IQD") or DEFAULT_USD_IQD)
    iqd_source = "سعر عالمي (open.er-api)"
    # الدينار العراقي في التحويل يجب أن يطابق سعر السوق الموازي المستخدم
    # في تسعير الذهب، لا السعر العالمي/الرسمي.
    try:
        from .market import market_fx

        parallel = float(market_fx().get("parallel_sell") or 0)
        if parallel > 0:
            rates["IQD"] = parallel
            iqd_source = "السوق الموازي (IQWealth)"
    except Exception:
        pass

    # التومان: سوق طهران الحر أولاً، ثم آخر قراءة ناجحة، ثم قيمة احتياطية.
    toman_source = TOMAN_SOURCE
    try:
        rates["TOM"] = _fetch_toman()
    except Exception:
        previous = None
        if _last_good:
            previous = (_last_good.get("rates") or {}).get("TOM")
        if previous:
            rates["TOM"] = float(previous)
            toman_source = f"{TOMAN_SOURCE} (آخر قراءة)"
        else:
            rates["TOM"] = USD_TOMAN_FALLBACK
            toman_source = "قيمة احتياطية — تعذر الاتصال بمصدر السوق الحر"

    payload = {
        "rates": rates,
        "updated": data.get("updated", ""),
        "source": data.get("source", ""),
        "toman_source": toman_source,
        "iqd_source": iqd_source,
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
        "usd_toman": round(float(rates.get("TOM") or 0), 2),
        "toman_source": data.get("toman_source", TOMAN_SOURCE),
        "iqd_source": data.get("iqd_source", "السوق الموازي (IQWealth)"),
        "note_ar": (
            "الدولار والتومان بسعر السوق الحر (طهران)، والدينار العراقي بسعر السوق الموازي. "
            "الأسعار استرشادية وقد تختلف قليلاً بين الصرافين."
        ),
        "note_en": (
            "USD/Toman uses the Tehran free market and IQD uses the Iraqi parallel market. "
            "Rates are indicative and may vary slightly between exchangers."
        ),
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
