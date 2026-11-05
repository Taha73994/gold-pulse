"""مصادر السوق: الذهب، الدولار، عوائد السندات، ومؤشرات المخاطرة."""
import json
import math
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from statistics import pstdev
from threading import Lock

from .config import (
    DEFAULT_USD_IQD,
    FX_CACHE_SECONDS,
    FX_MARKET_CACHE_SECONDS,
    HTTP_TIMEOUT,
    LOCAL_BUY_MARGIN_PCT,
    LOCAL_SELL_MARGIN_PCT,
    MARKET_CACHE_SECONDS,
    OUNCE_GRAMS,
    PARALLEL_FX_FALLBACK_PREMIUM_PCT,
    PARALLEL_FX_URL,
    USER_AGENT,
)

YAHOO_CHART = "https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
FX_URL = "https://open.er-api.com/v6/latest/USD"

_cache: dict[str, tuple[float, object]] = {}
_cache_lock = Lock()
_last_good: dict[str, object] = {}


def _cached(key: str, ttl: int, loader):
    now = time.time()
    with _cache_lock:
        hit = _cache.get(key)
        if hit and now - hit[0] < ttl:
            return hit[1]
    try:
        value = loader()
        with _cache_lock:
            _cache[key] = (now, value)
            _last_good[key] = value
        return value
    except Exception:
        with _cache_lock:
            if key in _last_good:
                return _last_good[key]
        raise


def _http_json(url: str):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as res:
        return json.loads(res.read().decode("utf-8"))


def fetch_yahoo(symbol: str, range_: str = "1y", interval: str = "1d") -> dict:
    query = urllib.parse.urlencode({"interval": interval, "range": range_})
    url = f"{YAHOO_CHART.format(symbol=urllib.parse.quote(symbol))}?{query}"
    payload = _http_json(url)
    result = (payload.get("chart") or {}).get("result") or []
    if not result:
        raise RuntimeError(f"لا توجد بيانات لـ {symbol}")
    node = result[0]
    meta = node.get("meta") or {}
    timestamps = node.get("timestamp") or []
    quote = ((node.get("indicators") or {}).get("quote") or [{}])[0]
    opens = quote.get("open") or []
    highs = quote.get("high") or []
    lows = quote.get("low") or []
    closes = quote.get("close") or []
    volumes = quote.get("volume") or []

    candles = []
    for i, ts in enumerate(timestamps):
        close = closes[i] if i < len(closes) else None
        if close is None:
            continue
        candles.append(
            {
                "time": datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%d"),
                "open": round(float(opens[i] or close), 4) if i < len(opens) else round(float(close), 4),
                "high": round(float(highs[i] or close), 4) if i < len(highs) else round(float(close), 4),
                "low": round(float(lows[i] or close), 4) if i < len(lows) else round(float(close), 4),
                "close": round(float(close), 4),
                "volume": int(volumes[i] or 0) if i < len(volumes) else 0,
            }
        )
    if not candles:
        raise RuntimeError(f"بيانات فارغة لـ {symbol}")
    return {
        "symbol": symbol,
        "currency": meta.get("currency", "USD"),
        "exchange": meta.get("exchangeName", ""),
        "price": round(float(meta.get("regularMarketPrice") or candles[-1]["close"]), 4),
        "previous_close": round(float(meta.get("chartPreviousClose") or candles[-2]["close"]), 4)
        if len(candles) > 1
        else round(candles[-1]["close"], 4),
        "candles": candles,
    }


def gold_history(range_: str = "1y") -> dict:
    allowed = {"1mo", "3mo", "6mo", "1y", "2y", "5y"}
    if range_ not in allowed:
        range_ = "1y"
    return _cached(f"gold:{range_}", MARKET_CACHE_SECONDS, lambda: fetch_yahoo("GC=F", range_))


def _fx_loader() -> dict:
    data = _http_json(FX_URL)
    rate = float((data.get("rates") or {}).get("IQD") or DEFAULT_USD_IQD)
    return {
        "usd_iqd": round(rate, 2),
        "updated": data.get("time_last_update_utc") or "",
        "source": "open.er-api.com",
    }


def usd_iqd() -> dict:
    try:
        return _cached("fx", FX_CACHE_SECONDS, _fx_loader)
    except Exception:
        return {
            "usd_iqd": DEFAULT_USD_IQD,
            "updated": "",
            "source": "قيمة احتياطية",
        }


