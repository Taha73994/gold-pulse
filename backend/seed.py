"""بذور تجريبية: محلات ذهب وإعلانات مع صور محلية.

التشغيل من مجلد gold_pulse:
    python -m backend.seed
"""
from __future__ import annotations

import math
import random
from datetime import datetime, timedelta
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from .config import UPLOAD_DIR
from .database import Base, SessionLocal, engine
from .models import Ad, Shop

random.seed(7)


def _gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size, top)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        draw.line([(0, y), (w, y)], fill=color)
    return img


def _glow(img: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int], alpha: int = 90) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = center
    for r in range(radius, 0, -6):
        a = int(alpha * (1 - r / radius) ** 2)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=(*color, a))
    layer = layer.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(layer) if img.mode == "RGBA" else img.paste(
        Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB"), (0, 0)
    )


def make_shop_image(path: Path, seed: int) -> None:
    rnd = random.Random(seed)
    w, h = 900, 560
    base = _gradient((w, h), (18, 21, 30), (34, 28, 16)).convert("RGBA")
    _glow(base, (w // 2, int(h * 0.42)), 260, (233, 196, 106), 110)

    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # خامات ذهبية: سبائك مائلة
    for i in range(3):
        bx = int(w * 0.22) + i * 120
        by = int(h * 0.52) - i * 26
        pts = [
            (bx, by),
            (bx + 210, by - 34),
            (bx + 210, by + 58),
            (bx, by + 92),
        ]
        d.polygon(pts, fill=(212, 175, 55, 60 + i * 30), outline=(246, 221, 156, 180))
        pts_top = [
            (bx, by),
            (bx + 210, by - 34),
            (bx + 244, by - 8),
            (bx + 34, by + 26),
        ]
        d.polygon(pts_top, fill=(246, 221, 156, 160 + i * 20))
    # عملات
    for i in range(14):
        cx = rnd.randint(40, w - 40)
        cy = rnd.randint(30, h - 30)
        r = rnd.randint(6, 22)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(233, 196, 106, rnd.randint(20, 70)))
    layer = layer.filter(ImageFilter.GaussianBlur(0.6))
    base.alpha_composite(layer)
    base.convert("RGB").save(path, quality=90)


def make_ad_image(path: Path, seed: int) -> None:
    rnd = random.Random(seed)
    w, h = 800, 640
    base = _gradient((w, h), (24, 26, 36), (54, 42, 20)).convert("RGBA")
    _glow(base, (int(w * 0.5), int(h * 0.45)), 220, (233, 196, 106), 120)
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # عقد/خاتم بسيط
    cx, cy = w // 2, int(h * 0.46)
    for r, a in [(150, 40), (120, 60), (92, 90)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(246, 221, 156, a), width=6)
    d.ellipse([cx - 44, cy - 44, cx + 44, cy + 44], fill=(233, 196, 106, 170))
    d.ellipse([cx - 26, cy - 26, cx + 26, cy + 26], fill=(24, 26, 36, 220))
    for _ in range(18):
        x = rnd.randint(20, w - 20)
        y = rnd.randint(20, h - 20)
        r = rnd.randint(2, 7)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 236, 179, rnd.randint(40, 120)))
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.4)))
    base.convert("RGB").save(path, quality=90)


