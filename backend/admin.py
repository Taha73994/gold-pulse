"""لوحة المالك: تحقق، رفع صور، وإحصائيات."""
import base64
import binascii
import uuid
from datetime import datetime, timedelta
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.orm import Session

from .ads import PACKAGES
from .config import ALLOWED_IMAGE_EXT, MAX_UPLOAD_BYTES, UPLOAD_DIR
from .database import get_db
from .market import market_snapshot
from .models import Ad, Alert, DeviceActivity, Feedback, MediaFile, OwnerContact, Shop, SignalSnapshot
from .security import require_admin

router = APIRouter(prefix="/api/admin", tags=["admin"])


class LoginIn(BaseModel):
    pin: str


class UploadIn(BaseModel):
    filename: str = "image.jpg"
    data: str


@router.post("/login")
def login(data: LoginIn):
    from .config import ADMIN_PIN

    if data.pin != ADMIN_PIN:
        raise HTTPException(status_code=401, detail="رمز المالك غير صحيح")
    return {"ok": True, "role": "owner"}


@router.get("/ping", dependencies=[Depends(require_admin)])
def ping():
    return {"ok": True}


@router.post("/upload", dependencies=[Depends(require_admin)])
def upload_image(data: UploadIn, db: Session = Depends(get_db)):
    raw = data.data.strip()
    if "," in raw and raw.lower().startswith("data:"):
        raw = raw.split(",", 1)[1]
    ext = Path(data.filename).suffix.lower().lstrip(".")
    if ext not in ALLOWED_IMAGE_EXT:
        raise HTTPException(
            status_code=400,
            detail="صيغة الصورة غير مدعومة. استخدم JPG أو PNG أو WEBP.",
        )
    try:
        blob = base64.b64decode(raw, validate=True)
    except (binascii.Error, ValueError):
        raise HTTPException(status_code=400, detail="ملف الصورة غير صالح")
    if len(blob) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="حجم الصورة أكبر من 3 ميغابايت")
    name = f"{uuid.uuid4().hex}.{ext}"
    path = UPLOAD_DIR / name
    try:
        path.write_bytes(blob)
    except OSError:
        pass
    mime = {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
        "gif": "image/gif",
    }.get(ext, "application/octet-stream")
    try:
        db.add(MediaFile(name=name, content_type=mime, data=blob))
        db.commit()
    except Exception:
        db.rollback()
    return {"ok": True, "url": f"/api/media/{name}", "size": len(blob)}


@router.get("/presence", dependencies=[Depends(require_admin)])
def presence_details(db: Session = Depends(get_db)):
    """تفاصيل المستخدمين — للمالك فقط."""
    from .presence import _count

    now = datetime.utcnow()
    rows = db.query(DeviceActivity).all()
    platforms: dict[str, int] = {}
    locales: dict[str, int] = {}
    versions: dict[str, int] = {}
    for row in rows:
        platform = row.platform or "unknown"
        locale = row.locale or "ar"
        version = row.app_version or "—"
        platforms[platform] = platforms.get(platform, 0) + 1
        locales[locale] = locales.get(locale, 0) + 1
        versions[version] = versions.get(version, 0) + 1
    return {
        "ok": True,
        "online_now": _count(db, now - timedelta(minutes=15)),
        "active_today": _count(db, now - timedelta(days=1)),
        "active_week": _count(db, now - timedelta(days=7)),
        "active_month": _count(db, now - timedelta(days=30)),
        "total_users": len(rows),
        "new_today": db.query(DeviceActivity)
        .filter(
            DeviceActivity.first_seen
            >= now.replace(hour=0, minute=0, second=0, microsecond=0)
        )
        .count(),
        "launches_today": 0,
        "platforms": platforms,
        "locales": locales,
        "versions": versions,
        "generated_at": now.isoformat(),
    }


@router.get("/stats", dependencies=[Depends(require_admin)])
def stats(db: Session = Depends(get_db)):
    now = datetime.utcnow()
    ads = db.query(Ad).all()
    active_ads = [
        a for a in ads if a.is_active and (a.expires_at is None or a.expires_at > now)
    ]
    prices = {p["code"]: p["price_iqd"] for p in PACKAGES}
    revenue = sum(prices.get(a.package, 0) for a in active_ads)
    shops = db.query(Shop).count()
    active_shops = db.query(Shop).filter(Shop.is_active.is_(True)).count()
    users = db.query(DeviceActivity).count()
    today = (
        db.query(DeviceActivity)
        .filter(DeviceActivity.last_seen >= now.replace(hour=0, minute=0, second=0, microsecond=0))
        .count()
    )
    try:
        gold = market_snapshot()["usd_oz"]
    except Exception:
        gold = 0
    return {
        "ok": True,
        "generated_at": now.isoformat(),
        "users": {
            "total": users,
            "today": today,
            "online_15m": db.query(DeviceActivity)
            .filter(DeviceActivity.last_seen >= now - timedelta(minutes=15))
            .count(),
        },
        "shops": {"total": shops, "active": active_shops},
        "ads": {
            "total": len(ads),
            "active": len(active_ads),
            "featured": sum(1 for a in active_ads if a.is_featured),
            "views": sum(a.views or 0 for a in ads),
            "clicks": sum(a.clicks or 0 for a in ads),
            "estimated_revenue_iqd": revenue,
        },
        "alerts": {
            "total": db.query(Alert).count(),
            "unread": db.query(Alert).filter(Alert.is_read.is_(False)).count(),
        },
        "signals": db.query(SignalSnapshot).count(),
        "feedback": {
            "count": db.query(Feedback).count(),
            "average": round(
                float(db.query(func.avg(Feedback.rating)).scalar() or 0), 2
            ),
        },
        "gold_usd_oz": gold,
    }


# ---------------------------------------------------------------------------
# نسخ احتياطي / استرجاع — مهم عند الاستضافة ذات القرص المؤقت.
# ---------------------------------------------------------------------------

BACKUP_MODELS = {
    "shops": Shop,
    "ads": Ad,
    "contact": OwnerContact,
}


def _row_to_dict(row) -> dict:
    data = {}
    for col in row.__table__.columns:
        value = getattr(row, col.key)
        if isinstance(value, datetime):
            value = value.isoformat()
        data[col.key] = value
    return data


@router.get("/backup", dependencies=[Depends(require_admin)])
def export_backup(db: Session = Depends(get_db)):
    payload = {
        "ok": True,
        "version": 1,
        "exported_at": datetime.utcnow().isoformat(),
        "data": {name: [_row_to_dict(r) for r in db.query(model).all()] for name, model in BACKUP_MODELS.items()},
    }
    return payload


@router.post("/restore", dependencies=[Depends(require_admin)])
def import_backup(payload: dict, db: Session = Depends(get_db)):
    data = payload.get("data") if isinstance(payload.get("data"), dict) else payload
    restored = {}
    for name, model in BACKUP_MODELS.items():
        rows = data.get(name)
        if not isinstance(rows, list):
            continue
        db.query(model).delete()
        count = 0
        for item in rows:
            if not isinstance(item, dict):
                continue
            clean = {}
            for col in model.__table__.columns:
                if col.key == "id" or col.key not in item:
                    continue
                value = item[col.key]
                if isinstance(value, str) and col.type.__class__.__name__ == "DateTime":
                    try:
                        value = datetime.fromisoformat(value.replace("Z", "+00:00")).replace(tzinfo=None)
                    except ValueError:
                        value = None
                clean[col.key] = value
            if clean:
                db.add(model(**clean))
                count += 1
        restored[name] = count
    db.commit()
    return {"ok": True, "restored": restored}
