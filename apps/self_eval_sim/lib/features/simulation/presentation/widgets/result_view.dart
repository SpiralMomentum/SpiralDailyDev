import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/evaluation.dart';
import 'vn_scene_view.dart';

/// 결과를 미연시처럼 한 줄씩 보여 준다. 탭하면 타자 중인 줄을 끝까지 보이고, 다시 탭하면 다음 줄로 간다.
class ResultView extends StatefulWidget {
  const ResultView({
    super.key,
    required this.result,
    required this.onShare,
    required this.onAgain,
    required this.onHome,
    this.charInterval = const Duration(milliseconds: 35),
  });

  final EvaluationResult result;
  final VoidCallback onShare;
  final VoidCallback onAgain;
  final VoidCallback onHome;
  final Duration charInterval;

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> with SingleTickerProviderStateMixin {
  int _scene = 0;
  int _line = 0;
  late final AnimationController _typing = AnimationController(vsync: this)
    ..addListener(() => setState(() {}));

  Scene get _current => widget.result.scenes[_scene];
  String get _text => _current.lines[_line];
  int get _length => _text.characters.length;
  int get _visible => (_typing.value * _length).floor();
  bool get _isTyping => _typing.isAnimating;
  bool get _atEnd =>
      _scene == widget.result.scenes.length - 1 && _line == _current.lines.length - 1;

  @override
  void initState() {
    super.initState();
    _type();
  }

  @override
  void didUpdateWidget(covariant ResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) {
      _scene = 0;
      _line = 0;
      _type();
    }
  }

  void _type() {
    _typing.duration = widget.charInterval * _length;
    _typing.forward(from: 0);
  }

  void _tap() {
    if (_isTyping) {
      _typing.value = 1;
      return;
    }
    if (_atEnd) return;
    setState(() {
      if (_line < _current.lines.length - 1) {
        _line++;
      } else {
        _scene++;
        _line = 0;
      }
      _type();
    });
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = _atEnd && !_isTyping;
    return GestureDetector(
      key: const Key('result_tap_area'),
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: VnSceneView(
        scene: _current,
        line: _text,
        visibleChars: _visible,
        titleLabel: l10n.resultTitleLabel,
        title: widget.result.title,
        footer: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: done
              ? Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('share_button'),
                        onPressed: widget.onShare,
                        icon: const Icon(Icons.ios_share),
                        label: Text(l10n.resultShare),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        key: const Key('again_button'),
                        onPressed: widget.onAgain,
                        child: Text(l10n.resultAgain),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('home_button'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        onPressed: widget.onHome,
                        child: Text(l10n.resultHome),
                      ),
                    ),
                  ],
                )
              : Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${l10n.resultTapToContinue}  ${_sceneProgress()}',
                    key: const Key('tap_hint'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
        ),
      ),
    );
  }

  String _sceneProgress() {
    final total = widget.result.scenes.fold<int>(0, (n, s) => n + s.lines.length);
    final before = widget.result.scenes.take(_scene).fold<int>(0, (n, s) => n + s.lines.length);
    return '${before + _line + 1}/$total';
  }
}
