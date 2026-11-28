import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_cubit.dart';

/// 설정을 한 번도 읽지 못했을 때 설정 목록 대신 보여 준다.
/// 기본값을 실제 값처럼 보여 주거나 바꾼 값을 말없이 버리지 않게 한다.
class SettingsLoadError extends StatelessWidget {
  const SettingsLoadError({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('설정을 불러오지 못했어요', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<SettingsCubit>().load(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    ),
  );
}
