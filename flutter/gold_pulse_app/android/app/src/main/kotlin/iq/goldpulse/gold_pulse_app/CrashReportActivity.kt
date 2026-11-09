package iq.goldpulse.gold_pulse_app

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.text.method.ScrollingMovementMethod
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

/**
 * شاشة تشخيص بسيطة تعمل في عملية منفصلة (:crash) وتعرض سبب الانهيار
 * نصياً بدل إغلاق التطبيق بصمت. مفيدة لإرسال صورة الخطأ للمطوّر.
 */
class CrashReportActivity : Activity() {
    companion object {
        const val EXTRA_REPORT = "report"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val report = intent.getStringExtra(EXTRA_REPORT) ?: readSavedReport()
            ?: "حدث خطأ غير معروف أثناء بدء التشغيل."

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(42, 80, 42, 36)
            setBackgroundColor(Color.parseColor("#0E0F13"))
        }

        val title = TextView(this).apply {
            text = "تعذّر فتح نبض الذهب"
            textSize = 21f
            setTextColor(Color.parseColor("#E9C46A"))
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        root.addView(title)

        val hint = TextView(this).apply {
            text = "هذه تفاصيل الخطأ. صوّر الشاشة وأرسلها للمطوّر لتحديد السبب."
            textSize = 12f
            setTextColor(Color.parseColor("#B9BDC7"))
            gravity = Gravity.CENTER
            setPadding(0, 14, 0, 16)
        }
        root.addView(hint)

        val scroll = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f,
            )
            setBackgroundColor(Color.parseColor("#171A21"))
        }
        val body = TextView(this).apply {
            text = report
            textSize = 11f
            setTextColor(Color.parseColor("#E6E6E6"))
            typeface = Typeface.MONOSPACE
            setPadding(24, 24, 24, 24)
            movementMethod = ScrollingMovementMethod()
            setTextIsSelectable(true)
        }
        scroll.addView(body)
        root.addView(scroll)

        val copy = Button(this).apply {
            text = "نسخ التفاصيل"
            setOnClickListener {
                try {
                    val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    clipboard.setPrimaryClip(ClipData.newPlainText("Gold Pulse crash", report))
                    Toast.makeText(this@CrashReportActivity, "تم النسخ", Toast.LENGTH_SHORT).show()
                } catch (_: Throwable) {
                    // تجاهل.
                }
            }
        }
        root.addView(copy)

        val close = Button(this).apply {
            text = "إغلاق"
            setOnClickListener { finish() }
        }
        root.addView(close)

        setContentView(root)
    }

    private fun readSavedReport(): String? = try {
        val file = java.io.File(filesDir, "last_crash.txt")
        if (file.exists()) file.readText(Charsets.UTF_8) else null
    } catch (_: Throwable) {
        null
    }
}
