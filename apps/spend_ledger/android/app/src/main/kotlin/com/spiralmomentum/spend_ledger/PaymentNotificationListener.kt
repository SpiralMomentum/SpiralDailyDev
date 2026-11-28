package com.spiralmomentum.spend_ledger

import android.app.Notification
import android.app.Person
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.os.Parcelable
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * 허용한 앱의 알림에서 원문을 뽑아 [IngestEngineHost]로 넘긴다.
 * 모든 알림의 패키지 이름은 최근 앱 목록(설정 화면의 후보)에 남긴다. 원문은 로그에 남기지 않는다.
 */
class PaymentNotificationListener : NotificationListenerService() {
    private var dateReceiver: BroadcastReceiver? = null

    override fun onListenerConnected() {
        super.onListenerConnected()
        if (dateReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action in REFRESH_ACTIONS) IngestEngineHost.refresh(context)
            }
        }
        val filter = IntentFilter().apply { REFRESH_ACTIONS.forEach(::addAction) }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
        dateReceiver = receiver
    }

    override fun onListenerDisconnected() {
        unregisterDateReceiver()
        super.onListenerDisconnected()
        // 시스템이 연결을 끊으면(절전 등) 다시 붙여 달라고 요청한다. 권한이 꺼져 있으면 무시된다.
        try {
            requestRebind(ComponentName(this, PaymentNotificationListener::class.java))
        } catch (t: Throwable) {
            Log.w(TAG, "requestRebind failed: ${t.javaClass.simpleName}")
        }
    }

    override fun onDestroy() {
        unregisterDateReceiver()
        IngestEngineHost.shutdown()
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            handle(sbn)
        } catch (t: Throwable) {
            // 알림 하나 때문에 서비스가 죽지 않게 한다. 예외 타입만 남긴다.
            Log.w(TAG, "notification handling failed: ${t.javaClass.simpleName}")
        }
    }

    private fun handle(sbn: StatusBarNotification) {
        val pkg = sbn.packageName ?: return
        if (pkg == packageName) return
        NativeStores.pushRecentPackage(this, pkg)
        if (!shouldHandle(pkg, NativeStores.allowedPackages(this))) return
        val message = extractMessage(toFields(sbn)) ?: return
        IngestEngineHost.submit(this, message)
    }

    private fun unregisterDateReceiver() {
        val receiver = dateReceiver ?: return
        dateReceiver = null
        try {
            unregisterReceiver(receiver)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "date receiver was not registered")
        }
    }

    companion object {
        private const val TAG = "PaymentListener"

        /** 날짜가 바뀌거나 시각·시간대가 바뀌면 위젯 요약을 다시 계산한다. */
        private val REFRESH_ACTIONS = setOf(
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
        )

        fun toFields(sbn: StatusBarNotification): NotificationFields {
            val n = sbn.notification
            val extras = n.extras ?: Bundle.EMPTY
            return NotificationFields(
                packageName = sbn.packageName,
                isGroupSummary = n.flags and Notification.FLAG_GROUP_SUMMARY != 0,
                isOngoing = n.flags and Notification.FLAG_ONGOING_EVENT != 0,
                title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString(),
                text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString(),
                bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString(),
                messages = messages(extras),
                postTimeMs = preferredTimeMs(n.`when`, sbn.postTime),
            )
        }

        /**
         * `EXTRA_MESSAGES`의 각 Bundle에서 "text", "time", "sender"(없으면 "sender_person"의 이름)를 읽는다.
         * MessagingStyle.Message.toBundle의 키라 API 26부터 같은 방식으로 읽힌다.
         */
        private fun messages(extras: Bundle): List<MessageFields> {
            val array: Array<out Parcelable> =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    extras.getParcelableArray(Notification.EXTRA_MESSAGES, Parcelable::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    extras.getParcelableArray(Notification.EXTRA_MESSAGES)
                } ?: return emptyList()
            return array.mapNotNull { (it as? Bundle)?.let(::message) }
        }

        private fun message(b: Bundle): MessageFields {
            val sender = b.getCharSequence("sender")?.toString()
                ?: senderPersonName(b)
            return MessageFields(
                text = b.getCharSequence("text")?.toString(),
                timestampMs = if (b.containsKey("time")) b.getLong("time").takeIf { it > 0 } else null,
                sender = sender,
            )
        }

        private fun senderPersonName(b: Bundle): String? {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
            val person: Person? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                b.getParcelable("sender_person", Person::class.java)
            } else {
                @Suppress("DEPRECATION")
                b.getParcelable("sender_person")
            }
            return person?.name?.toString()
        }
    }
}
