import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ingest/data/android_bridge.dart';
import 'settings_cubit.dart';

const Map<String, String> _knownNames = {
  'com.samsung.android.messaging': '삼성 메시지',
  'com.google.android.apps.messaging': 'Google 메시지',
};

/// 패키지 표시 이름. 문자 앱은 고정 이름, 그 밖은 최근 앱 라벨, 없으면 패키지 이름.
String packageLabel(String package, List<RecentPackage> recent) {
  final known = _knownNames[package];
  if (known != null) return known;
  for (final r in recent) {
    if (r.package == package) return r.label;
  }
  return package;
}

/// 직접 입력한 패키지 이름을 다듬어 목록에 더한다. 빈 값·중복은 무시한다.
List<String> addPackage(List<String> packages, String input) {
  final p = input.trim();
  if (p.isEmpty || packages.contains(p)) return packages;
  return [...packages, p];
}

class AllowedAppsPage extends StatefulWidget {
  const AllowedAppsPage({super.key, this.bridge = const AndroidBridge()});

  final AndroidBridge bridge;

  @override
  State<AllowedAppsPage> createState() => _AllowedAppsPageState();
}

class _AllowedAppsPageState extends State<AllowedAppsPage> {
  final TextEditingController _c = TextEditingController();
  List<RecentPackage> _recent = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await widget.bridge.recentPackages();
      if (mounted) setState(() => _recent = list);
    } catch (_) {
      // 최근 앱 목록은 보조 정보라 실패해도 직접 입력으로 추가할 수 있다.
    }
  }

  void _addManual(SettingsCubit cubit, List<String> current) {
    final next = addPackage(current, _c.text);
    _c.clear();
    if (next != current) cubit.setNotificationPackages(next);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('수집할 앱')),
    body: BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final allowed = state.settings.notificationPackages;
        final cubit = context.read<SettingsCubit>();
        final theme = Theme.of(context);
        final candidates = [
          for (final r in _recent)
            if (!allowed.contains(r.package)) r,
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (allowed.isEmpty)
              Text(
                '수집할 앱이 없어 결제 알림을 받지 않습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            for (final p in allowed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(packageLabel(p, _recent)),
                subtitle:
                    _knownNames.containsKey(p) || p == packageLabel(p, _recent)
                    ? null
                    : Text(p),
                trailing: IconButton(
                  tooltip: '삭제',
                  icon: const Icon(Icons.close),
                  onPressed: () => cubit.setNotificationPackages([
                    for (final x in allowed)
                      if (x != p) x,
                  ]),
                ),
              ),
            if (candidates.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('최근 알림을 보낸 앱', style: theme.textTheme.titleMedium),
              for (final r in candidates)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.label),
                  subtitle: Text(r.package),
                  trailing: const Icon(Icons.add),
                  onTap: () =>
                      cubit.setNotificationPackages([...allowed, r.package]),
                ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    decoration: const InputDecoration(hintText: '패키지 이름 직접 입력'),
                    onSubmitted: (_) => _addManual(cubit, allowed),
                  ),
                ),
                IconButton(
                  tooltip: '추가',
                  icon: const Icon(Icons.add),
                  onPressed: () => _addManual(cubit, allowed),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
