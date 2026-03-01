import 'package:flutter/material.dart';
import 'version_checker.dart';

class UpdateDialog {
  static Future<void> showIfNeeded(
    BuildContext context,
    VersionChecker checker,
  ) async {
    final requirement = checker.check();

    if (requirement == UpdateRequirement.none) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: requirement != UpdateRequirement.forced,
      builder: (context) => AlertDialog(
        title: Text(
          requirement == UpdateRequirement.forced ? '업데이트 필요' : '업데이트 안내',
        ),
        content: Text(
          requirement == UpdateRequirement.forced
              ? '앱을 사용하려면 최신 버전으로 업데이트해야 합니다.'
              : '새로운 버전이 출시되었습니다. 업데이트하시겠습니까?',
        ),
        actions: [
          if (requirement == UpdateRequirement.soft)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에'),
            ),
          FilledButton(
            onPressed: () {
              // In real app: launch store URL
              if (requirement != UpdateRequirement.forced) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }
}
