package iq.goldpulse.gold_pulse_app

import android.app.Application
import android.content.Context
import android.content.Intent
import android.os.Process
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * تطبيق مخصص يلتقط أي انهيار قبل عرض الواجهة (حتى أثناء تهيئة المكوّنات)
 * ويعرض تفاصيل الخطأ في شاشة مستقلة بدل الإغلاق الصامت.
 */
class GoldPulseApp : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        installCrashHandler(base)
    }

    private fun versionName(context: Context): String = try {
        val info = context.packageManager.getPackageInfo(context.packageName, 0)
        "${info.versionName} (${info.longVersionCode})"
    } catch (_: Throwable) {
        "?"
    }

    private fun installCrashHandler(context: Context) {
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            val report = buildReport(context, thread, error)
            try {
                context.getFileStreamPath("last_crash.txt")
                    .writeText(report, Charsets.UTF_8)
            } catch (_: Throwable) {
                // تجاهل: قد تكون مساحة التخزين ممتلئة.
            }
            try {
                context.getExternalFilesDir(null)?.let { dir ->
                    java.io.File(dir, "last_crash.txt").writeText(report, Charsets.UTF_8)
                }
            } catch (_: Throwable) {
                // تجاهل.
            }
            try {
                // شاشة في عملية منفصلة تبقى ظاهرة بعد موت عملية التطبيق.
                val intent = Intent(context, CrashReportActivity::class.java)
                    .putExtra(CrashReportActivity.EXTRA_REPORT, report.take(20000))
                    .addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    )
                context.startActivity(intent)
            } catch (_: Throwable) {
                // بعض الأجهزة تمنع فتح شاشة من معالج الانهيار؛ الملف محفوظ.
            }
            try {
                Thread.sleep(400)
            } catch (_: Throwable) {
                // تجاهل.
            }
            try {
                previous?.uncaughtException(thread, error)
            } catch (_: Throwable) {
                // تجاهل.
            }
            Process.killProcess(Process.myPid())
            kotlin.system.exitProcess(10)
        }
    }

    private fun buildReport(context: Context, thread: Thread, error: Throwable): String {
        val writer = StringWriter()
        PrintWriter(writer).use { error.printStackTrace(it) }
        val time = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
        val device = "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL} / Android ${android.os.Build.VERSION.RELEASE} (SDK ${android.os.Build.VERSION.SDK_INT})"
        return buildString {
            appendLine("Gold Pulse — تقرير خطأ")
            appendLine("الوقت: $time")
            appendLine("الجهاز: $device")
            appendLine("الإصدار: ${versionName(context)}")
            appendLine("الملف: ${thread.name}")
            appendLine()
            append(writer.toString())
        }
    }
}
