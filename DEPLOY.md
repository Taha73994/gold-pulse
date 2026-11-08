# النشر على الإنترنت — نبض الذهب / Gold Pulse

النظام المباشر الآن:

| الجزء | الخدمة | الرابط |
|---|---|---|
| التطبيق + الـ API | **Vercel** (خطة Hobby — مجانية، بدون بطاقة) | `https://gold-pulse-iota.vercel.app` |
| قاعدة البيانات | **Neon PostgreSQL** (خطة مجانية، Frankfurt) | — |

> سبب ترك Render: خطته المجانية تطلب إضافة بطاقة (حجز 1$ للتحقق)، وهو ما لم ترده.
> Vercel Hobby مجاني بالكامل بدون بطاقة، ولا ينام مثل Render (بدل الإقلاع البارد ~1–2 ثانية).

---

## 1) كيف يعمل المشروع

```
Flutter APK / Web  ──HTTPS──▶  Vercel (FastAPI: backend.main:app)
                                      │
                                      ▼
                              Neon PostgreSQL (DATABASE_URL)
```

- ملف `pyproject.toml` يعرّف نقطة الدخول لـ Vercel:

```toml
[tool.vercel]
entrypoint = "backend.main:app"
```

- الاعتماديات **يجب** أن تكون في `[project] dependencies` داخل `pyproject.toml`
  (Vercel لا يقرأ `requirements.txt` في نمط Python zero-config).

```toml
dependencies = [
    "fastapi==0.162.0",
    "sqlalchemy==2.1.6",
    "pydantic==2.12.5",
    "psycopg[binary]==3.2.9",
]
```

- `vercel.json` يحدّد المنطقة `fra1` و`maxDuration: 60`.

---

## 2) متغيرات البيئة على Vercel

من: **Vercel ← المشروع `gold-pulse` ← Settings ← Environment Variables**
(البيئة: Production)

| الاسم | القيمة |
|---|---|
| `GOLD_ADMIN_PIN` | `GoldPulse@2026` |
| `GOLD_DATA_DIR` | `/tmp/gold-pulse` |
| `DATABASE_URL` | رابط Neon المجمّع (pooled) |
| `GOLD_LOCAL_BUY_MARGIN_PCT` | `3` (اختياري — هامش الشراء من الزبون) |
| `GOLD_LOCAL_SELL_MARGIN_PCT` | `3` (اختياري — هامش البيع للزبون) |
| `GOLD_PARALLEL_FX_URL` | `https://iraqsm.com/data/fx.json` (اختياري — مصدر سعر السوق الموازي) |
| `GOLD_PARALLEL_FX_FALLBACK_PREMIUM_PCT` | `11.5` (اختياري — هامش احتياطي إذا تعذر المصدر) |
| `GOLD_FX_MARKET_CACHE_SECONDS` | `30` (اختياري — مدة كاش سعر السوق قبل إعادة جلبه) |
| `GOLD_RATE_ALERT_IQD` | `5` (اختياري — أقل تغيّر بالدينار يطلق تنبيه سعر الصرف) |
| `GOLD_RATE_ALERT_WINDOW_MINUTES` | `180` (اختياري — نافذة المقارنة) |
| `GOLD_RATE_ALERT_COOLDOWN_MINUTES` | `120` (اختياري — كتم التكرار) |

رابط Neon بصيغة:

```
postgresql://USER:PASSWORD@ep-xxxx-pooler.c-7.eu-central-1.aws.neon.tech/neondb?sslmode=require
```

> استخدم رابط **Pooler** (فيه `-pooler`) لأن Vercel Serverless يفتح اتصالات متعددة.
> الكود يضبط `prepare_threshold=0` و`pool_size=2` للتوافق مع PgBouncer.
> الجداول تُنشأ تلقائياً عند أول طلب (`Base.metadata.create_all`).

---

## 3) النشر / التحديث

كل `push` إلى فرع `main` في GitHub ينشر تلقائياً:

- المستودع: <https://github.com/Taha73994/gold-pulse>
- Vercel يبني وينشر خلال ~20 ثانية.

بعد أي تعديل في متغيرات البيئة يجب **Redeploy** من لوحة Vercel.

### اختبار سريع

```powershell
$base = "https://gold-pulse-iota.vercel.app"
Invoke-RestMethod "$base/health"
Invoke-RestMethod "$base/api/market"
Invoke-RestMethod "$base/api/shops"
Invoke-RestMethod "$base/api/ads"
```

يجب أن ترجع جميعها `200` و`ok: true`.

---

## 4) الصور المرفوعة (محلات/إعلانات)

الصور تُحفظ داخل جدول `media_files` في قاعدة البيانات
وتُقدَّم عبر `/api/media/{name}` — لذلك **تبقى بعد كل إعادة نشر**.

- رفع صورة: `POST /api/admin/upload` (يتطلب `X-Admin-Pin`).
- الحد الأقصى: 3 ميغابايت، صيغ JPG / PNG / WEBP / GIF.

---

## 5) نسخة احتياطية / استرجاع

```powershell
$pin  = "GoldPulse@2026"
$base = "https://gold-pulse-iota.vercel.app"

# نسخة احتياطية
Invoke-WebRequest "$base/api/admin/backup" -Headers @{ "X-Admin-Pin" = $pin } -OutFile "backup.json"

# استرجاع
$body = Get-Content "backup.json" -Raw
Invoke-WebRequest "$base/api/admin/restore" -Method Post `
  -Headers @{ "X-Admin-Pin" = $pin; "Content-Type" = "application/json" } -Body $body
```

النسخة تشمل: المحلات، الإعلانات، بيانات التواصل، والتنبيهات (بدون معرّفات `id` لتجنّب التعارض).

---

## 6) بناء APK جديد (إن غيّرت الرابط)

```powershell
cd "C:\Users\tahali\Documents\Default Project\gold_pulse\flutter\gold_pulse_app"
$env:JAVA_HOME = "C:\Android\jdk17"
$env:ANDROID_HOME = "C:\Android\sdk"
C:\src\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE=https://gold-pulse-iota.vercel.app
```

ثم انسخ الناتج إلى `C:\Users\tahali\Pictures\APK\gold_pulse.apk`:

```powershell
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" `
  "C:\Users\tahali\Pictures\APK\gold_pulse.apk" -Force
```

---

## 7) ملاحظات الخطة المجانية

| الموضوع | التفصيل |
|---|---|
| **البطاقة** | لا تُطلب في Vercel Hobby ولا في Neon Free. |
| **الاستخدام** | Vercel Hobby مخصّص للاستخدام الشخصي غير التجاري — هذا مشروع شخصي. |
| **الإقلاع البارد** | ~1–2 ثانية بعد فترة خمول (أفضل بكثير من Render). |
| **قاعدة البيانات** | Neon Free: مساحة كافية للاستخدام المنخفض، والبيانات دائمة. |
| **الحدود** | Vercel: 100 GB نقل/شهر — أكثر من كافٍ. |

---

## 8) تشغيل محلي (للتطوير)

```bash
cd gold_pulse
python run.py          # http://0.0.0.0:8010 — PIN: taha2026
```

يستخدم SQLite محلياً في `data/` عندما لا يكون `DATABASE_URL` مضبوطاً.

---

© 2026 Taha Ali — جميع الحقوق محفوظة.
