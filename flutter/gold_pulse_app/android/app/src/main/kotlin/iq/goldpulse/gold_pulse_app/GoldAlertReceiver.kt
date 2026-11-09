package iq.goldpulse.gold_pulse_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import kotlin.math.abs

/**
 * فحص دوري في الخلفية عبر AlarmManager (بدون WorkManager أو Room).
 * يقرأ أحدث التنبيهات وسعر السوق من الخادم ويعرض إشعاراً عند وجود جديد،
 * ويعمل حتى بعد إغلاق التطبيق أو إعادة تشغيل الهاتف.
 */
class GoldAlertReceiver : BroadcastReceiver() {

    companion object {
        private const val PREFS = "FlutterSharedPreferences"
        private const val DOUBLE_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu"
        private const val DEFAULT_BASE = "https://gold-pulse-iota.vercel.app"
        private const val TARGET_NOTIFICATION_ID = 99001
        private const val TARGET_COOLDOWN_MS = 6 * 60 * 60 * 1000L
        private const val USER_AGENT = "GoldPulse/1.2.5 Android"
    }

    override fun onReceive(context: Context, intent: Intent) {
        // goAsync يمنحنا وقتاً قصيراً لإكمال طلب الشبكة بعد انتهاء onReceive.
        val pending = goAsync()
        val appContext = context.applicationContext
        Thread {
            try {
                runChecks(appContext)
            } catch (_: Throwable) {
                // لا يجب أن يسقط التطبيق بسبب الفحص الخلفي.
            } finally {
                try {
                    pending.finish()
                } catch (_: Throwable) {
                    // تجاهل.
                }
            }
        }.start()
    }

    private fun runChecks(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean("flutter.notifications", false)) return
        if (!AlertNotifications.canNotify(context)) return
        val base = apiBase(prefs)
        val en = prefs.getString("flutter.locale", "ar") == "en"
        checkAlerts(context, prefs, base, en)
        checkTarget(context, prefs, base, en)
    }

    private fun apiBase(prefs: SharedPreferences): String {
        val saved = prefs.getString("flutter.worker_api_base", null)
            ?.trim()
            ?.trimEnd('/')
        if (saved != null && saved.startsWith("https://")) return saved
        return DEFAULT_BASE
    }

    private fun checkAlerts(
        context: Context,
        prefs: SharedPreferences,
        base: String,
        en: Boolean
    ) {
        val root = getJson("$base/api/alerts") ?: return
        val items = root.optJSONArray("items") ?: return
        var newestId = 0L
        var title = ""
        var body = ""
        var severity = "medium"
        for (i in 0 until items.length()) {
            val item = items.optJSONObject(i) ?: continue
            val id = item.optLong("id", 0L)
            if (id <= newestId) continue
            newestId = id
            title = if (en) {
                item.optString("title_en", item.optString("title", "Gold Pulse"))
            } else {
                item.optString("title", item.optString("title_en", "نبض الذهب"))
            }
            body = if (en) {
                item.optString("body_en", item.optString("body", ""))
            } else {
                item.optString("body", item.optString("body_en", ""))
            }
            severity = item.optString("severity", "medium")
        }
        if (newestId <= 0) return
        val lastId = prefs.getLong("flutter.last_alert_id", 0L)
        if (lastId == 0L) {
            // أول تشغيل: لا نزعج المستخدم بتنبيهات قديمة.
            prefs.edit().putLong("flutter.last_alert_id", newestId).apply()
            return
        }
        if (newestId <= lastId) return
        val shown = AlertNotifications.show(
            context,
            newestId.toInt(),
            title.ifBlank { if (en) "Gold Pulse alert" else "تنبيه نبض الذهب" },
            body,
            severity
        )
        if (shown) {
            prefs.edit().putLong("flutter.last_alert_id", newestId).apply()
        }
    }

    private fun checkTarget(
        context: Context,
        prefs: SharedPreferences,
        base: String,
        en: Boolean
    ) {
        val target = flutterDouble(prefs, "target_ounce_iqd")
        if (target <= 0.0) return
        val root = getJson("$base/api/market?lang=${if (en) "en" else "ar"}") ?: return
        val usdOz = root.optDouble("usd_oz", 0.0)
        val usdIqd = root.optDouble("usd_iqd", 0.0)
        if (usdOz <= 0.0 || usdIqd <= 0.0) return
        val ounceIqd = usdOz * usdIqd
        val previous = flutterDouble(prefs, "worker_last_ounce_iqd")
        val now = System.currentTimeMillis()
        val lastAlertAt = prefs.getLong("flutter.target_alert_ms", 0L)
        val near = abs(ounceIqd - target) / target <= 0.0015
        val crossed = previous > 0.0 && (
            (previous < target && ounceIqd >= target) ||
                (previous > target && ounceIqd <= target)
            )
        if ((near || crossed) && now - lastAlertAt >= TARGET_COOLDOWN_MS) {
            val title = if (en) "Target price reached" else "وصل السعر إلى هدفك"
            val body = if (en) {
                "Gold ounce is now ${formatIqd(ounceIqd)} — your target was ${formatIqd(target)}."
            } else {
                "سعر الأونصة الآن ${formatIqd(ounceIqd)} — هدفك كان ${formatIqd(target)}."
            }
            val shown = AlertNotifications.show(
                context,
                TARGET_NOTIFICATION_ID,
                title,
                body,
                "high"
            )
            if (shown) {
                prefs.edit().putLong("flutter.target_alert_ms", now).apply()
            }
        }
        prefs.edit()
            .putString("flutter.worker_last_ounce_iqd", DOUBLE_PREFIX + ounceIqd.toString())
            .apply()
    }

    private fun flutterDouble(prefs: SharedPreferences, key: String): Double {
        val raw = prefs.getString("flutter.$key", null) ?: return 0.0
        val value = if (raw.startsWith(DOUBLE_PREFIX)) {
            raw.substring(DOUBLE_PREFIX.length)
        } else {
            raw
        }
        return value.toDoubleOrNull() ?: 0.0
    }

    private fun formatIqd(value: Double): String =
        String.format(Locale.US, "%,.0f د.ع", value)

    private fun getJson(url: String): JSONObject? {
        var connection: HttpURLConnection? = null
        return try {
            connection = (URL(url).openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 6000
                readTimeout = 6000
                setRequestProperty("Accept", "application/json")
                setRequestProperty("User-Agent", USER_AGENT)
            }
            if (connection.responseCode !in 200..299) return null
            val text = connection.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
            JSONObject(text)
        } catch (_: Exception) {
            null
        } finally {
            connection?.disconnect()
        }
    }
}
