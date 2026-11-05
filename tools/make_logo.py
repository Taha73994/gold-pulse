"""توليد شعار «نبض الذهب» وأيقونات التطبيق لكل المنصات."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "flutter" / "gold_pulse_app"
ASSETS = APP / "assets" / "images"

SS = 4
SIZE = 1024


def _lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _rounded_gradient(size: int, radius: int) -> Image.Image:
    w = size
    img = Image.new("RGB", (w, w), (10, 12, 17))
    draw = ImageDraw.Draw(img)
    for y in range(w):
        t = y / (w - 1)
        draw.line([(0, y), (w, y)], fill=_lerp((28, 22, 12), (10, 12, 17), t))
    mask = Image.new("L", (w, w), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, w - 1], radius=radius, fill=255)
    out = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def _gold_line(draw: ImageDraw.ImageDraw, pts, width: int) -> None:
    colors = [
        (246, 231, 180),
        (233, 196, 106),
        (212, 168, 60),
        (201, 155, 47),
        (233, 196, 106),
        (246, 231, 180),
    ]
    n = len(pts) - 1
    for i in range(n):
        t = i / max(1, n - 1)
        color = _lerp(colors[0], colors[-1], t)
        draw.line([pts[i], pts[i + 1]], fill=(*color, 255), width=width, joint="curve")
        # رؤوس دائرية
        r = width // 2
        draw.ellipse(
            [pts[i][0] - r, pts[i][1] - r, pts[i][0] + r, pts[i][1] + r],
            fill=(*color, 255),
        )


def make_logo() -> Image.Image:
    w = SIZE * SS
    canvas = _rounded_gradient(w, int(0.21 * w)).convert("RGBA")

    # حد ذهبي داخل الشعار
    border = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    bd = ImageDraw.Draw(border)
    inset = int(0.012 * w)
    bd.rounded_rectangle(
        [inset, inset, w - inset, w - inset],
        radius=int(0.20 * w),
        outline=(233, 196, 106, 150),
        width=int(0.008 * w),
    )
    canvas.alpha_composite(border)

    # وهج خلف الخط
    glow = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    pts = [
        (int(0.16 * w), int(0.60 * w)),
        (int(0.27 * w), int(0.60 * w)),
        (int(0.34 * w), int(0.49 * w)),
        (int(0.41 * w), int(0.68 * w)),
        (int(0.48 * w), int(0.40 * w)),
        (int(0.56 * w), int(0.66 * w)),
        (int(0.63 * w), int(0.52 * w)),
        (int(0.72 * w), int(0.52 * w)),
        (int(0.79 * w), int(0.34 * w)),
        (int(0.85 * w), int(0.34 * w)),
    ]
    _gold_line(gd, pts, int(0.042 * w))
    glow = glow.filter(ImageFilter.GaussianBlur(int(0.030 * w)))
    alpha = glow.getchannel("A").point(lambda v: int(v * 0.38))
    glow.putalpha(alpha)
    canvas.alpha_composite(glow)

    # الخط الأساسي
    line = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    ld = ImageDraw.Draw(line)
    _gold_line(ld, pts, int(0.036 * w))
    canvas.alpha_composite(line)

    # نقطة النهاية + شرارات
    dot = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dot)
    ex, ey = pts[-1]
    r = int(0.028 * w)
    dd.ellipse([ex - r, ey - r, ex + r, ey + r], fill=(246, 231, 180, 255))
    for (fx, fy, fr) in [(0.22, 0.34, 0.012), (0.70, 0.28, 0.009), (0.46, 0.24, 0.007)]:
        rr = int(fr * w)
        dd.ellipse(
            [int(fx * w) - rr, int(fy * w) - rr, int(fx * w) + rr, int(fy * w) + rr],
            fill=(233, 196, 106, 120),
        )
    canvas.alpha_composite(dot)

    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


def save_all(logo: Image.Image) -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    logo.save(ASSETS / "logo.png")

    # أيقونات أندرويد
    android = APP / "android" / "app" / "src" / "main" / "res"
    for folder, px in {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }.items():
        out = android / folder / "ic_launcher.png"
        if out.parent.exists():
            logo.resize((px, px), Image.LANCZOS).save(out)

    # أيقونات iOS
    ios_dir = APP / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    contents = ios_dir / "Contents.json"
    if contents.exists():
        data = json.loads(contents.read_text(encoding="utf-8"))
        for image in data.get("images", []):
            filename = image.get("filename")
            size = image.get("size")
            scale = image.get("scale", "1x")
            if not filename or not size:
                continue
            base = float(size.split("x")[0])
            px = int(round(base * int(scale.rstrip("x"))))
            logo.resize((px, px), Image.LANCZOS).save(ios_dir / filename)

    # الويب
    icons = APP / "web" / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    for name, px in {
        "Icon-192.png": 192,
        "Icon-512.png": 512,
        "Icon-maskable-192.png": 192,
        "Icon-maskable-512.png": 512,
    }.items():
        logo.resize((px, px), Image.LANCZOS).save(icons / name)
    logo.resize((32, 32), Image.LANCZOS).save(APP / "web" / "favicon.png")

    # ويندوز
    ico = APP / "windows" / "runner" / "resources" / "app_icon.ico"
    if ico.parent.exists():
        logo.save(ico, sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])


def main() -> None:
    logo = make_logo()
    save_all(logo)
    print(f"logo written to {ASSETS / 'logo.png'}")


if __name__ == "__main__":
    main()
