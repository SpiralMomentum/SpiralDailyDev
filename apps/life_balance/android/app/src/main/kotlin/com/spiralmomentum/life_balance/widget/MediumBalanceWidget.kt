package com.spiralmomentum.life_balance.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.provideContent
import androidx.glance.color.ColorProvider
import androidx.glance.currentState
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.text.Text
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import java.time.LocalDate

/** 중형(4x2): 잔고 숫자, 오늘 출금 문구(-1일 포함), 사용 비율 진행 막대. */
class MediumBalanceWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val data = readWidgetData(currentState<HomeWidgetGlanceState>().preferences)
            val c = colorsOf(data)
            WidgetFrame(c) {
                if (data == null) {
                    SetupMessage(c, 14.sp)
                } else {
                    val v = presentWidget(data, LocalDate.now())
                    Column(modifier = GlanceModifier.fillMaxWidth()) {
                        Text(text = v.mediumLabel, style = labelStyle(c, data, 14.sp, c.accent), maxLines = 1)
                        Text(text = v.value, style = numberStyle(c, 34.sp), maxLines = 1)
                        // 보너스 구간에는 더 깎일 잔고가 없으므로 출금 문구를 숨긴다.
                        if (!v.isBonus) {
                            Text(text = v.withdrawal, style = labelStyle(c, data, 13.sp), maxLines = 1)
                        }
                        Spacer(modifier = GlanceModifier.height(10.dp))
                        LinearProgressIndicator(
                            progress = v.usedRatio,
                            modifier = GlanceModifier.fillMaxWidth().height(6.dp),
                            color = c.accent,
                            backgroundColor = ColorProvider(
                                day = Color(data.light.fg).copy(alpha = 0.15f),
                                night = Color(data.dark.fg).copy(alpha = 0.15f),
                            ),
                        )
                    }
                }
            }
        }
    }
}

class MediumBalanceReceiver : HomeWidgetGlanceWidgetReceiver<MediumBalanceWidget>() {
    override val glanceAppWidget = MediumBalanceWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        MidnightAlarm.arm(context)
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        MidnightAlarm.arm(context)
    }
}
