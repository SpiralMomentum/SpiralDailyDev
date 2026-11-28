package com.spiralmomentum.spend_ledger

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** 세 크기가 공유하는 그리기. 크기별로 레이아웃과 채울 항목만 다르다. */
abstract class SpendWidget(
    private val layout: Int,
    /** 레이아웃에 있는 글자 뷰와 그 색 역할. */
    private val textColors: Map<Int, (WidgetPalette) -> Int>,
    private val hasBars: Boolean,
) : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = widgetData.all.mapValues { it.value as? String }
        val t = widgetTexts(data)
        val colors = widgetColors(data)
        val nightNow = context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, layout)
            fill(views, t)
            // 색 키가 없거나 깨졌으면 XML 기본색(남색 밝음)을 그대로 둔다.
            colors?.let { paint(views, it, nightNow, textColors, hasBars) }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("spendledger://home")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_pending,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("spendledger://candidates"),
                ),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    protected open fun fill(v: RemoteViews, t: WidgetTexts) {
        v.setTextViewText(R.id.widget_total, t.total)
        v.setTextViewText(R.id.widget_ratio, t.ratio)
        v.setTextViewText(R.id.widget_today, "오늘 ${t.today}")
        if (t.pending > 0) {
            v.setTextViewText(R.id.widget_pending, "확인 대기 ${t.pending}건")
            v.setViewVisibility(R.id.widget_pending, View.VISIBLE)
        } else {
            v.setViewVisibility(R.id.widget_pending, View.GONE)
        }
    }
}

private val COMMON_TEXT_COLORS: Map<Int, (WidgetPalette) -> Int> = mapOf(
    R.id.widget_label_total to { p -> p.subtle },
    R.id.widget_total to { p -> p.onSurface },
    R.id.widget_ratio to { p -> p.primary },
    R.id.widget_today to { p -> p.subtle },
    R.id.widget_as_of to { p -> p.subtle },
    R.id.widget_pending to { p -> p.warning },
)

private val MEDIUM_TEXT_COLORS = COMMON_TEXT_COLORS + mapOf(R.id.widget_daily to { p: WidgetPalette -> p.subtle })

private val LARGE_TEXT_COLORS = MEDIUM_TEXT_COLORS + mapOf(
    R.id.widget_top to { p: WidgetPalette -> p.subtle },
    R.id.widget_recent to { p: WidgetPalette -> p.subtle },
)

class SmallSpendWidget : SpendWidget(R.layout.widget_small, COMMON_TEXT_COLORS, hasBars = false) {
    override fun fill(v: RemoteViews, t: WidgetTexts) {
        super.fill(v, t)
        v.setTextViewText(R.id.widget_as_of, t.asOf)
    }
}

class MediumSpendWidget : SpendWidget(R.layout.widget_medium, MEDIUM_TEXT_COLORS, hasBars = true) {
    override fun fill(v: RemoteViews, t: WidgetTexts) {
        super.fill(v, t)
        v.setTextViewText(R.id.widget_daily, "하루 ${t.daily}")
        v.setTextViewText(R.id.widget_as_of, t.asOf)
        setBars(v, t)
    }
}

class LargeSpendWidget : SpendWidget(R.layout.widget_large, LARGE_TEXT_COLORS, hasBars = true) {
    override fun fill(v: RemoteViews, t: WidgetTexts) {
        super.fill(v, t)
        v.setTextViewText(R.id.widget_daily, "하루 ${t.daily}")
        v.setTextViewText(R.id.widget_as_of, t.asOf)
        setBars(v, t)
        v.setTextViewText(R.id.widget_top, listLines("많이 쓴 곳", t.top))
        v.setTextViewText(R.id.widget_recent, listLines("최근", t.recent))
    }
}

private fun setBars(v: RemoteViews, t: WidgetTexts) {
    v.setProgressBar(R.id.widget_spent_bar, 100, (t.ratioPercent ?: 0).coerceIn(0, 100), false)
    v.setProgressBar(R.id.widget_elapsed_bar, 100, t.elapsedPercent, false)
}

private fun listLines(title: String, items: List<String>): String =
    if (items.isEmpty()) "$title\n없음" else "$title\n" + items.joinToString("\n")

private val BAR_IDS = listOf(R.id.widget_spent_bar, R.id.widget_elapsed_bar)

/**
 * 위젯 색칠. API 31 이상이고 SYSTEM이면 밝음·어두움 두 값을 넘겨 런처가 시스템 다크 모드를 따르게 한다.
 * 그 밖에는 [pick]한 한 벌로 칠한다. API 26~30의 진행 막대는 RemoteViews로 틴트를 바꿀 수 없어 XML 기본색을 둔다.
 */
private fun paint(
    v: RemoteViews,
    c: WidgetColors,
    nightNow: Boolean,
    textColors: Map<Int, (WidgetPalette) -> Int>,
    hasBars: Boolean,
) {
    val sdk31 = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    if (sdk31 && c.mode == WidgetMode.SYSTEM) {
        v.setColorInt(R.id.widget_bg, "setColorFilter", c.light.widgetBackground, c.dark.widgetBackground)
        textColors.forEach { (id, role) -> v.setColorInt(id, "setTextColor", role(c.light), role(c.dark)) }
        if (hasBars) {
            BAR_IDS.forEach { id ->
                v.setColorStateList(
                    id,
                    "setProgressTintList",
                    ColorStateList.valueOf(c.light.primary),
                    ColorStateList.valueOf(c.dark.primary),
                )
                v.setColorStateList(
                    id,
                    "setProgressBackgroundTintList",
                    ColorStateList.valueOf(c.light.track),
                    ColorStateList.valueOf(c.dark.track),
                )
            }
        }
        return
    }
    val p = c.pick(nightNow)
    v.setInt(R.id.widget_bg, "setColorFilter", p.widgetBackground)
    textColors.forEach { (id, role) -> v.setTextColor(id, role(p)) }
    if (hasBars && sdk31) {
        BAR_IDS.forEach { id ->
            v.setColorStateList(id, "setProgressTintList", ColorStateList.valueOf(p.primary))
            v.setColorStateList(id, "setProgressBackgroundTintList", ColorStateList.valueOf(p.track))
        }
    }
}
