import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../settings/presentation/allowed_apps_page.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../data/android_bridge.dart';

/// Android 알림 접근 상태와 수집할 앱 설정 진입점.
class NotificationAccessPage extends StatefulWidget {
  const NotificationAccessPage({
    super.key,
    this.bridge = const AndroidBridge(),
  });

  final AndroidBridge bridge;

  @override
  State<NotificationAccessPage> createState() => _NotificationAccessPageState();
}

class _NotificationAccessPageState extends State<NotificationAccessPage>
    with WidgetsBindingObserver {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final on = await widget.bridge.listenerEnabled();
    if (mounted) setState(() => _enabled = on);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = _enabled;
    return Scaffold(
      appBar: AppBar(title: const Text('알림 수집 설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('알림 접근'),
            trailing: Text(
              enabled == null ? '확인 중' : (enabled ? '켜짐' : '꺼짐'),
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: widget.bridge.openListenerSettings,
            child: const Text('알림 접근 설정 열기'),
          ),
          const SizedBox(height: 24),
          Text(
            '삼성 휴대폰에서는 절전 기능이 이 앱을 멈추면 알림을 받지 못할 수 있어요. '
            '설정 > 배터리 > 백그라운드 사용 제한에서 이 앱을 "제한 없음"으로 두거나, '
            '절전 예외 앱에 추가해 주세요.',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('수집할 앱'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final cubit = context.read<SettingsCubit>();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: AllowedAppsPage(bridge: widget.bridge),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
