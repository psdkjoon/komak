package ir.psdkjoon.komak

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.os.Build
import android.os.IBinder

class ForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForegroundCompat()
            stopSelf()
            return START_NOT_STICKY
        }
        NotificationHelper.ensureChannels(this)
        val notification = build(
            intent?.getStringExtra(EXTRA_TITLE) ?: getString(R.string.app_name),
            intent?.getStringExtra(EXTRA_TEXT) ?: getString(R.string.service_running),
        )
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        return START_STICKY
    }

    private fun build(title: String, text: String): Notification {
        val builder = NotificationHelper.builder(
            this,
            NotificationHelper.CHANNEL_SERVICE,
            title,
            text,
            requestCode = NOTIFICATION_ID,
        ).setOngoing(true).setAutoCancel(false)
        if (Build.VERSION.SDK_INT >= 23) {
            val stop = PendingIntent.getService(
                this,
                NOTIFICATION_ID,
                Intent(this, ForegroundService::class.java).setAction(ACTION_STOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            builder.addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, R.drawable.ic_tile),
                    getString(R.string.service_stop),
                    stop,
                ).build(),
            )
        }
        return builder.build()
    }

    @Suppress("DEPRECATION")
    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= 24) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }
    }

    companion object {
        private const val NOTIFICATION_ID = 900
        private const val ACTION_STOP = "stop"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"

        fun start(context: Context, title: String? = null, text: String? = null): Boolean {
            val intent = Intent(context, ForegroundService::class.java)
            if (title != null) intent.putExtra(EXTRA_TITLE, title)
            if (text != null) intent.putExtra(EXTRA_TEXT, text)
            return try {
                if (Build.VERSION.SDK_INT >= 26) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                true
            } catch (_: Exception) {
                false
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, ForegroundService::class.java))
        }
    }
}
