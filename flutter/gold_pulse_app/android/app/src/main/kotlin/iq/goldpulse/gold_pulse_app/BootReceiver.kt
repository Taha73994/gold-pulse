package iq.goldpulse.gold_pulse_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** يعيد جدولة الفحص الخلفي بعد إعادة تشغيل الهاتف أو تحديث التطبيق. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                runCatching { GoldAlertScheduler.schedule(context) }
            }
        }
    }
}
