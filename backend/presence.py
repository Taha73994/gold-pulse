"""عدّاد المستخدمين الفعليين — نبضة جهاز عند فتح التطبيق."""
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from .database import get_db
from .models import DeviceActivity

router = APIRouter(prefix="/api", tags=["presence"])


class PresenceIn(BaseModel):
    device_id: str = Field(min_length=6, max_length=120)
    platform: str = ""
    locale: str = "ar"
    app_version: str = ""


def _count(db: Session, since: datetime) -> int:
    return db.query(DeviceActivity).filter(DeviceActivity.last_seen >= since).count()


@router.post("/presence")
def heartbeat(data: PresenceIn, db: Session = Depends(get_db)):
    now = datetime.utcnow()
    row = db.query(DeviceActivity).filter(DeviceActivity.device_id == data.device_id).first()
    if row:
        row.last_seen = now
        row.platform = data.platform or row.platform
        row.locale = data.locale or row.locale
        row.app_version = data.app_version or row.app_version
        row.launches = (row.launches or 1) + 1
    else:
        row = DeviceActivity(
            device_id=data.device_id,
            first_seen=now,
            last_seen=now,
            platform=data.platform,
            locale=data.locale,
            app_version=data.app_version,
            launches=1,
        )
        db.add(row)
    db.commit()
    return {
        "ok": True,
        "online_now": _count(db, now - timedelta(minutes=15)),
        "active_today": _count(db, now - timedelta(days=1)),
        "active_week": _count(db, now - timedelta(days=7)),
        "total_users": db.query(DeviceActivity).count(),
    }


@router.get("/presence/stats")
def presence_stats(db: Session = Depends(get_db)):
    """أرقام عامة فقط: العدد الكلي والمتصلون الآن.

    التفاصيل (المنصات، اللغات، النسخ، النشاط اليومي) متاحة للمالك فقط
    عبر ‎/api/admin/presence.
    """
    now = datetime.utcnow()
    return {
        "ok": True,
        "online_now": _count(db, now - timedelta(minutes=15)),
        "active_today": _count(db, now - timedelta(days=1)),
        "active_week": _count(db, now - timedelta(days=7)),
        "active_month": _count(db, now - timedelta(days=30)),
        "total_users": db.query(DeviceActivity).count(),
        "generated_at": now.isoformat(),
    }