def _parallel_fx_loader() -> dict:
    """سعر الدولار في السوق الموازي (سوق الكفاح/بغداد) والسعر الرسمي.

    المصدر المجاني: IQWealth — https://iraqsm.com/data/fx.json
    """
    data = _http_json(PARALLEL_FX_URL)
    parallel = data.get("parallel") or {}
    official = data.get("official") or {}
    shops = data.get("shops") or {}

    buy = float(parallel.get("buy") or 0)
    sell = float(parallel.get("sell") or 0)
    if buy <= 0 and sell <= 0:
        raise RuntimeError("لا يوجد سعر موازٍ في المصدر")
    if sell <= 0:
        sell = buy
    if buy <= 0:
        buy = sell

    cbi = float(official.get("cbi") or 0) or float(usd_iqd()["usd_iqd"])
    mid = (buy + sell) / 2
    gap = float(data.get("gapPct") or 0)
    if not gap and cbi:
        gap = (mid - cbi) / cbi * 100

    return {
        "parallel_buy": round(buy, 2),
        "parallel_sell": round(sell, 2),
        "parallel_mid": round(mid, 2),
        "official": round(cbi, 2),
        "gap_pct": round(gap, 2),
        "shop_buy": round(float(shops.get("buy") or 0), 2),
        "shop_sell": round(float(shops.get("sell") or 0), 2),
        "available": True,
        "estimated": False,
        "stale": bool(parallel.get("stale")),
        "published_at": parallel.get("publishedAt") or "",
        "as_of": data.get("asOf") or "",
        "source": "IQWealth (iraqsm.com)",
        "source_url": "https://iraqsm.com/fx",
    }


def market_fx() -> dict:
    """سعر السوق الموازي مع بديل تقديري عند تعذر المصدر."""
    try:
        return _cached("fx_market", FX_MARKET_CACHE_SECONDS, _parallel_fx_loader)
    except Exception:
        official = usd_iqd()
        base = float(official.get("usd_iqd") or DEFAULT_USD_IQD)
        est = base * (1 + PARALLEL_FX_FALLBACK_PREMIUM_PCT / 100)
        return {
            "parallel_buy": round(est - 1, 2),
            "parallel_sell": round(est + 1, 2),
            "parallel_mid": round(est, 2),
            "official": round(base, 2),
            "gap_pct": round(PARALLEL_FX_FALLBACK_PREMIUM_PCT, 2),
            "shop_buy": 0,
            "shop_sell": 0,
            "available": False,
            "estimated": True,
            "stale": True,
            "published_at": official.get("updated") or "",
            "as_of": "",
            "source": "تقدير من السعر الرسمي",
            "source_url": "https://iraqsm.com/fx",
        }


def _pct_change(values: list[float], days: int) -> float:
    if len(values) <= days:
        return 0.0
    old = values[-days - 1]
    if old == 0:
        return 0.0
    return (values[-1] - old) / old * 100


def _macro_symbol(symbol: str, key: str) -> dict:
    try:
        data = fetch_yahoo(symbol, "3mo")
        closes = [c["close"] for c in data["candles"]]
        return {
            "symbol": symbol,
            "value": round(closes[-1], 3),
            "change_5d_pct": round(_pct_change(closes, 5), 3),
            "change_20d_pct": round(_pct_change(closes, 20), 3),
            "ok": True,
        }
    except Exception:
        return {"symbol": symbol, "value": 0, "change_5d_pct": 0, "change_20d_pct": 0, "ok": False}


def macro_snapshot() -> dict:
    def loader():
        return {
            "dxy": _macro_symbol("DX-Y.NYB", "dxy"),
            "us10y": _macro_symbol("^TNX", "us10y"),
            "sp500": _macro_symbol("^GSPC", "sp500"),
            "vix": _macro_symbol("^VIX", "vix"),
        }

    try:
        return _cached("macro", MARKET_CACHE_SECONDS, loader)
    except Exception:
        return {
            "dxy": {"value": 0, "change_5d_pct": 0, "ok": False},
            "us10y": {"value": 0, "change_5d_pct": 0, "ok": False},
            "sp500": {"value": 0, "change_5d_pct": 0, "ok": False},
            "vix": {"value": 0, "change_5d_pct": 0, "ok": False},
        }


