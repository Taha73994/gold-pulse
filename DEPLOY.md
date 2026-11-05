# النشر على الإنترنت — نبض الذهب / Gold Pulse

الهدف: خادم يعمل **24 ساعة** على الإنترنت، يفتحه التطبيق من أي مكان في العالم
بدون شرط نفس شبكة الواي فاي.

نستخدم **Render.com** (خطة مجانية) + **Docker** (الملف جاهز في المشروع).
كل ما يلزم: حساب GitHub مجاني + حساب Render مجاني.

---

## 1) إنشاء مستودع GitHub (مرة واحدة)

1. حمّل **GitHub Desktop**: <https://desktop.github.com> وثبّته.
2. أنشئ حساب GitHub مجاني إن لم يكن لديك.
3. من GitHub Desktop: **File ← Add local repository** واختر المجلد:
   `C:\Users\tahali\Documents\Default Project\gold_pulse`
   (إن لم يظهر كمستودع، اختر **create a repository** بنفس المسار).
4. اكتب رسالة الالتزام: `Gold Pulse release` ← **Commit to main**.
5. اضغط **Publish repository**.
   - يمكنك إبقاؤه **Private** (خاص) — Render يسمح بربط المستودعات الخاصة.

> ⚠️ لا ترفع مجلد `data/` أو `build/` — يوجد `.dockerignore` و`.gitignore` لهذا الغرض.

---

## 2) النشر على Render

1. افتح <https://render.com> ← **Get Started** ← سجّل بحساب GitHub.
2. من اللوحة: **New ← Blueprint**.
3. اختر المستودع `gold-pulse` ← **Connect**.
4. سيتعرّف Render على ملف `render.yaml` تلقائياً ← اضغط **Apply**.
5. انتظر 3–6 دقائق حتى تظهر حالة **Live**.
6. انسخ الرابط العلوي، شكله:
   `https://gold-pulse-api.onrender.com`

### ضبط رمز المالك

من صفحة الخدمة: **Environment ← Add Environment Variable**

| الاسم | القيمة |
|---|---|
| `GOLD_ADMIN_PIN` | رمز سري تختاره (مثلاً `taha2026`) |

ثم **Save Changes** ← يعيد Render النشر تلقائياً.

### اختبار سريع

افتح في المتصفح:

- `https://gold-pulse-api.onrender.com/health` → يجب أن يظهر `"ok": true`
- `https://gold-pulse-api.onrender.com/docs` → واجهة الـ API

---

## 3) ربط التطبيق بالخادم السحابي

الخادم نفسه يقدّم **نسخة الويب/PWA** على الجذر، أي أن:

- `https://your-app.onrender.com/` ← تطبيق الويب الكامل (آيفون + حاسبة).
- `https://your-app.onrender.com/docs` ← واجهة الـ API.

### آيفون / حاسبة (بدون بناء)

افتح الرابط في Safari/Chrome ← **إضافة إلى الشاشة الرئيسية** ← يعمل كتطبيق.
لا تحتاج أي بناء إضافي لأن الويب يتصل بالخادم من نفس العنوان تلقائياً.

### أندرويد (APK)

بعد حصولك على الرابط، شغّل على حاسبتك:

```powershell
cd "C:\Users\tahali\Documents\Default Project\gold_pulse"
powershell -ExecutionPolicy Bypass -File tools\build_release.ps1 -Server https://gold-pulse-api.onrender.com
```

سيُنتج نسختين محدّثتين في `C:\Users\tahali\Pictures\APK`:

- `gold_pulse.apk` — تعمل من أي مكان بالعالم.
- `gold_pulse_web.zip` — للاستضافة على أي سيرفر آخر (اختياري، الخادم يقدّم الويب بنفسه).

---

## ملاحظات مهمة عن الخطة المجانية

| الموضوع | التفصيل |
|---|---|
| **السكون** | الخدمة تنام بعد 15 دقيقة بلا استخدام. أول فتح بعد النوم يستغرق ~30–50 ثانية ثم يعمل طبيعياً. |
| **القرص** | غير دائم على الخطة المجانية: أي تعديل تجريه من لوحة المالك (محلات، إعلانات، تواصل) قد يضيع عند إعادة النشر. |
| **الحل** | قبل أي تحديث للكود: خذ نسخة احتياطية ثم استرجعها (انظر أدناه). |
| **الحدود** | 750 ساعة/شهر — كافية لخدمة واحدة تعمل باستمرار. |

### نسخة احتياطية (قبل أي إعادة نشر)

```powershell
$pin = "taha2026"
$url = "https://gold-pulse-api.onrender.com"
Invoke-WebRequest "$url/api/admin/backup" -Headers @{ "X-Admin-Pin" = $pin } -OutFile "backup.json"
```

### استرجاع النسخة

```powershell
$pin = "taha2026"
$url = "https://gold-pulse-api.onrender.com"
$body = Get-Content "backup.json" -Raw
Invoke-WebRequest "$url/api/admin/restore" -Method Post -Headers @{ "X-Admin-Pin" = $pin; "Content-Type" = "application/json" } -Body $body
```

---

## بديل: قاعدة بيانات دائمة (اختياري)

إذا أردت ألا تضيع البيانات أبداً، استخدم **Neon** (PostgreSQL مجاني):

1. <https://neon.tech> ← أنشئ مشروعاً مجانياً ← انسخ `Connection string`.
2. في Render: **Environment ← Add** المتغير `DATABASE_URL` بالقيمة المنسوخة.
3. أعد النشر — سيُنشئ التطبيق الجداول تلقائياً في Neon.

> حزمة `psycopg` مثبّتة مسبقاً في صورة Docker، لا تحتاج أي تعديل.

---

## تشغيل محلي (كما هو الآن)

```bash
cd gold_pulse
python run.py          # http://0.0.0.0:8010
```

الخادم المحلي يبقى مفيداً للتجربة والتطوير، لكن التطبيق الموزّع للمستخدمين
يجب أن يشير إلى الرابط السحابي.

---

© 2026 Taha Ali — جميع الحقوق محفوظة.
