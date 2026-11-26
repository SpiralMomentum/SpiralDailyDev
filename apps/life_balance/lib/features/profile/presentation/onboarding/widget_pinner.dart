import 'package:home_widget/home_widget.dart';

import '../../../widget_sync/data/widget_payload.dart';

/// 홈 화면 위젯 추가 요청. 플랫폼 채널 호출을 감싸 위젯 테스트에서 대체한다.
abstract interface class WidgetPinner {
  Future<bool> isSupported();
  Future<void> requestPin();
}

class HomeWidgetPinner implements WidgetPinner {
  const HomeWidgetPinner();

  @override
  Future<bool> isSupported() async {
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestPin() => HomeWidget.requestPinWidget(
    qualifiedAndroidName: WidgetKeys.smallReceiver,
  );
}
