package ir.psdkjoon.komak

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.concurrent.atomic.AtomicInteger

object NotificationHelper {
    const val CHANNEL_GENERAL = "general"
    const val CHANNEL_REMINDERS = "reminders"
    const val CHANNEL_SERVICE = "service"
    const val EXTRA_PAYLOAD = "payload"

    private const val EXTRA_ID = "id"
    private const val EXTRA_TITLE = "title"
    private const val EXTRA_BODY = "body"
    private const val EXTRA_CHANNEL = "channel"

    private val nextId = AtomicInteger(1000)

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannels(
            listOf(
                NotificationChannel(
                    CHANNEL_GENERAL,
                    context.getString(R.string.notification_channel),
                    NotificationManager.IMPORTANCE_DEFAULT,
                ),
                NotificationChannel(
                    CHANNEL_REMINDERS,
                    context.getString(R.string.reminder_channel),
                    NotificationManager.IMPORTANCE_HIGH,
                ),
                NotificationChannel(
                    CHANNEL_SERVICE,
                    context.getString(R.string.service_channel),
                    NotificationManager.IMPORTANCE_LOW,
                ),
            ),
        )
    }

    fun openApp(context: Context, payload: String? = null, requestCode: Int = 0): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (payload != null) intent.putExtra(EXTRA_PAYLOAD, payload)
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    fun builder(
        context: Context,
        channel: String,
        title: String,
        body: String,
        payload: String? = null,
        requestCode: Int = 0,
    ): Notification.Builder {
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, channel)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        return builder
            .setSmallIcon(R.drawable.ic_tile)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(openApp(context, payload, requestCode))
            .setAutoCancel(true)
    }

    fun canNotify(context: Context): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return false
        return Build.VERSION.SDK_INT < 24 || manager.areNotificationsEnabled()
    }

    fun notify(
        context: Context,
        title: String,
        body: String,
        channel: String = CHANNEL_GENERAL,
        id: Int = nextId.getAndIncrement(),
        payload: String? = null,
    ): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return false
        ensureChannels(context)
        val notification = builder(context, channel, title, body, payload, id).build()
        return try {
            manager.notify(id, notification)
            true
        } catch (_: SecurityException) {
            false
        }
    }

    fun cancel(context: Context, id: Int) {
        context.getSystemService(NotificationManager::class.java)?.cancel(id)
    }

    fun scheduleAt(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        title: String,
        body: String,
        channel: String = CHANNEL_REMINDERS,
        payload: String? = null,
    ) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = alarmIntent(context, id)
            .putExtra(EXTRA_TITLE, title)
            .putExtra(EXTRA_BODY, body)
            .putExtra(EXTRA_CHANNEL, channel)
        if (payload != null) intent.putExtra(EXTRA_PAYLOAD, payload)
        val pending = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val exact = Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()
        try {
            when {
                Build.VERSION.SDK_INT >= 23 && exact ->
                    alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
                Build.VERSION.SDK_INT >= 23 ->
                    alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
                else -> alarms.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
            }
        } catch (_: SecurityException) {
            alarms.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
        }
    }

    fun cancelScheduled(context: Context, id: Int) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val pending = PendingIntent.getBroadcast(
            context,
            id,
            alarmIntent(context, id),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE,
        ) ?: return
        alarms.cancel(pending)
        pending.cancel()
    }

    internal fun fire(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_ID, 0)
        notify(
            context,
            intent.getStringExtra(EXTRA_TITLE) ?: "",
            intent.getStringExtra(EXTRA_BODY) ?: "",
            intent.getStringExtra(EXTRA_CHANNEL) ?: CHANNEL_REMINDERS,
            id,
            intent.getStringExtra(EXTRA_PAYLOAD),
        )
        Reminders.onFired(context, id)
    }

    private fun alarmIntent(context: Context, id: Int): Intent =
        Intent(context, NotificationAlarmReceiver::class.java).putExtra(EXTRA_ID, id)
}

class NotificationAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        NotificationHelper.fire(context, intent)
    }
}
