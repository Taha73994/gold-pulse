"""خادم نبض الذهب — أسعار حية، تحليل، أخبار، محلات، إعلانات، وتنبيهات."""
import asyncio
import logging
import os
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path

from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

from . import ads as ads_module
from . import shops as shops_module
from .admin import router as admin_router
from .alerts import list_alerts, record_analysis
from .analysis import build_analysis
from .config import (
    ADS_CONTACT_PHONE,
    ADS_CONTACT_WHATSAPP,
    COPYRIGHT_AR,
    COPYRIGHT_EN,
    DISCLAIMER,
    OWNER_NAME,
    UPLOAD_DIR,
)
from .contact import router as contact_router
from .currency import convert, currency_payload
from .database import Base, SessionLocal, engine, get_db
from .market import history_payload, market_snapshot
from .models import Alert, OwnerContact  # noqa: F401 — لإنشاء الجدول
from .news import get_news
from .presence import router as presence_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("gold_pulse")

_monitor_task: asyncio.Task | None = None


async def _monitor_loop():
    await asyncio.sleep(8)
    while True:
        try:
            result = await asyncio.to_thread(build_analysis, "ar")
            db = SessionLocal()
            try:
                record_analysis(db, result)
            finally:
                db.close()
            logger.info("تم تحديث إشارة الذهب: %s @ %.2f", result["action"], result["price"])
        except Exception as exc:
            logger.warning("تعذر تحديث الإشارة في الخلفية: %s", exc)
        await asyncio.sleep(120)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    global _monitor_task
    _monitor_task = asyncio.create_task(_monitor_loop())
    yield
    if _monitor_task:
        _monitor_task.cancel()
        try:
            await _monitor_task
        except asyncio.CancelledError:
            pass


app = FastAPI(
    title="Gold Pulse API — نبض الذهب",
    description=(
        "API لأسعار الذهب الحية، التحليل الفني والأساسي، معنويات الأخبار، "
        "دليل المحلات، الإعلانات، والعملات. أداة دعم قرار وليست نصيحة استثمارية."
    ),
    version="1.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(shops_module.router)
app.include_router(ads_module.router)
app.include_router(presence_router)
app.include_router(contact_router)
app.include_router(admin_router)

app.mount("/media", StaticFiles(directory=UPLOAD_DIR), name="media")

# نسخة الويب (PWA) — تُقدَّم من نفس الخادم إن وُجد مجلد webapp.
WEBAPP_DIR = Path(os.getenv("GOLD_WEB_DIR") or (Path(__file__).resolve().parent.parent / "webapp"))
_HAS_WEBAPP = WEBAPP_DIR.is_dir() and (WEBAPP_DIR / "index.html").is_file()


def _lang(lang: str) -> str:
    return "en" if lang == "en" else "ar"


@app.get("/", include_in_schema=False)
def root():
    if _HAS_WEBAPP:
        return RedirectResponse("/index.html")
    return RedirectResponse("/docs")


@app.get("/health")
def health():
    return {
        "ok": True,
        "service": "gold-pulse-api",
        "version": "1.1.0",
        "time": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/api/config")
def config(lang: str = "ar"):
    lang = _lang(lang)
    return {
        "app_name": "Gold Pulse" if lang == "en" else "نبض الذهب",
        "app_name_ar": "نبض الذهب",
        "app_name_en": "Gold Pulse",
        "version": "1.1.0",
        "owner": OWNER_NAME,
        "copyright": COPYRIGHT_EN if lang == "en" else COPYRIGHT_AR,
        "disclaimer": DISCLAIMER,
        "ads_contact_phone": ADS_CONTACT_PHONE,
        "ads_contact_whatsapp": ADS_CONTACT_WHATSAPP,
        "admin_enabled": True,
        "features": [
            "Live gold price in USD/oz and IQD/gram",
            "Technical and macro analysis",
            "News sentiment",
            "Gold calculator",
            "Gold shops directory",
            "Classified ads",
            "Currency converter (IQD, USD, Toman, Lira)",
            "Signal alerts",
            "Active users counter",
        ]
        if lang == "en"
        else [
            "سعر الذهب العالمي والدينار العراقي",
            "تحليل فني وأساسي",
            "معنويات الأخبار",
            "حاسبة ذهب",
            "دليل محلات الذهب",
            "إعلانات مبوبة",
            "تحويل العملات (دينار، دولار، تومان، ليرة)",
            "تنبيهات تغيّر الإشارة",
            "عدّاد المستخدمين الفعليين",
        ],
    }


@app.get("/api/market")
def market(lang: str = "ar"):
    try:
        return market_snapshot(_lang(lang))
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"تعذر جلب بيانات السوق: {exc}")


@app.get("/api/history")
def history(range_: str = Query("1y", alias="range")):
    try:
        return history_payload(range_)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"تعذر جلب التاريخ السعري: {exc}")


@app.get("/api/analysis")
def analysis(lang: str = "ar", db: Session = Depends(get_db)):
    try:
        result = build_analysis(_lang(lang))
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"تعذر إنتاج التحليل: {exc}")
    record_analysis(db, result)
    return result


@app.get("/api/mentor")
def mentor(lang: str = "ar", db: Session = Depends(get_db)):
    try:
        result = build_analysis(_lang(lang))
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"تعذر إنتاج إرشاد التداول: {exc}")
    record_analysis(db, result)
    return {
        "ok": True,
        "generated_at": result["generated_at"],
        "price": result["price"],
        "action": result["action"],
        "action_label": result["action_label"],
        "confidence": result["confidence"],
        "verdict": result["verdict"],
        "mentor": result["mentor"],
        "forecast": result["forecast"],
        "plan": result["plan"],
        "levels": result["levels"],
        "indicators": result["indicators"],
        "disclaimer": result["disclaimer"],
    }


@app.get("/api/news")
def news(
    category: str = "all",
    limit: int = Query(40, ge=1, le=80),
    lang: str = "ar",
):
    payload = get_news(_lang(lang))
    items = payload.get("items", [])
    if category and category != "all":
        items = [i for i in items if i.get("category") == category]
    out = dict(payload)
    out["items"] = items[:limit]
    return out


@app.get("/api/alerts")
def alerts(db: Session = Depends(get_db)):
    return list_alerts(db)


@app.post("/api/alerts/read-all")
def read_all(db: Session = Depends(get_db)):
    db.query(Alert).filter(Alert.is_read.is_(False)).update({"is_read": True})
    db.commit()
    return {"ok": True}


@app.post("/api/alerts/{alert_id}/read")
def read_one(alert_id: int, db: Session = Depends(get_db)):
    alert = db.get(Alert, alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="التنبيه غير موجود")
    alert.is_read = True
    db.commit()
    return {"ok": True}


@app.get("/api/currencies")
def currencies():
    return currency_payload()


@app.get("/api/convert")
def currency_convert(
    amount: float = Query(1, ge=0, le=1_000_000_000),
    source: str = Query("USD", alias="from"),
    target: str = Query("IQD", alias="to"),
):
    try:
        return convert(amount, source, target)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


# يجب أن يبقى آخر شيء: يقدّم تطبيق الويب/PWA من نفس الخادم.
if _HAS_WEBAPP:
    app.mount("/", StaticFiles(directory=WEBAPP_DIR, html=True), name="webapp")
