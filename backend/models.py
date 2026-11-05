"""جداول الإشارات والتنبيهات، المحلات، الإعلانات، ونشاط المستخدمين."""
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, Integer, LargeBinary, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base


class SignalSnapshot(Base):
    __tablename__ = "signal_snapshots"

    id: Mapped[int] = mapped_column(primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)
    action: Mapped[str] = mapped_column(String(20), index=True)
    action_label: Mapped[str] = mapped_column(String(40), default="")
    score: Mapped[float] = mapped_column(Float, default=0)
    confidence: Mapped[int] = mapped_column(Integer, default=0)
    price: Mapped[float] = mapped_column(Float, default=0)
    horizon: Mapped[str] = mapped_column(String(40), default="")
    payload: Mapped[str] = mapped_column(Text, default="")


class Alert(Base):
    __tablename__ = "alerts"

    id: Mapped[int] = mapped_column(primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)
    kind: Mapped[str] = mapped_column(String(30), default="signal")
    severity: Mapped[str] = mapped_column(String(20), default="info")
    title: Mapped[str] = mapped_column(String(200))
    title_en: Mapped[str] = mapped_column(String(200), default="")
    body: Mapped[str] = mapped_column(Text, default="")
    body_en: Mapped[str] = mapped_column(Text, default="")
    action: Mapped[str] = mapped_column(String(20), default="")
    price: Mapped[float] = mapped_column(Float, default=0)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, index=True)


class Shop(Base):
    __tablename__ = "shops"

    id: Mapped[int] = mapped_column(primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    name: Mapped[str] = mapped_column(String(160), index=True)
    name_en: Mapped[str] = mapped_column(String(160), default="")
    city: Mapped[str] = mapped_column(String(80), default="", index=True)
    city_en: Mapped[str] = mapped_column(String(80), default="")
    address: Mapped[str] = mapped_column(String(240), default="")
    address_en: Mapped[str] = mapped_column(String(240), default="")
    phone: Mapped[str] = mapped_column(String(40), default="")
    whatsapp: Mapped[str] = mapped_column(String(40), default="")
    latitude: Mapped[float] = mapped_column(Float, default=0)
    longitude: Mapped[float] = mapped_column(Float, default=0)
    map_url: Mapped[str] = mapped_column(String(500), default="")
    image_url: Mapped[str] = mapped_column(String(500), default="")
    description: Mapped[str] = mapped_column(Text, default="")
    description_en: Mapped[str] = mapped_column(Text, default="")
    working_hours: Mapped[str] = mapped_column(String(120), default="")
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    views: Mapped[int] = mapped_column(Integer, default=0)


class Ad(Base):
    __tablename__ = "ads"

    id: Mapped[int] = mapped_column(primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    title: Mapped[str] = mapped_column(String(200))
    title_en: Mapped[str] = mapped_column(String(200), default="")
    description: Mapped[str] = mapped_column(Text, default="")
    description_en: Mapped[str] = mapped_column(Text, default="")
    price: Mapped[float] = mapped_column(Float, default=0)
    currency: Mapped[str] = mapped_column(String(10), default="IQD")
    image_url: Mapped[str] = mapped_column(String(500), default="")
    phone: Mapped[str] = mapped_column(String(40), default="")
    whatsapp: Mapped[str] = mapped_column(String(40), default="")
    link: Mapped[str] = mapped_column(String(500), default="")
    city: Mapped[str] = mapped_column(String(80), default="", index=True)
    category: Mapped[str] = mapped_column(String(60), default="general", index=True)
    shop_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    placement: Mapped[str] = mapped_column(String(30), default="home", index=True)
    package: Mapped[str] = mapped_column(String(30), default="basic")
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    views: Mapped[int] = mapped_column(Integer, default=0)
    clicks: Mapped[int] = mapped_column(Integer, default=0)


class OwnerContact(Base):
    """بيانات تواصل المالك — تظهر للمستخدم فقط للحقول المعبّأة."""

    __tablename__ = "owner_contact"

    id: Mapped[int] = mapped_column(primary_key=True, default=1)
    name: Mapped[str] = mapped_column(String(120), default="")
    name_en: Mapped[str] = mapped_column(String(120), default="")
    phone: Mapped[str] = mapped_column(String(40), default="")
    whatsapp: Mapped[str] = mapped_column(String(40), default="")
    telegram: Mapped[str] = mapped_column(String(80), default="")
    email: Mapped[str] = mapped_column(String(120), default="")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )


class DeviceActivity(Base):
    __tablename__ = "device_activity"

    id: Mapped[int] = mapped_column(primary_key=True)
    device_id: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    first_seen: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    last_seen: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)
    platform: Mapped[str] = mapped_column(String(40), default="")
    locale: Mapped[str] = mapped_column(String(10), default="ar")
    app_version: Mapped[str] = mapped_column(String(30), default="")
    launches: Mapped[int] = mapped_column(Integer, default=1)


class MediaFile(Base):
    """Uploaded images stored in DB so they survive redeploys."""

    __tablename__ = "media_files"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    content_type: Mapped[str] = mapped_column(String(80), default="image/png")
    data: Mapped[bytes] = mapped_column(LargeBinary)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Feedback(Base):
    """تقييم المستخدم للتطبيق (نجوم + ملاحظة) — يظهر للمالك فقط."""

    __tablename__ = "feedback"

    id: Mapped[int] = mapped_column(primary_key=True)
    device_id: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    rating: Mapped[int] = mapped_column(Integer, default=0)
    comment: Mapped[str] = mapped_column(Text, default="")
    lang: Mapped[str] = mapped_column(String(10), default="ar")
    app_version: Mapped[str] = mapped_column(String(30), default="")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )


class RateSnapshot(Base):
    """قراءات سعر صرف السوق الموازي لمتابعة التغير وتوليد التنبيهات."""

    __tablename__ = "rate_snapshots"

    id: Mapped[int] = mapped_column(primary_key=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, index=True
    )
    parallel: Mapped[float] = mapped_column(Float, default=0)
    official: Mapped[float] = mapped_column(Float, default=0)
    gap_pct: Mapped[float] = mapped_column(Float, default=0)
    source: Mapped[str] = mapped_column(String(120), default="")
