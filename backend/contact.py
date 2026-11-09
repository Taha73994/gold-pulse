"""بيانات التواصل مع المالك — يعرضها التطبيق للمستخدمين."""
from datetime import datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from .database import get_db
from .models import OwnerContact
from .security import require_admin

router = APIRouter(prefix="/api", tags=["contact"])


class ContactIn(BaseModel):
    name: str = Field(default="", max_length=120)
    name_en: str = Field(default="", max_length=120)
    phone: str = Field(default="", max_length=40)
    whatsapp: str = Field(default="", max_length=40)
    telegram: str = Field(default="", max_length=80)
    email: str = Field(default="", max_length=120)
    facebook: str = Field(default="", max_length=200)
    instagram: str = Field(default="", max_length=200)
    tiktok: str = Field(default="", max_length=200)


def _row(db: Session) -> OwnerContact:
    row = db.get(OwnerContact, 1)
    if row is None:
        row = OwnerContact(id=1)
        db.add(row)
        db.commit()
        db.refresh(row)
    return row


def serialize(row: OwnerContact) -> dict:
    return {
        "name": row.name or "",
        "name_en": row.name_en or "",
        "phone": row.phone or "",
        "whatsapp": row.whatsapp or "",
        "telegram": row.telegram or "",
        "email": row.email or "",
        "facebook": row.facebook or "",
        "instagram": row.instagram or "",
        "tiktok": row.tiktok or "",
        "updated_at": row.updated_at.isoformat() if row.updated_at else None,
    }


@router.get("/contact")
def get_contact(db: Session = Depends(get_db)):
    """عام: يُرجع الحقول المعبّأة فقط، مع أعلام التوفّر."""
    data = serialize(_row(db))
    channels = {
        key: data[key]
        for key in (
            "phone",
            "whatsapp",
            "telegram",
            "email",
            "facebook",
            "instagram",
            "tiktok",
        )
        if data[key]
    }
    return {"ok": True, "has_any": bool(channels), "channels": channels, **data}


@router.put("/admin/contact", dependencies=[Depends(require_admin)])
def set_contact(data: ContactIn, db: Session = Depends(get_db)):
    row = _row(db)
    row.name = data.name.strip()
    row.name_en = data.name_en.strip()
    row.phone = data.phone.strip()
    row.whatsapp = data.whatsapp.strip()
    row.telegram = data.telegram.strip()
    row.email = data.email.strip()
    row.facebook = data.facebook.strip()
    row.instagram = data.instagram.strip()
    row.tiktok = data.tiktok.strip()
    row.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(row)
    return {"ok": True, "item": serialize(row)}
