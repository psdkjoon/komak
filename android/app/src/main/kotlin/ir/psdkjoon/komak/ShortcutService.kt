package ir.psdkjoon.komak

import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon

object ShortcutService {
    data class Item(val id: String, val shortLabel: String, val longLabel: String? = null)

    /** Points every shortcut at the launcher icon that is enabled now. */
    fun refreshIcons(context: Context) {
        val manager = manager(context) ?: return
        try {
            val icon = Icon.createWithResource(context, LauncherIcon.currentIconRes(context))
            val updated = manager.dynamicShortcuts.map {
                ShortcutInfo.Builder(context, it.id).setIcon(icon).build()
            } + manager.pinnedShortcuts.map {
                ShortcutInfo.Builder(context, it.id).setIcon(icon).build()
            }
            if (updated.isNotEmpty()) manager.updateShortcuts(updated)
        } catch (_: Exception) {
        }
    }

    fun set(context: Context, items: List<Item>): Boolean {
        val manager = manager(context) ?: return false
        val shortcuts = items.take(manager.maxShortcutCountPerActivity).map { build(context, it) }
        return try {
            manager.setDynamicShortcuts(shortcuts)
        } catch (_: Exception) {
            false
        }
    }

    fun add(context: Context, item: Item): Boolean {
        val manager = manager(context) ?: return false
        return try {
            manager.addDynamicShortcuts(listOf(build(context, item)))
            true
        } catch (_: Exception) {
            false
        }
    }

    fun remove(context: Context, ids: List<String>) {
        manager(context)?.removeDynamicShortcuts(ids)
    }

    fun clear(context: Context) {
        manager(context)?.removeAllDynamicShortcuts()
    }

    private fun manager(context: Context): ShortcutManager? =
        if (android.os.Build.VERSION.SDK_INT >= 25) {
            context.getSystemService(ShortcutManager::class.java)
        } else {
            null
        }

    private fun build(context: Context, item: Item): ShortcutInfo {
        val intent = Intent(
            Intent.ACTION_VIEW,
            DeepLinkHandler.uri("shortcut", item.id),
            context,
            MainActivity::class.java,
        )
        val builder = ShortcutInfo.Builder(context, item.id)
            .setShortLabel(item.shortLabel)
            .setIcon(Icon.createWithResource(context, LauncherIcon.currentIconRes(context)))
            .setIntent(intent)
        if (item.longLabel != null) builder.setLongLabel(item.longLabel)
        return builder.build()
    }
}
