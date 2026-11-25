package com.spiralmomentum.life_balance.widget

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.spiralmomentum.life_balance.MainActivity
import com.spiralmomentum.life_balance.R
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.LocalDate

/**
 * 상시 알림 본문. Dart `notificationText`와 같은 규칙:
 * 보너스면 `notification.bonus_body`의 `{bonus}`, 아니면 `notification.body`의 `{balance}`를 채운다.
 * 문구가 없으면 null.
 */
fun notificationTextFor(data: WidgetData, today: LocalDate): String? {
    val entry = BalanceCalc.entryFor(data.schedule, today)
    val b = BalanceCalc.compute(data.birth, entry.maturity, today)
    val value = BalanceCalc.format(b, data.unit)
    val (key, name) = if (b.isBonus) {
        WidgetKeys.NOTIFICATION_BONUS_BODY to "bonus"
    } else {
        WidgetKeys.NOTIFICATION_BODY to "balance"
    }
    val variants = data.phrases[key].orEmpty()
    if (variants.isEmpty()) return null
    return BalanceCalc.pick(variants, today).replace("{$name}", value)
}

/**
 * 재부팅/시각 변경/자정 알람 때 Flutter 없이 상시 알림을 다시 띄운다.
 * Dart `LocalOngoingNotifier`와 같은 채널·id·제목을 써서 서로 대체한다.
 * 끄기(lb_notify == "0")는 Dart가 이미 취소했으므로 여기서는 아무것도 하지 않는다.
 */
object OngoingNotification {
    const val CHANNEL_ID = "lb_balance"
    const val CHANNEL_NAME = "인생잔고"
    const val NOTIFICATION_ID = 1

    fun post(context: Context) {
        val app = context.applicationContext
        val data = readWidgetData(HomeWidgetPlugin.getData(app)) ?: return
        if (!data.notify) return
        val manager = NotificationManagerCompat.from(app)
        if (!manager.areNotificationsEnabled()) return
        val text = notificationTextFor(data, LocalDate.now()) ?: return

        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_LOW),
        )
        val open = PendingIntent.getActivity(
            app,
            0,
            Intent(app, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(app, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(CHANNEL_NAME)
            .setContentText(text)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setShowWhen(false)
            .setContentIntent(open)
            .build()
        try {
            manager.notify(NOTIFICATION_ID, notification)
        } catch (e: SecurityException) {
            // 권한이 직전에 회수된 경우. 다음 앱 실행 때 Dart가 다시 맞춘다.
        }
    }
}
