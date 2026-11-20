import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// 광고 SDK 연동 전 보상형 광고 자리. 끝까지 보면 true, 닫으면 false 로 pop 한다.
class SimulatedAdPage extends StatefulWidget {
  const SimulatedAdPage({super.key, required this.duration});

  final Duration duration;

  static Route<bool> route(Duration duration) => MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => SimulatedAdPage(duration: duration),
      );

  @override
  State<SimulatedAdPage> createState() => _SimulatedAdPageState();
}

class _SimulatedAdPageState extends State<SimulatedAdPage> {
  late int _left = widget.duration.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline, color: Colors.white54, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    l10n.adPlaying(_left.clamp(0, 999)),
                    key: const Key('ad_countdown'),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                key: const Key('ad_close'),
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
