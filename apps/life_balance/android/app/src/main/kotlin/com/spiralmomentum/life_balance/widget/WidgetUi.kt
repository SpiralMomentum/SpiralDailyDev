package com.spiralmomentum.life_balance.widget

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.action.actionStartActivity
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontFamily
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.spiralmomentum.life_balance.MainActivity

internal const val SETUP_MESSAGE = "앱에서 설정을 완료하세요"

// 데이터가 없을 때(앱 설정 전) 쓰는 중립 색.
private val fallback = Palette(bg = 0xFFF5F5F5.toInt(), fg = 0xFF212121.toInt(), accent = 0xFF757575.toInt())
private val fallbackDark = Palette(bg = 0xFF212121.toInt(), fg = 0xFFEEEEEE.toInt(), accent = 0xFF9E9E9E.toInt())

/** 시스템 다크 여부에 따라 호스트가 light/dark 중 하나를 고르는 색. */
internal data class Colors(val bg: ColorProvider, val fg: ColorProvider, val accent: ColorProvider)

internal fun colorsOf(data: WidgetData?): Colors {
    val l = data?.light ?: fallback
    val d = data?.dark ?: fallbackDark
    return Colors(
        bg = ColorProvider(day = Color(l.bg), night = Color(d.bg)),
        fg = ColorProvider(day = Color(l.fg), night = Color(d.fg)),
        accent = ColorProvider(day = Color(l.accent), night = Color(d.accent)),
    )
}

/** 잔고 숫자: 시스템 산세리프(Glance는 커스텀 폰트/글꼴 기능 미지원). */
internal fun numberStyle(c: Colors, size: TextUnit) =
    TextStyle(color = c.fg, fontSize = size, fontWeight = FontWeight.Bold, fontFamily = FontFamily.SansSerif)

/** 라벨: 스토아는 세리프, 나머지는 산세리프. 작은 글자라 강조색(대비 부족) 대신 전경색. */
internal fun labelStyle(c: Colors, data: WidgetData?, size: TextUnit) =
    TextStyle(
        color = c.fg,
        fontSize = size,
        fontFamily = if (data?.isStoic == true) FontFamily.Serif else FontFamily.SansSerif,
    )

/** 배경, 모서리, 탭 → 앱 실행을 공통으로 감싼다. */
@Composable
internal fun WidgetFrame(c: Colors, content: @Composable () -> Unit) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .cornerRadius(16.dp)
            .background(c.bg)
            .padding(12.dp)
            .clickable(actionStartActivity<MainActivity>()),
        contentAlignment = Alignment.CenterStart,
        content = content,
    )
}

@Composable
internal fun SetupMessage(c: Colors, size: TextUnit) {
    Text(text = SETUP_MESSAGE, style = TextStyle(color = c.fg, fontSize = size, fontFamily = FontFamily.SansSerif))
}
