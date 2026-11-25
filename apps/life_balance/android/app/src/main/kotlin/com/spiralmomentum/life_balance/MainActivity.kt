package com.spiralmomentum.life_balance

import android.os.Bundle
import com.spiralmomentum.life_balance.widget.MidnightAlarm
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 위젯이 없는 사용자도 자정에 네이티브로 상시 알림을 갱신하도록 앱 시작 때 알람을 건다.
        MidnightAlarm.arm(this)
    }
}