SHOPS = [
    {
        "name": "مجوهرات النبض الذهبي",
        "name_en": "Gold Pulse Jewelry",
        "city": "بغداد",
        "city_en": "Baghdad",
        "address": "شارع النهر، مقابل سوق الذهب، الكرادة",
        "address_en": "Al-Nahr St., opposite the gold market, Karrada",
        "phone": "07701234567",
        "whatsapp": "9647701234567",
        "latitude": 33.3015,
        "longitude": 44.4175,
        "description": "سبائك وليرات ذهبية عيار 24 و22، أجور صياغة واضحة وخصم على الكميات. نبيع ونشتري بأسعار السوق اليومية.",
        "description_en": "24K and 22K bars and coins, transparent making charges and volume discounts. We buy and sell at daily market rates.",
        "working_hours": "9:00 ص – 8:00 م",
        "is_verified": True,
        "is_featured": True,
        "image": "shop1.png",
    },
    {
        "name": "ذهب أهل الكاظمية",
        "name_en": "Kadhimiya Gold House",
        "city": "بغداد",
        "city_en": "Baghdad",
        "address": "سوق الذهب، قرب مرقد الكاظمين",
        "address_en": "Gold souk, near Al-Kadhimiya shrine",
        "phone": "07811234568",
        "whatsapp": "9647811234568",
        "latitude": 33.3806,
        "longitude": 44.3383,
        "description": "تصميم أطقم زفاف وأساور عيار 21. تقييم مجاني للذهب القديم والتبديل بدون خسارة كبيرة.",
        "description_en": "Bridal sets and 21K bracelets. Free valuation for old gold and low-loss trade-ins.",
        "working_hours": "10:00 ص – 9:00 م",
        "is_verified": True,
        "is_featured": False,
        "image": "shop2.png",
    },
    {
        "name": "أربيل جولد سنتر",
        "name_en": "Erbil Gold Center",
        "city": "أربيل",
        "city_en": "Erbil",
        "address": "شارع 60 متر، قرب قلعة أربيل",
        "address_en": "60m Street, near Erbil Citadel",
        "phone": "07501234569",
        "whatsapp": "9647501234569",
        "latitude": 36.1911,
        "longitude": 44.0092,
        "description": "أكبر تشكيلة سبائك سويسرية وإماراتية مع شهادة أصالة. خدمة تسليم آمن داخل الإقليم.",
        "description_en": "Large selection of Swiss and UAE bars with authenticity certificates. Secure delivery inside the region.",
        "working_hours": "9:30 ص – 8:30 م",
        "is_verified": True,
        "is_featured": True,
        "image": "shop3.png",
    },
    {
        "name": "البصرة للمجوهرات",
        "name_en": "Basra Jewellers",
        "city": "البصرة",
        "city_en": "Basra",
        "address": "شارع الجزائر، العشار",
        "address_en": "Al-Jazair St., Ashar",
        "phone": "07712233445",
        "whatsapp": "9647712233445",
        "latitude": 30.5081,
        "longitude": 47.7835,
        "description": "أسعار تنافسية للسبائك وخدمة تقسيط للمشترين المنتظمين. نحدّث السعر لحظياً حسب البورصة.",
        "description_en": "Competitive bar pricing and instalments for regular buyers. Rates updated live with the market.",
        "working_hours": "9:00 ص – 7:30 م",
        "is_verified": False,
        "is_featured": False,
        "image": "shop4.png",
    },
    {
        "name": "نجف جولد",
        "name_en": "Najaf Gold",
        "city": "النجف",
        "city_en": "Najaf",
        "address": "شارع الرسول، سوق الذهب",
        "address_en": "Al-Rasoul St., gold market",
        "phone": "07803344556",
        "whatsapp": "9647803344556",
        "latitude": 31.9996,
        "longitude": 44.3292,
        "description": "تخصص في الليرات العثمانية والسبائك الصغيرة للادخار. فحص عيار مجاني بأجهزة دقيقة.",
        "description_en": "Specialists in Ottoman coins and small savings bars. Free karat testing with precision equipment.",
        "working_hours": "9:00 ص – 8:00 م",
        "is_verified": True,
        "is_featured": False,
        "image": "shop5.png",
    },
    {
        "name": "السليمانية للذهب",
        "name_en": "Sulaymaniyah Gold",
        "city": "السليمانية",
        "city_en": "Sulaymaniyah",
        "address": "شارع سالم، مركز المدينة",
        "address_en": "Salem Street, city center",
        "phone": "07704455667",
        "whatsapp": "9647704455667",
        "latitude": 35.5613,
        "longitude": 45.4358,
        "description": "مجوهرات كردية تقليدية وحديثة، وخدمة بيع وشراء يومية بأسعار معلنة على الشاشة.",
        "description_en": "Traditional and modern Kurdish jewellery, daily buy/sell with rates displayed on screen.",
        "working_hours": "9:30 ص – 8:00 م",
        "is_verified": False,
        "is_featured": False,
        "image": "shop6.png",
    },
]

