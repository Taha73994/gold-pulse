"""إعلانات المنتجات والمحلات — مصدر ربح مالك التطبيق."""
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import or_
from sqlalchemy.orm import Session

from .database import get_db
from .models import Ad
from .security import require_admin

router = APIRouter(prefix="/api", tags=["ads"])

PACKAGES = [
    {
        "code": "basic",
        "name_ar": "الباقة الأساسية",
        "name_en": "Basic",
        "days": 7,
        "price_iqd": 5000,
        "placement": "shops",
        "featured": False,
        "perks_ar": ["ظهور 7 أيام", "صورة واحدة", "رقم هاتف وواتساب", "زر اتصال مباشر"],
        "perks_en": ["7-day listing", "One image", "Phone & WhatsApp", "Direct call button"],
    },
    {
        "code": "plus",
        "name_ar": "الباقة المميزة",
        "name_en": "Plus",
        "days": 14,
        "price_iqd": 15000,
        "placement": "shops",
        "featured": True,
        "perks_ar": [
            "ظهور 14 يوماً",
            "إعلان مميز في دليل المحلات",
            "أولوية في الترتيب",
            "صورة ووصف كامل",
        ],
        "perks_en": [
            "14-day listing",
            "Featured in the shops directory",
            "Priority ordering",
            "Image and full description",
        ],
    },
    {
        "code": "premium",
        "name_ar": "الباقة الذهبية",
        "name_en": "Gold",
        "days": 30,
        "price_iqd": 35000,
        "placement": "home",
        "featured": True,
        "perks_ar": [
            "ظهور 30 يوماً",
            "بانر في الصفحة الرئيسية",
            "إعلان مميز في المحلات",
            "أولوية قصوى + إحصائيات",
        ],
        "perks_en": [
            "30-day listing",
            "Home-screen banner",
            "Featured in shops",
            "Top priority + statistics",
        ],
    },
]

PLACEMENTS = {"home", "shops", "news", "market"}
CATEGORIES = {
    "general": ("عام", "General"),
    "jewelry": ("مجوهرات", "Jewelry"),
    "gold": ("ذهب وسبائك", "Gold & Bullion"),
    "watches": ("ساعات", "Watches"),
    "services": ("خدمات", "Services"),
    "electronics": ("إلكترونيات", "Electronics"),
}


class AdIn(BaseModel):
    title: str = Field(min_length=2, max_length=200)
    title_en: str = ""
    description: str = ""
    description_en: str = ""
    price: float = 0
    currency: str = "IQD"
    image_url: str = ""
    phone: str = ""
    whatsapp: str = ""
    link: str = ""
    city: str = ""
    category: str = "general"
    shop_id: Optional[int] = None
    placement: str = "home"
    package: str = "basic"
    is_featured: bool = False
    is_active: bool = True
    days: Optional[int] = None
    expires_at: Optional[str] = None


def serialize(ad: Ad) -> dict:
    now = datetime.utcnow()
    days_left = None
    if ad.expires_at:
        days_left = max(0, (ad.expires_at - now).days)
    category = CATEGORIES.get(ad.category, CATEGORIES["general"])
    return {
        "id": ad.id,
        "title": ad.title,
        "title_en": ad.title_en,
        "description": ad.description,
        "description_en": ad.description_en,
        "price": ad.price,
        "currency": ad.currency,
        "image_url": ad.image_url,
        "phone": ad.phone,
        "whatsapp": ad.whatsapp,
        "link": ad.link,
        "city": ad.city,
        "category": ad.category,
        "category_ar": category[0],
        "category_en": category[1],
        "shop_id": ad.shop_id,
        "placement": ad.placement,
        "package": ad.package,
        "is_featured": ad.is_featured,
        "is_active": ad.is_active,
        "views": ad.views,
        "clicks": ad.clicks,
        "created_at": ad.created_at.isoformat() if ad.created_at else None,
        "expires_at": ad.expires_at.isoformat() if ad.expires_at else None,
        "days_left": days_left,
    }


def _package(code: str) -> dict:
    for pkg in PACKAGES:
        if pkg["code"] == code:
            return pkg
    return PACKAGES[0]