def price_per_gram(usd_oz: float, iqd_rate: float, karat: int = 24) -> float:
    return usd_oz / OUNCE_GRAMS * iqd_rate * (karat / 24)


def local_quotes(grams: dict[str, float], parallel_rate: float) -> dict:
    """سعر الشاشة + هامش السوق = سعر البيع والشراء التقريبي في العراق.

    ask = سعر البيع للزبون (يشتري الذهب)، bid = سعر الشراء من الزبون (يبيع الذهب).
    سعر الشاشة نفسه محسوب بسعر صرف السوق الموازي.
    """
    buy = max(0.0, LOCAL_BUY_MARGIN_PCT)
    sell = max(0.0, LOCAL_SELL_MARGIN_PCT)
    by_karat = {}
    for karat, screen in grams.items():
        bid = screen * (1 - buy / 100)
        ask = screen * (1 + sell / 100)
        by_karat[karat] = {
            "screen": round(screen),
            "bid": round(bid),
            "ask": round(ask),
            "spread": round(ask - bid),
            "spread_pct": round((ask - bid) / screen * 100, 2) if screen else 0,
        }
    return {
        "buy_margin_pct": buy,
        "sell_margin_pct": sell,
        "parallel_rate": round(parallel_rate, 2),
        "rate_kind": "parallel",
        "by_karat": by_karat,
        "note_ar": (
            "محسوب بسعر صرف السوق الموازي (الكفاح) مع هامش السوق القابل للضبط؛ "
            "قد يختلف من محل لآخر."
        ),
        "note_en": (
            "Priced at the parallel (Kifah) exchange rate plus a configurable "
            "market margin; varies by dealer."
        ),
    }


def market_snapshot(lang: str = "ar") -> dict:
    gold = gold_history("1y")
    candles = gold["candles"]
    closes = [c["close"] for c in candles]
    last = candles[-1]
    prev = candles[-2] if len(candles) > 1 else last
    change = last["close"] - prev["close"]
    change_pct = (change / prev["close"] * 100) if prev["close"] else 0
    fx = usd_iqd()
    mfx = market_fx()
    rate = float(mfx["parallel_sell"])
    official_rate = float(mfx["official"])
    macro = macro_snapshot()
    grams = {
        "24": round(price_per_gram(last["close"], rate, 24)),
        "22": round(price_per_gram(last["close"], rate, 22)),
        "21": round(price_per_gram(last["close"], rate, 21)),
        "18": round(price_per_gram(last["close"], rate, 18)),
    }
    grams_official = {
        "24": round(price_per_gram(last["close"], official_rate, 24)),
        "22": round(price_per_gram(last["close"], official_rate, 22)),
        "21": round(price_per_gram(last["close"], official_rate, 21)),
        "18": round(price_per_gram(last["close"], official_rate, 18)),
    }

    return {
        "ok": True,
        "source": "Yahoo Finance — Gold Futures (GC=F)",
        "symbol": "GC=F",
        "as_of": datetime.now(timezone.utc).isoformat(),
        "usd_oz": round(last["close"], 2),
        "change_usd": round(change, 2),
        "change_pct": round(change_pct, 2),
        "open": round(last["open"], 2),
        "high": round(last["high"], 2),
        "low": round(last["low"], 2),
        "prev_close": round(prev["close"], 2),
        "usd_iqd": rate,
        "usd_iqd_official": official_rate,
        "fx": mfx,
        "fx_source": mfx["source"],
        "fx_updated": mfx["published_at"] or fx["updated"],
        "iqd_gram": grams,
        "iqd_gram_official": grams_official,
        "local": local_quotes(grams, rate),
        "spark": [round(c["close"], 2) for c in candles[-40:]],
        "volatility_20d": round(pstdev([c["close"] for c in candles[-20:]]) / last["close"] * 100, 2)
        if len(candles) >= 20
        else 0,
        "macro": macro,
        "disclaimer": (
            "Gold is quoted in USD per troy ounce. The dinar price here uses the "
            "parallel (black-market) USD/IQD rate, which is how gold is priced in Iraq; "
            "the official rate is shown for reference only."
            if lang == "en"
            else (
                "السعر العالمي بالدولار للأونصة. سعر الدينار هنا محسوب بسعر صرف "
                "السوق الموازي (السوق السوداء) لأن الذهب في العراق يُسعَّر به، "
                "والسعر الرسمي معروض للمقارنة فقط."
            )
        ),
    }


