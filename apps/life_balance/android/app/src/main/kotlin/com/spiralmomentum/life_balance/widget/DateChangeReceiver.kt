package com.spiralmomentum.life_balance.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** 날짜/시각/시간대 변경과 부팅 시 두 위젯을 즉시 다시 그리고 자정 알람을 다시 건다. */
class DateChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in HANDLED) return
        refreshAndRearm(context)
    }

    companion object {
        val HANDLED = setOf(
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
        )
    }
}
