package ir.psdkjoon.komak

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object Reminders {
    private const val PREFS = "reminders"
    private const val KEY = "items"

    data class Reminder(
        val id: Int,
        val title: String,
        val body: String,
        val at: Long,
        val repeatMillis: Long = 0,
        val payload: String? = null,
    )

    @Synchronized
    fun add(context: Context, reminder: Reminder) {
        save(context, load(context).filter { it.id != reminder.id } + reminder)
        schedule(context, reminder)
    }

    @Synchronized
    fun remove(context: Context, id: Int) {
        save(context, load(context).filter { it.id != id })
        NotificationHelper.cancelScheduled(context, id)
    }

    @Synchronized
    fun all(context: Context): List<Reminder> = load(context)

    @Synchronized
    fun rearm(context: Context) {
        val now = System.currentTimeMillis()
        val kept = mutableListOf<Reminder>()
        for (reminder in load(context)) {
            when {
                reminder.at > now -> kept += reminder
                reminder.repeatMillis > 0 -> kept += nextAfter(reminder, now)
                else -> NotificationHelper.notify(
                    context,
                    reminder.title,
                    reminder.body,
                    NotificationHelper.CHANNEL_REMINDERS,
                    reminder.id,
                    reminder.payload,
                )
            }
        }
        save(context, kept)
        kept.forEach { schedule(context, it) }
    }

    @Synchronized
    internal fun onFired(context: Context, id: Int) {
        val reminder = load(context).firstOrNull { it.id == id } ?: return
        if (reminder.repeatMillis > 0) {
            add(context, nextAfter(reminder, System.currentTimeMillis()))
        } else {
            remove(context, id)
        }
    }

    private fun nextAfter(reminder: Reminder, now: Long): Reminder {
        val steps = (now - reminder.at) / reminder.repeatMillis + 1
        return reminder.copy(at = reminder.at + steps * reminder.repeatMillis)
    }

    private fun schedule(context: Context, reminder: Reminder) {
        NotificationHelper.scheduleAt(
            context,
            reminder.id,
            reminder.at,
            reminder.title,
            reminder.body,
            NotificationHelper.CHANNEL_REMINDERS,
            reminder.payload,
        )
    }

    private fun load(context: Context): List<Reminder> {
        val raw = prefs(context).getString(KEY, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            List(array.length()) { index ->
                val item = array.getJSONObject(index)
                Reminder(
                    id = item.getInt("id"),
                    title = item.getString("title"),
                    body = item.getString("body"),
                    at = item.getLong("at"),
                    repeatMillis = item.optLong("repeat", 0),
                    payload = if (item.isNull("payload")) null else item.optString("payload"),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun save(context: Context, items: List<Reminder>) {
        val array = JSONArray()
        for (item in items) {
            array.put(
                JSONObject()
                    .put("id", item.id)
                    .put("title", item.title)
                    .put("body", item.body)
                    .put("at", item.at)
                    .put("repeat", item.repeatMillis)
                    .put("payload", item.payload),
            )
        }
        prefs(context).edit().putString(KEY, array.toString()).commit()
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