def history_payload(range_: str = "1y") -> dict:
    gold = gold_history(range_)
    return {
        "range": range_,
        "symbol": gold["symbol"],
        "candles": gold["candles"],
        "source": "Yahoo Finance — GC=F",
    }


def moving_average(values: list[float], period: int) -> float | None:
    if len(values) < period:
        return None
    return sum(values[-period:]) / period


def exponential_average(values: list[float], period: int) -> float | None:
    if len(values) < period:
        return None
    multiplier = 2 / (period + 1)
    ema = sum(values[:period]) / period
    for value in values[period:]:
        ema = (value - ema) * multiplier + ema
    return ema


def rsi(values: list[float], period: int = 14) -> float | None:
    if len(values) <= period:
        return None
    gains = []
    losses = []
    for i in range(1, len(values)):
        diff = values[i] - values[i - 1]
        gains.append(max(diff, 0))
        losses.append(max(-diff, 0))
    avg_gain = sum(gains[:period]) / period
    avg_loss = sum(losses[:period]) / period
    for i in range(period, len(gains)):
        avg_gain = (avg_gain * (period - 1) + gains[i]) / period
        avg_loss = (avg_loss * (period - 1) + losses[i]) / period
    if avg_loss == 0:
        return 100.0
    rs = avg_gain / avg_loss
    return 100 - (100 / (1 + rs))


def atr(candles: list[dict], period: int = 14) -> float | None:
    if len(candles) <= period:
        return None
    ranges = []
    for i in range(1, len(candles)):
        high = candles[i]["high"]
        low = candles[i]["low"]
        prev_close = candles[i - 1]["close"]
        ranges.append(max(high - low, abs(high - prev_close), abs(low - prev_close)))
    value = sum(ranges[:period]) / period
    for r in ranges[period:]:
        value = (value * (period - 1) + r) / period
    return value


def indicators(candles: list[dict]) -> dict:
    closes = [c["close"] for c in candles]
    highs = [c["high"] for c in candles]
    lows = [c["low"] for c in candles]
    ema12 = exponential_average(closes, 12)
    ema26 = exponential_average(closes, 26)
    macd_line = (ema12 - ema26) if ema12 is not None and ema26 is not None else None
    macd_signal = None
    if macd_line is not None:
        macd_series = []
        for i in range(26, len(closes) + 1):
            e12 = exponential_average(closes[:i], 12)
            e26 = exponential_average(closes[:i], 26)
            if e12 is not None and e26 is not None:
                macd_series.append(e12 - e26)
        macd_signal = exponential_average(macd_series, 9)
    macd_hist = (macd_line - macd_signal) if macd_line is not None and macd_signal is not None else None
    atr_value = atr(candles)
    return {
        "close": round(closes[-1], 2),
        "sma20": round(moving_average(closes, 20), 2) if moving_average(closes, 20) else None,
        "sma50": round(moving_average(closes, 50), 2) if moving_average(closes, 50) else None,
        "sma200": round(moving_average(closes, 200), 2) if moving_average(closes, 200) else None,
        "rsi14": round(rsi(closes), 2) if rsi(closes) is not None else None,
        "macd": round(macd_line, 3) if macd_line is not None else None,
        "macd_signal": round(macd_signal, 3) if macd_signal is not None else None,
        "macd_hist": round(macd_hist, 3) if macd_hist is not None else None,
        "atr14": round(atr_value, 2) if atr_value is not None else None,
        "return_1d": round(_pct_change(closes, 1), 2),
        "return_5d": round(_pct_change(closes, 5), 2),
        "return_20d": round(_pct_change(closes, 20), 2),
        "support20": round(min(lows[-20:]), 2) if len(lows) >= 20 else round(min(lows), 2),
        "resistance20": round(max(highs[-20:]), 2) if len(highs) >= 20 else round(max(highs), 2),
        "volatility20": round(pstdev([c["close"] for c in candles[-20:]]) / closes[-1] * 100, 2)
        if len(closes) >= 20
        else 0,
    }
