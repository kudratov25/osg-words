package com.osg.osg_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import org.json.JSONObject

/**
 * Home Screen widget showing the current vocabulary word (any target
 * language - the flag comes with the title in the payload). Android has no
 * lock-screen widget API (removed in Android 5.0) - this is the closest
 * equivalent. Mirrors ios/OsgWidgetExtension/OsgWidget.swift; both read
 * the `todays_words` JSON written by lib/notifications/widget_sync.dart.
 *
 * The payload holds the whole planned week of word slots, each with the
 * exact time its notification fires. [onUpdate] shows the latest slot
 * whose time has passed and sets an exact alarm for the next slot time,
 * which re-runs [onUpdate] - so the widget switches at the same moment as
 * each notification, for the whole week, without the app being opened.
 * Alarms are cleared on reboot, but Android updates every widget after
 * boot, which restarts the chain. The periodic `updatePeriodMillis` tick
 * is only a fallback.
 *
 * Tap-to-reveal: each word starts with only the title and a "Show meaning"
 * pill. Tapping the pill sends [ACTION_REVEAL_MEANING] (carrying the slot's
 * `at`) back to this receiver, which stores that `at` under
 * [REVEALED_AT_KEY] in the same home_widget prefs and redraws. A slot is
 * revealed iff its `at` equals the stored value, so when the alarm switches
 * to the next slot the new word is hidden again automatically - no Dart
 * involvement, nothing to reset.
 */
class OsgWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val slots = parseSlots(widgetData.getString("todays_words", null))
        val now = System.currentTimeMillis()
        val word = currentSlot(slots, now)
        val revealed = word != null && widgetData.getLong(REVEALED_AT_KEY, NOT_REVEALED) == word.at

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.osg_widget).apply {
                setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                if (word == null) {
                    setTextViewText(R.id.widget_title, context.getString(R.string.osg_widget_placeholder_title))
                    setTextViewText(R.id.widget_translation, context.getString(R.string.osg_widget_placeholder_translation))
                    setTextViewText(R.id.widget_example, "")
                    // Placeholder: subtitle visible, nothing to reveal.
                    setViewVisibility(R.id.widget_translation, View.VISIBLE)
                    setViewVisibility(R.id.widget_example, View.GONE)
                    setViewVisibility(R.id.widget_reveal_button, View.GONE)
                } else {
                    // `title` already carries the target language's flag
                    // ("🇩🇪 der Schlüssel"), set by widget_sync.dart.
                    setTextViewText(R.id.widget_title, word.title)
                    setTextViewText(R.id.widget_translation, word.translation)
                    setTextViewText(R.id.widget_example, word.example)
                    val meaning = if (revealed) View.VISIBLE else View.GONE
                    setViewVisibility(R.id.widget_translation, meaning)
                    setViewVisibility(R.id.widget_example, meaning)
                    setViewVisibility(R.id.widget_reveal_button, if (revealed) View.GONE else View.VISIBLE)
                    // The pill's own pending intent overrides the container's
                    // launch intent for taps on the pill only.
                    if (!revealed) {
                        setOnClickPendingIntent(R.id.widget_reveal_button, revealIntent(context, word.at))
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        val next = slots.firstOrNull { it.at > now }
        if (next != null) scheduleUpdateAt(context, next.at + 1000) else cancelScheduledUpdate(context)
    }

    /**
     * Handles the "Show meaning" tap; everything else (APPWIDGET_UPDATE
     * etc.) goes to the normal AppWidgetProvider dispatch. The receiver is
     * exported for the launcher, so the reveal is only honored when the
     * intent explicitly targets this component and names the slot that is
     * current right now - a stale tap (slot already switched since the
     * widget was drawn) or a forged `at` is ignored. Worst case a caller can
     * do is reveal the current word's meaning, which is what the pill does.
     */
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_REVEAL_MEANING) {
            super.onReceive(context, intent)
            return
        }
        val self = ComponentName(context, OsgWidgetProvider::class.java)
        if (intent.component != self) return
        val at = intent.getLongExtra(EXTRA_SLOT_AT, NOT_REVEALED)
        val widgetData = HomeWidgetPlugin.getData(context)
        val current = currentSlot(parseSlots(widgetData.getString("todays_words", null)), System.currentTimeMillis())
        if (current != null && current.at == at) {
            widgetData.edit().putLong(REVEALED_AT_KEY, at).apply()
        }
        // Redraw either way: a stale tap then simply shows the current slot
        // (hidden), instead of leaving an outdated word on screen.
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(self)
        if (ids.isNotEmpty()) onUpdate(context, manager, ids, widgetData)
    }

    /** Last widget removed from the home screen: stop the alarm chain. */
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelScheduledUpdate(context)
    }

    private fun scheduleUpdateAt(context: Context, triggerAt: Long) {
        val am = alarmManager(context)
        val pending = slotUpdateIntent(context)
        // RTC (not RTC_WAKEUP): no need to wake the phone to redraw a widget
        // nobody can see; it's delivered as soon as the device wakes - e.g.
        // from that slot's own notification.
        val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
        if (canExact) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC, triggerAt, pending)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC, triggerAt, pending)
        }
    }

    private fun cancelScheduledUpdate(context: Context) {
        alarmManager(context).cancel(slotUpdateIntent(context))
    }

    data class Slot(val at: Long, val title: String, val translation: String, val example: String)

    companion object {
        private const val SLOT_ALARM_REQUEST_CODE = 4201
        private const val REVEAL_REQUEST_CODE = 4202
        private const val NOT_REVEALED = -1L

        /** Broadcast sent by the "Show meaning" pill. */
        const val ACTION_REVEAL_MEANING = "com.osg.osg_app.action.REVEAL_MEANING"
        /** Long extra on [ACTION_REVEAL_MEANING]: the `at` of the slot to reveal. */
        const val EXTRA_SLOT_AT = "slot_at"
        /** home_widget pref: `at` of the slot whose meaning is revealed. */
        const val REVEALED_AT_KEY = "widget_revealed_at"
        private const val STALE_AFTER_MS = 24L * 60 * 60 * 1000

        /**
         * The slot to show at [now]: the latest one whose time has passed.
         * Before the first slot, the first one. Null if there's no data, or
         * the plan ran out more than a day ago (app not opened for a week).
         */
        internal fun currentSlot(slots: List<Slot>, now: Long): Slot? {
            if (slots.isEmpty()) return null
            val passed = slots.lastOrNull { it.at <= now } ?: return slots.first()
            val stale = passed == slots.last() && now - passed.at > STALE_AFTER_MS
            return if (stale) null else passed
        }

        /** Parses payload v2 ({"slots":[...]}); v1 ({"words":[...]}, today only) as fallback. */
        internal fun parseSlots(json: String?): List<Slot> {
            if (json == null) return emptyList()
            return try {
                val root = JSONObject(json)
                if (root.has("slots")) {
                    val arr = root.getJSONArray("slots")
                    (0 until arr.length()).map { i ->
                        val o = arr.getJSONObject(i)
                        Slot(o.getLong("at"), o.getString("title"), o.getString("translation"), o.getString("example"))
                    }.sortedBy { it.at }
                } else {
                    val arr = root.getJSONArray("words")
                    val today = Calendar.getInstance().apply {
                        set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
                        set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
                    }.timeInMillis
                    (0 until arr.length()).map { i ->
                        val o = arr.getJSONObject(i)
                        val article = if (o.isNull("article")) null else o.getString("article")
                        val german = o.getString("german")
                        Slot(
                            today + o.getInt("slotMinutes") * 60_000L,
                            if (article.isNullOrEmpty()) german else "$article $german",
                            o.getString("translation"),
                            o.getString("example"),
                        )
                    }.sortedBy { it.at }
                }
            } catch (e: Exception) {
                emptyList()
            }
        }

        private fun alarmManager(context: Context) =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        /**
         * Explicit broadcast back to this provider for the pill tap. One
         * request code for all widget instances is fine: they all show the
         * same slot, and FLAG_UPDATE_CURRENT refreshes the `at` extra.
         */
        private fun revealIntent(context: Context, at: Long): PendingIntent {
            val intent = Intent(context, OsgWidgetProvider::class.java).apply {
                action = ACTION_REVEAL_MEANING
                putExtra(EXTRA_SLOT_AT, at)
            }
            return PendingIntent.getBroadcast(
                context,
                REVEAL_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun slotUpdateIntent(context: Context): PendingIntent {
            val ids = AppWidgetManager.getInstance(context)
                .getAppWidgetIds(ComponentName(context, OsgWidgetProvider::class.java))
            val intent = Intent(context, OsgWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            return PendingIntent.getBroadcast(
                context,
                SLOT_ALARM_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
