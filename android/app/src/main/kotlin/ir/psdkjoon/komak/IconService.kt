package ir.psdkjoon.komak

import android.app.Service
import android.content.Intent
import android.os.IBinder

class IconService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_NOT_STICKY

    override fun onTaskRemoved(rootIntent: Intent?) {
        IconSwitcher.applyPending(this)
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }
}
