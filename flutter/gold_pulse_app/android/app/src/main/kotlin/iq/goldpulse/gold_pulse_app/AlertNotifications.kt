package iq.goldpulse.gold_pulse_app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/** إنشاء قناة التنبيهات وإظهار الإشعارات من داخل التطبيق أو من العامل الخلفي. */
object AlertNotifications {
    const val CHANNEL_ID = "gold_pulse_alerts"

    fun soundUri(context: Context): Uri =
        Uri.parse("android.resource://${context.packageName}/${R.raw.gold_alert}")

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            CHANNEL_ID,
            "تنبيهات نبض الذهب",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Gold Pulse gold and exchange-rate alerts"
            enableVibration(true)
            setShowBadge(true)
            setSound(soundUri(context), audio)
        }
        manager.createNotificationChannel(channel)
    }

    fun canNotify(context: Context): Boolean {
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return false
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    fun show(
        context: Context,
        id: Int,
        title: String,
        body: String,
        severity: String
    ): Boolean {
        if (!canNotify(context)) return false
        createChannel(context)
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("open_alerts", true)
        }
        val pending = PendingIntent.getActivity(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val accent = when (severity) {
            "high" -> 0xFFF87171.toInt()
            "medium" -> 0xFFFBBF24.toInt()
            else -> 0xFFE9C46A.toInt()
        }
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_gold)
            .setLargeIcon(
                android.graphics.BitmapFactory.decodeResource(
                    context.resources,
                    R.drawable.notification_large
                )
            )
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSound(soundUri(context))
            .setVibrate(longArrayOf(0, 350, 160, 350))
            .setAutoCancel(true)
            .setColor(accent)
            .setContentIntent(pending)
            .build()
        return try {
            NotificationManagerCompat.from(context).notify(id, notification)
            true
        } catch (_: Exception) {
            false
        }
    }
}
