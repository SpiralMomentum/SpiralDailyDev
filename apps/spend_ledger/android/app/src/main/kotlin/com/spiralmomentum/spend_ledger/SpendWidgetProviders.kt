package com.spiralmomentum.spend_ledger

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** 세 크기가 공유하는 그리기. 크기별로 레이아웃과 채울 항목만 다르다. */
abstract class SpendWidget(private val layout: Int) : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val t = widgetTexts(widgetData.all.mapValues { it.value as? String })
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, layout)
            fill(views, t)
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

class SmallSpendWidget : SpendWidget(R.layout.widget_small) {
    override fun fill(v: RemoteViews, t: WidgetTexts) {
        super.fill(v, t)
        v.setTextViewText(R.id.widget_as_of, t.asOf)
    }
}

class MediumSpendWidget : SpendWidget(R.layout.widget_medium) {
    override fun fill(v: RemoteViews, t: WidgetTexts) {
        super.fill(v, t)
        v.setTextViewText(R.id.widget_daily, "하루 ${t.daily}")
        v.setTextViewText(R.id.widget_as_of, t.asOf)
        setBars(v, t)
    }
}

class LargeSpendWidget : SpendWidget(R.layout.widget_large) {
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