def _apply(ad: Ad, data: AdIn) -> Ad:
    pkg = _package(data.package)
    values = data.model_dump()
    days = values.pop("days", None)
    expires_raw = values.pop("expires_at", None)
    values["placement"] = values["placement"] if values["placement"] in PLACEMENTS else pkg["placement"]
    values["category"] = values["category"] if values["category"] in CATEGORIES else "general"
    for key, value in values.items():
        setattr(ad, key, value)
    if data.is_featured or pkg["featured"]:
        ad.is_featured = True
    if expires_raw:
        try:
            ad.expires_at = datetime.fromisoformat(expires_raw)
        except ValueError:
            ad.expires_at = datetime.utcnow() + timedelta(days=pkg["days"])
    elif days:
        ad.expires_at = datetime.utcnow() + timedelta(days=max(1, min(365, days)))
    elif not ad.expires_at or ad.expires_at < datetime.utcnow():
        ad.expires_at = datetime.utcnow() + timedelta(days=pkg["days"])
    if not ad.placement:
        ad.placement = pkg["placement"]
    return ad


@router.get("/ads/packages")
def packages():
    return {"ok": True, "items": PACKAGES}


@router.get("/ads")
def list_ads(
    placement: str = "",
    category: str = "",
    city: str = "",
    featured: bool = False,
    q: str = "",
    limit: int = Query(40, ge=1, le=120),
    db: Session = Depends(get_db),
):
    now = datetime.utcnow()
    query = db.query(Ad).filter(Ad.is_active.is_(True))
    query = query.filter(or_(Ad.expires_at.is_(None), Ad.expires_at > now))
    if placement:
        query = query.filter(Ad.placement == placement)
    if category:
        query = query.filter(Ad.category == category)
    if city:
        query = query.filter(Ad.city == city)
    if featured:
        query = query.filter(Ad.is_featured.is_(True))
    if q:
        like = f"%{q.strip()}%"
        query = query.filter(or_(Ad.title.ilike(like), Ad.title_en.ilike(like)))
    rows = (
        query.order_by(Ad.is_featured.desc(), Ad.created_at.desc())
        .limit(limit)
        .all()
    )
    return {"ok": True, "items": [serialize(a) for a in rows], "count": len(rows)}


@router.get("/ads/{ad_id}")
def get_ad(ad_id: int, db: Session = Depends(get_db)):
    ad = db.get(Ad, ad_id)
    if not ad or not ad.is_active:
        raise HTTPException(status_code=404, detail="الإعلان غير موجود")
    ad.views = (ad.views or 0) + 1
    db.commit()
    db.refresh(ad)
    return {"ok": True, "item": serialize(ad)}


@router.post("/ads/{ad_id}/click")
def click_ad(ad_id: int, db: Session = Depends(get_db)):
    ad = db.get(Ad, ad_id)
    if not ad:
        raise HTTPException(status_code=404, detail="الإعلان غير موجود")
    ad.clicks = (ad.clicks or 0) + 1
    db.commit()
    return {"ok": True, "clicks": ad.clicks}


@router.get("/admin/ads", dependencies=[Depends(require_admin)])
def admin_ads(db: Session = Depends(get_db)):
    rows = db.query(Ad).order_by(Ad.id.desc()).all()
    total_views = sum(a.views or 0 for a in rows)
    total_clicks = sum(a.clicks or 0 for a in rows)
    active = sum(
        1
        for a in rows
        if a.is_active and (a.expires_at is None or a.expires_at > datetime.utcnow())
    )
    return {
        "ok": True,
        "items": [serialize(a) for a in rows],
        "stats": {
            "total": len(rows),
            "active": active,
            "views": total_views,
            "clicks": total_clicks,
            "ctr": round(total_clicks / total_views * 100, 2) if total_views else 0,
        },
    }


@router.post("/admin/ads", dependencies=[Depends(require_admin)])
def create_ad(data: AdIn, db: Session = Depends(get_db)):
    ad = _apply(Ad(), data)
    db.add(ad)
    db.commit()
    db.refresh(ad)
    return {"ok": True, "item": serialize(ad)}


@router.put("/admin/ads/{ad_id}", dependencies=[Depends(require_admin)])
def update_ad(ad_id: int, data: AdIn, db: Session = Depends(get_db)):
    ad = db.get(Ad, ad_id)
    if not ad:
        raise HTTPException(status_code=404, detail="الإعلان غير موجود")
    _apply(ad, data)
    db.commit()
    db.refresh(ad)
    return {"ok": True, "item": serialize(ad)}


@router.delete("/admin/ads/{ad_id}", dependencies=[Depends(require_admin)])
def delete_ad(ad_id: int, db: Session = Depends(get_db)):
    ad = db.get(Ad, ad_id)
    if not ad:
        raise HTTPException(status_code=404, detail="الإعلان غير موجود")
    db.delete(ad)
    db.commit()
    return {"ok": True}
