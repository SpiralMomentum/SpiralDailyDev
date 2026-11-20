import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/model_pack.dart';

/// 최초 모델 다운로드 전까지 앱을 막는 관문 (명세: 최초 모델 다운로드 전까지는 사용 불가).
/// 상태가 이 화면 하나에서만 쓰이므로 StatefulWidget 으로 관리한다 (presentation_convention 1단계).
class ModelGatePage extends StatefulWidget {
  const ModelGatePage({
    super.key,
    required this.checkInstalled,
    required this.download,
    required this.child,
    this.onReady,
  });

  /// 모델이 준비되면 한 번 불린다 (모델 미리 불러오기 등).
  final VoidCallback? onReady;

  final CheckModelPackUseCase checkInstalled;
  final DownloadModelPackUseCase download;
  final Widget child;

  @override
  State<ModelGatePage> createState() => _ModelGatePageState();
}

enum _GateStatus { checking, idle, downloading, failed, tooLarge, ready }

class _ModelGatePageState extends State<ModelGatePage> {
  _GateStatus _status = _GateStatus.checking;
  int? _percent;
  StreamSubscription<DownloadEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    widget.checkInstalled().then((installed) {
      if (!mounted) return;
      setState(() => _status = installed ? _GateStatus.ready : _GateStatus.idle);
      if (installed) widget.onReady?.call();
    });
  }

  void _start() {
    setState(() {
      _status = _GateStatus.downloading;
      _percent = 0;
    });
    _subscription = widget.download().listen((event) {
      if (!mounted) return;
      setState(() {
        switch (event) {
          case DownloadProgress(:final percent):
            _percent = percent;
          case DownloadCompleted():
            _status = _GateStatus.ready;
            widget.onReady?.call();
          case DownloadFailed(:final failure):
            _status = failure is ModelTooLargeFailure ? _GateStatus.tooLarge : _GateStatus.failed;
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _GateStatus.ready) return widget.child;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.download_for_offline_outlined, size: 64),
              const SizedBox(height: 20),
              Text(
                l10n.gateTitle,
                key: const Key('gate_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(l10n.gateBody, textAlign: TextAlign.center),
              const SizedBox(height: 28),
              ...switch (_status) {
                _GateStatus.checking => [const Center(child: CircularProgressIndicator())],
                _GateStatus.downloading => [
                    LinearProgressIndicator(
                      key: const Key('gate_progress'),
                      value: _percent == null ? null : _percent! / 100,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.gateDownloading(_percent ?? 0), textAlign: TextAlign.center),
                  ],
                _GateStatus.failed || _GateStatus.tooLarge => [
                    Text(
                      _status == _GateStatus.tooLarge ? l10n.gateTooLarge : l10n.gateFailed,
                      key: const Key('gate_error'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('gate_retry'),
                      onPressed: _start,
                      child: Text(l10n.gateRetry),
                    ),
                  ],
                _ => [
                    FilledButton(
                      key: const Key('gate_download'),
                      onPressed: _start,
                      child: Text(l10n.gateDownload),
                    ),
                  ],
              },
            ],
          ),
        ),
      ),
    );
  }
}
