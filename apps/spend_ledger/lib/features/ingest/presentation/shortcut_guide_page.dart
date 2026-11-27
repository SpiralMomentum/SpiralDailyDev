import 'package:flutter/material.dart';

const List<String> shortcutSteps = [
  '단축어 앱 → 자동화 → 새로운 자동화 → 메시지',
  "메시지 내용에 '원' 포함, '즉시 실행' 선택, '실행 시 알림' 끔",
  "동작에 '결제 문자 기록'(지출 위젯) 추가, 메시지 = 단축어 입력",
  '저장',
];

class ShortcutGuidePage extends StatelessWidget {
  const ShortcutGuidePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('단축어 설정 안내')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < shortcutSteps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${i + 1}) ${shortcutSteps[i]}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
      ],
    ),
  );
}