ADS = [
    {
        "title": "سبيكة ذهب 50 غرام عيار 24 مع شهادة",
        "title_en": "50g 24K gold bar with certificate",
        "description": "سبيكة سويسرية مختومة مع شهادة أصالة وفاتورة. مناسبة للادخار طويل الأمد. التسليم في بغداد أو إرسال مؤمّن.",
        "description_en": "Swiss sealed bar with authenticity certificate and invoice. Ideal for long-term saving. Delivery in Baghdad or insured shipping.",
        "price": 9900000,
        "currency": "IQD",
        "city": "بغداد",
        "category": "gold",
        "placement": "home",
        "is_featured": True,
        "phone": "07701234567",
        "whatsapp": "9647701234567",
        "image": "ad1.png",
        "days": 30,
    },
    {
        "title": "طقم زفاف عيار 21 — تصميم 2026",
        "title_en": "21K bridal set — 2026 design",
        "description": "طقم كامل (قلادة، أساور، أقراط، خاتم) بوزن 42 غرام وأجور صياغة مخفضة لهذا الشهر.",
        "description_en": "Full set (necklace, bracelets, earrings, ring) weighing 42g with reduced making charges this month.",
        "price": 5250000,
        "currency": "IQD",
        "city": "بغداد",
        "category": "jewelry",
        "placement": "shops",
        "is_featured": True,
        "phone": "07811234568",
        "whatsapp": "9647811234568",
        "image": "ad2.png",
        "days": 21,
    },
    {
        "title": "ليرات ذهبية عثمانية أصلية",
        "title_en": "Genuine Ottoman gold coins",
        "description": "ليرات مصكوكة أصلية بوزن 7.2 غرام، مناسبة للهدايا والادخار. الكمية محدودة.",
        "description_en": "Genuine minted coins, 7.2g each, ideal for gifts and saving. Limited quantity.",
        "price": 1450000,
        "currency": "IQD",
        "city": "النجف",
        "category": "gold",
        "placement": "market",
        "is_featured": False,
        "phone": "07803344556",
        "whatsapp": "9647803344556",
        "image": "ad3.png",
        "days": 14,
    },
    {
        "title": "ساعة ذهبية مستعملة بحالة ممتازة",
        "title_en": "Pre-owned gold watch, excellent condition",
        "description": "ساعة سويسرية بإطار ذهب 18 عيار مع علبة ووثائق. الفحص متاح قبل الشراء.",
        "description_en": "Swiss watch with 18K gold case, box and papers. Inspection available before purchase.",
        "price": 3800,
        "currency": "USD",
        "city": "أربيل",
        "category": "watches",
        "placement": "shops",
        "is_featured": False,
        "phone": "07501234569",
        "whatsapp": "9647501234569",
        "image": "ad4.png",
        "days": 30,
    },
]


def main() -> None:
    Base.metadata.create_all(bind=engine)
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    for i, item in enumerate(SHOPS, start=1):
        path = UPLOAD_DIR / item["image"]
        if not path.exists():
            make_shop_image(path, i * 13)

    for i, item in enumerate(ADS, start=1):
        path = UPLOAD_DIR / item["image"]
        if not path.exists():
            make_ad_image(path, i * 29)

    db = SessionLocal()
    try:
        if db.query(Shop).count() == 0:
            for item in SHOPS:
                db.add(Shop(**{k: v for k, v in item.items() if k != "image"}, image_url=item["image"]))
        if db.query(Ad).count() == 0:
            for item in ADS:
                days = item["days"]
                data = {k: v for k, v in item.items() if k not in {"image", "days"}}
                db.add(
                    Ad(
                        **data,
                        image_url=item["image"],
                        expires_at=datetime.utcnow() + timedelta(days=days),
                    )
                )
        db.commit()
        print(f"shops={db.query(Shop).count()} ads={db.query(Ad).count()}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
