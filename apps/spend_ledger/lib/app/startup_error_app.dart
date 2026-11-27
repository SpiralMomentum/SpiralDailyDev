import 'package:flutter/material.dart';

/// 시작 준비(키·DB 열기 등)에 실패했을 때의 최소 화면.
/// 오류 메시지에 금융 정보가 섞일 수 있어 종류만 보여 준다.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '지출 위젯',
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '데이터를 열지 못했어요. 앱을 다시 실행해 주세요.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${error.runtimeType}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
