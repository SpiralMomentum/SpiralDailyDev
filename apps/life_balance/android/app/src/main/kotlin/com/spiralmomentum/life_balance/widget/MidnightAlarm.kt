package com.spiralmomentum.life_balance.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.updateAll
import java.time.ZonedDateTime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * 위젯 자정 갱신 알람. DATE_CHANGED는 manifest 수신기에 전달되지 않고
 * updatePeriodMillis는 최대 30분 늦으므로, 다음 로컬 자정 + 1분에 비정확 알람을 건다.
 * 정확 알람 권한 없이 `setAndAllowWhileIdle`만 쓴다(Doze 중에는 수 분 늦을 수 있다).
 */
object MidnightAlarm {
    private const val REQUEST_CODE = 0

    /** [now] 이후 처음 오는 로컬 자정 + 1분(epoch ms). 자정이 없는 DST 전환일은 그날 첫 유효 시각 + 1분. */
    fun nextTriggerMillis(now: ZonedDateTime): Long =
        now.toLocalDate().plusDays(1).atStartOfDay(now.zone)
            .plusMinutes(1).toInstant().toEpochMilli()

    /** 같은 PendingIntent로 다시 걸면 기존 알람을 대체하므로 여러 번 호출해도 하나만 남는다. */
    fun arm(context: Context) {
        runCatching {
            val app = context.applicationContext
            val alarms = app.getSystemService(AlarmManager::class.java) ?: return
            val intent = Intent(app, MidnightAlarmReceiver::class.java)
            val pending = PendingIntent.getBroadcast(
                app,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            alarms.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                nextTriggerMillis(ZonedDateTime.now()),
                pending,
            )
        }
    }
}

/** 두 위젯을 다시 그린다. 실패해도 프로세스를 죽이지 않는다. */
internal suspend fun refreshAllWidgets(context: Context) {
    runCatching { SmallBalanceWidget().updateAll(context) }
    runCatching { MediumBalanceWidget().updateAll(context) }
}

/**
 * goAsync 안에서 위젯을 갱신하고, 상시 알림을 다시 띄우고, 다음 자정 알람을 다시 건다.
 * 부팅 직후에는 WorkManager 작업이 늦게(앱 대기 버킷에 따라 수 시간) 돌 수 있어 여기서 알림을 복구한다.
 */
internal fun BroadcastReceiver.refreshAndRearm(context: Context) {
    val pending = goAsync()
    val app = context.applicationContext
    CoroutineScope(Dispatchers.Default).launch {
        try {
            refreshAllWidgets(app)
            runCatching { OngoingNotification.post(app) }
            MidnightAlarm.arm(app)
        } finally {
            pending.finish()
        }
    }
}

class MidnightAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        refreshAndRearm(context)
    }
}
