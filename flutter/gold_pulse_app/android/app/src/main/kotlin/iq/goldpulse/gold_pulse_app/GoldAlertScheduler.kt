package iq.goldpulse.gold_pulse_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

/**
 * جدولة الفحص الدوري في الخلفية عبر AlarmManager.
 * لا تعتمد على WorkManager/Room، لذلك لا يمكنها إسقاط التطبيق عند البدء.
 */
object GoldAlertScheduler {
    private const val ACTION = "iq.goldpulse.action.CHECK_ALERTS"
    private const val REQUEST_CODE = 7421
    private const val INTERVAL_MS = 15 * 60 * 1000L

    fun schedule(context: Context) {
        try {
            val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                ?: return
            val pending = pendingIntent(context)
            manager.cancel(pending)
            val first = System.currentTimeMillis() + 60_000L
            manager.setInexactRepeating(
                AlarmManager.RTC_WAKEUP,
                first,
                INTERVAL_MS,
                pending
            )
        } catch (_: Throwable) {
            // الإشعارات الخلفية اختيارية؛ لا تمنع فتح التطبيق.
        }
    }

    fun cancel(context: Context) {
        try {
            val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                ?: return
            manager.cancel(pendingIntent(context))
        } catch (_: Throwable) {
            // تجاهل.
        }
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, GoldAlertReceiver::class.java).setAction(ACTION)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
