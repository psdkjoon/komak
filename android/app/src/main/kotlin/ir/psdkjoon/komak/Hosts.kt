package ir.psdkjoon.komak

import android.app.Activity

object Hosts {
    private val live = mutableListOf<Activity>()

    fun claim(host: Activity) {
        live.removeAll { it.isFinishing || it.isDestroyed }
        live.filter { it !== host }.forEach { it.finish() }
        live.clear()
        live.add(host)
    }
}
