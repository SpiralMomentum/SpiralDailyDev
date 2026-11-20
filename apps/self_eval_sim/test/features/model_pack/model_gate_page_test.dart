import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/model_pack/domain/model_pack.dart';
import 'package:self_eval_sim/features/model_pack/presentation/model_gate_page.dart';
import 'package:utils/utils.dart';

import '../../support/pump.dart';

class _Repo implements ModelPackRepository {
  _Repo({required this.installed});

  bool installed;
  final controller = StreamController<DownloadEvent>();

  @override
  Future<bool> isInstalled() async => installed;

  @override
  Stream<DownloadEvent> download({required int maxBytes}) => controller.stream;
}

void main() {
  Widget gate(_Repo repo) => ModelGatePage(
        checkInstalled: CheckModelPackUseCase(repo),
        download: DownloadModelPackUseCase(repo, maxBytes: 100),
        child: const Text('HOME', key: Key('home')),
      );

  testWidgets('설치되어 있으면 바로 본 화면', (tester) async {
    await tester.pumpLocalized(gate(_Repo(installed: true)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home')), findsOneWidget);
  });

  testWidgets('미설치: 내려받기 -> 진행률 -> 완료 후 본 화면', (tester) async {
    final repo = _Repo(installed: false);
    await tester.pumpLocalized(gate(repo));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home')), findsNothing);
    expect(find.text('처음 한 번, 모델을 내려받아야 해요'), findsOneWidget);
    await tester.tap(find.byKey(const Key('gate_download')));
    await tester.pump();
    repo.controller.add(const DownloadProgress(received: 40, total: 100));
    await tester.pump();
    expect(find.text('내려받는 중 40%'), findsOneWidget);
    repo.controller.add(const DownloadCompleted());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home')), findsOneWidget);
  });

  testWidgets('용량 상한 초과와 일반 실패는 다른 문구, 다시 시도 가능', (tester) async {
    final repo = _Repo(installed: false);
    await tester.pumpLocalized(gate(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gate_download')));
    await tester.pump();
    repo.controller.add(const DownloadFailed(ModelTooLargeFailure(bytes: 200, limit: 100)));
    await tester.pump();
    expect(find.text('모델 용량이 허용 상한을 넘었어요.'), findsOneWidget);
    expect(find.byKey(const Key('gate_retry')), findsOneWidget);
  });

  testWidgets('네트워크 실패 문구', (tester) async {
    final repo = _Repo(installed: false);
    await tester.pumpLocalized(gate(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gate_download')));
    await tester.pump();
    repo.controller.add(const DownloadFailed(NetworkFailure()));
    await tester.pump();
    expect(find.byKey(const Key('gate_error')), findsOneWidget);
    expect(find.byKey(const Key('gate_retry')), findsOneWidget);
  });
}
