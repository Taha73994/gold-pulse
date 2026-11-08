package iq.goldpulse.gold_pulse_app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "iq.goldpulse/notify"
    private val alertsChannel = "gold_pulse_alerts"
    private var player: MediaPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createAlertChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "init" -> {
                        createAlertChannel()
                        result.success(1)
                    }
                    "requestPermission" -> {
                        result.success(requestAlertPermission())
                    }
                    "playSound" -> result.success(playAlertSound())
                    "showAlert" -> {
                        val id = call.argument<Int>("id") ?: 1
                        val title = call.argument<String>("title") ?: "نبض الذهب"
                        val body = call.argument<String>("body") ?: ""
                        val severity = call.argument<String>("severity") ?: "info"
                        result.success(showAlert(id, title, body, severity))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun alertSoundUri(): Uri =
        Uri.parse("android.resource://$packageName/${R.raw.gold_alert}")

    private fun createAlertChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val existing = manager.getNotificationChannel(alertsChannel)
        if (existing != null) return
        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            alertsChannel,
            "تنبيهات نبض الذهب",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Gold Pulse gold and exchange-rate alerts"
            enableVibration(true)
            setShowBadge(true)
            setSound(alertSoundUri(), audio)
        }
        manager.createNotificationChannel(channel)
    }

    private fun requestAlertPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return true
        }
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7201)
        return true
    }

    private fun playAlertSound(): Boolean {
        return try {
            player?.release()
            val afd = resources.openRawResource(R.raw.gold_alert)
            player = MediaPlayer().apply {
                setDataSource(afd.fileDescriptor)
                prepare()
                start()
                setOnCompletionListener {
                    it.release()
                    if (player === it) player = null
                }
            }
            afd.close()
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun showAlert(id: Int, title: String, body: String, severity: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        createAlertChannel()
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("open_alerts", true)
        }
        val pending = PendingIntent.getActivity(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val accent = when (severity) {
            "high" -> 0xFFF87171.toInt()
            "medium" -> 0xFFFBBF24.toInt()
            else -> 0xFFE9C46A.toInt()
        }
        val notification = NotificationCompat.Builder(this, alertsChannel)
            .setSmallIcon(R.drawable.ic_stat_gold)
            .setLargeIcon(
                android.graphics.BitmapFactory.decodeResource(
                    resources,
                    R.drawable.notification_large
                )
            )
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setAutoCancel(true)
            .setColor(accent)
            .setContentIntent(pending)
            .build()
        return try {
            getSystemService(NotificationManager::class.java).notify(id, notification)
            true
        } catch (_: Exception) {
            false
        }
    }

    override fun onDestroy() {
        player?.release()
        player = null
        super.onDestroy()
    }
}
