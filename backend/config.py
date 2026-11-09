"""إعدادات تطبيق نبض الذهب."""
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# مجلد البيانات: محلياً data/ — على Vercel نظام الملفات للقراءة فقط عدا /tmp.
_DEFAULT_DATA = Path("/tmp/gold-pulse") if os.getenv("VERCEL") else (BASE_DIR / "data")
DATA_DIR = Path(os.getenv("GOLD_DATA_DIR") or _DEFAULT_DATA)
UPLOAD_DIR = DATA_DIR / "uploads"
DATA_DIR.mkdir(parents=True, exist_ok=True)
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

DB_PATH = Path(os.getenv("GOLD_DB_PATH") or (DATA_DIR / "gold_pulse.db"))

HTTP_TIMEOUT = 20
MARKET_CACHE_SECONDS = 15
NEWS_CACHE_SECONDS = 300
FX_CACHE_SECONDS = 1800
CURRENCY_CACHE_SECONDS = 60
ALERT_MINUTES = 20

# سعر الدولار مقابل التومان في السوق الإيراني الحر (وليس السعر الرسمي).
# المصدر: TGJU (call1.tgju.org) — الرقم بالريال، نقسمه على 10 للتومان.
TGJU_URL = os.getenv("GOLD_TGJU_URL", "https://call1.tgju.org/ajax.json")
TGJU_MIRRORS = (
    "https://call1.tgju.org/ajax.json",
    "https://call2.tgju.org/ajax.json",
    "https://call3.tgju.org/ajax.json",
    "https://call4.tgju.org/ajax.json",
)
# قيمة احتياطية فقط إذا فشلت كل المصادر ولم توجد قراءة سابقة.
USD_TOMAN_FALLBACK = float(os.getenv("GOLD_USD_TOMAN", "250000"))

# تنبيهات حركة سعر الأونصة (ارتفاع/انخفاض)
PRICE_ALERT_PCT = float(os.getenv("GOLD_PRICE_ALERT_PCT", "0.9"))
PRICE_ALERT_MINUTES = int(os.getenv("GOLD_PRICE_ALERT_MINUTES", "45"))

# هامش سوق الذهب العراقي (نسبة مئوية من سعر الشاشة):
# سعر البيع للزبون = الشاشة + الهامش، وسعر الشراء من الزبون = الشاشة − الهامش.
LOCAL_BUY_MARGIN_PCT = float(os.getenv("GOLD_LOCAL_BUY_MARGIN_PCT", "3.0"))
LOCAL_SELL_MARGIN_PCT = float(os.getenv("GOLD_LOCAL_SELL_MARGIN_PCT", "3.0"))

# سعر صرف السوق الموازي (السوق السوداء) — الذهب في العراق يُسعَّر به.
PARALLEL_FX_URL = os.getenv("GOLD_PARALLEL_FX_URL", "https://iraqsm.com/data/fx.json")
FX_MARKET_CACHE_SECONDS = int(os.getenv("GOLD_FX_MARKET_CACHE_SECONDS", "30"))
PARALLEL_FX_FALLBACK_PREMIUM_PCT = float(
    os.getenv("GOLD_PARALLEL_FX_FALLBACK_PREMIUM_PCT", "11.5")
)

# مراقبة سعر الصرف والتنبيه عند صعوده أو نزوله.
RATE_SNAPSHOT_MINUTES = int(os.getenv("GOLD_RATE_SNAPSHOT_MINUTES", "10"))
RATE_ALERT_IQD = float(os.getenv("GOLD_RATE_ALERT_IQD", "5"))
RATE_ALERT_WINDOW_MINUTES = int(os.getenv("GOLD_RATE_ALERT_WINDOW_MINUTES", "180"))
RATE_ALERT_COOLDOWN_MINUTES = int(
    os.getenv("GOLD_RATE_ALERT_COOLDOWN_MINUTES", "120")
)

ADMIN_PIN = os.getenv("GOLD_ADMIN_PIN", "taha2026")
MAX_UPLOAD_BYTES = 3 * 1024 * 1024
ALLOWED_IMAGE_EXT = {"jpg", "jpeg", "png", "webp", "gif"}

OWNER_NAME = "Taha Ali"
COPYRIGHT_AR = "© 2026 Taha Ali — جميع الحقوق محفوظة"
COPYRIGHT_EN = "© 2026 Taha Ali — All rights reserved"
ADS_CONTACT_PHONE = os.getenv("GOLD_ADS_PHONE", "")
ADS_CONTACT_WHATSAPP = os.getenv("GOLD_ADS_WHATSAPP", "")

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)

DISCLAIMER = (
    "هذا التطبيق أداة دعم قرار تعتمد على بيانات السوق والأخبار، وليس نصيحة "
    "استثمارية مضمونة. أسعار الذهب متقلبة وقد تخسر جزءاً من رأس مالك. "
    "راجع دائماً مصدراً موثوقاً قبل أي عملية شراء أو بيع."
)
DISCLAIMER_EN = (
    "This app is a decision-support tool built on market data and news. It is not "
    "guaranteed investment advice. Gold prices are volatile and you may lose part "
    "of your capital. Always verify with a trusted source before buying or selling."
)

DEFAULT_USD_IQD = float(os.getenv("GOLD_DEFAULT_USD_IQD", "1517"))
OUNCE_GRAMS = 31.1034768
