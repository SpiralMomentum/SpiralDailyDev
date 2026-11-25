package com.spiralmomentum.life_balance.widget

import android.content.Context
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Column
import androidx.glance.text.Text
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import java.time.LocalDate

/** 소형(2x1 이상): 잔고 숫자 + 라벨. */
class SmallBalanceWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val data = readWidgetData(currentState<HomeWidgetGlanceState>().preferences)
            val c = colorsOf(data)
            WidgetFrame(c) {
                if (data == null) {
                    SetupMessage(c, 12.sp)
                } else {
                    // 렌더마다 오늘 날짜로 다시 계산한다.
                    val v = presentWidget(data, LocalDate.now())
                    Column {
                        Text(text = v.smallLabel, style = labelStyle(c, data, 12.sp, c.accent), maxLines = 1)
                        Text(text = v.value, style = numberStyle(c, 22.sp), maxLines = 1)
                    }
                }
            }
        }
    }
}

class SmallBalanceReceiver : HomeWidgetGlanceWidgetReceiver<SmallBalanceWidget>() {
    override val glanceAppWidget = SmallBalanceWidget()
}
