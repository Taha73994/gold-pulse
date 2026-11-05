"""دليل محلات الذهب: إضافة، تعديل، بحث، وزيارات."""
import math
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import or_
from sqlalchemy.orm import Session

from .database import get_db
from .models import Shop
from .security import require_admin

router = APIRouter(prefix="/api", tags=["shops"])


class ShopIn(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    name_en: str = ""
    city: str = ""
    city_en: str = ""
    address: str = ""
    address_en: str = ""
    phone: str = ""
    whatsapp: str = ""
    latitude: float = 0
    longitude: float = 0
    map_url: str = ""
    image_url: str = ""
    description: str = ""
    description_en: str = ""
    working_hours: str = ""
    # None = القيمة الافتراضية: المحلات التي يضيفها المالك موثّقة تلقائياً
    is_verified: bool | None = None
    is_featured: bool = False
    is_active: bool = True


def serialize(shop: Shop) -> dict:
    return {
        "id": shop.id,
        "name": shop.name,
        "name_en": shop.name_en,
        "city": shop.city,
        "city_en": shop.city_en,
        "address": shop.address,
        "address_en": shop.address_en,
        "phone": shop.phone,
        "whatsapp": shop.whatsapp,
        "latitude": shop.latitude,
        "longitude": shop.longitude,
        "map_url": shop.map_url,
        "image_url": shop.image_url,
        "description": shop.description,
        "description_en": shop.description_en,
        "working_hours": shop.working_hours,
        "is_verified": shop.is_verified,
        "is_featured": shop.is_featured,
        "is_active": shop.is_active,
        "views": shop.views,
        "created_at": shop.created_at.isoformat() if shop.created_at else None,
    }


def _apply(shop: Shop, data: ShopIn) -> Shop:
    for key, value in data.model_dump(exclude_none=True).items():
        setattr(shop, key, value)
    return shop


@router.get("/shops")
def list_shops(
    q: str = "",
    city: str = "",
    featured: bool = False,
    limit: int = Query(80, ge=1, le=200),
    db: Session = Depends(get_db),
):
    query = db.query(Shop).filter(Shop.is_active.is_(True))
    if city:
        query = query.filter(or_(Shop.city == city, Shop.city_en == city))
    if featured:
        query = query.filter(Shop.is_featured.is_(True))
    if q:
        like = f"%{q.strip()}%"
        query = query.filter(
            or_(
                Shop.name.ilike(like),
                Shop.name_en.ilike(like),
                Shop.city.ilike(like),
                Shop.address.ilike(like),
            )
        )
    rows = (
        query.order_by(Shop.is_featured.desc(), Shop.is_verified.desc(), Shop.id.desc())
        .limit(limit)
        .all()
    )
    return {"ok": True, "items": [serialize(s) for s in rows], "count": len(rows)}


@router.get("/shops/cities")
def shop_cities(db: Session = Depends(get_db)):
    rows = (
        db.query(Shop.city, Shop.city_en)
        .filter(Shop.is_active.is_(True), Shop.city != "")
        .distinct()
        .all()
    )
    seen = set()
    items = []
    for city, city_en in rows:
        key = (city or city_en).strip()
        if not key or key in seen:
            continue
        seen.add(key)
        items.append({"city": city or city_en, "city_en": city_en or city})
    return {"ok": True, "items": sorted(items, key=lambda x: x["city"])}


@router.get("/shops/{shop_id}")
def get_shop(shop_id: int, db: Session = Depends(get_db)):
    shop = db.get(Shop, shop_id)
    if not shop or not shop.is_active:
        raise HTTPException(status_code=404, detail="المحل غير موجود")
    shop.views = (shop.views or 0) + 1
    db.commit()
    db.refresh(shop)
    return {"ok": True, "item": serialize(shop)}


@router.get("/admin/shops", dependencies=[Depends(require_admin)])
def admin_shops(db: Session = Depends(get_db)):
    rows = db.query(Shop).order_by(Shop.id.desc()).all()
    return {
        "ok": True,
        "items": [serialize(s) for s in rows],
        "count": len(rows),
        "cities": sorted({s.city for s in rows if s.city}),
    }


@router.post("/admin/shops", dependencies=[Depends(require_admin)])
def create_shop(data: ShopIn, db: Session = Depends(get_db)):
    shop = _apply(Shop(), data)
    # أي محل يضيفه المالك يُعدّ موثّقاً ما لم يُلغِ الخيار صراحةً.
    if data.is_verified is None:
        shop.is_verified = True
    db.add(shop)
    db.commit()
    db.refresh(shop)
    return {"ok": True, "item": serialize(shop)}


@router.put("/admin/shops/{shop_id}", dependencies=[Depends(require_admin)])
def update_shop(shop_id: int, data: ShopIn, db: Session = Depends(get_db)):
    shop = db.get(Shop, shop_id)
    if not shop:
        raise HTTPException(status_code=404, detail="المحل غير موجود")
    _apply(shop, data)
    db.commit()
    db.refresh(shop)
    return {"ok": True, "item": serialize(shop)}


@router.delete("/admin/shops/{shop_id}", dependencies=[Depends(require_admin)])
def delete_shop(shop_id: int, db: Session = Depends(get_db)):
    shop = db.get(Shop, shop_id)
    if not shop:
        raise HTTPException(status_code=404, detail="المحل غير موجود")
    db.delete(shop)
    db.commit()
    return {"ok": True}


def distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    if not all([lat1, lon1, lat2, lon2]):
        return -1
    radius = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )
    return round(radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)), 2)
