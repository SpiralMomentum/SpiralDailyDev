import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../bloc/attempt_state.dart';
import 'channel_art.dart';

/// 결과 생성 대기 화면. 발현 시(온라인)에만 보상형 광고 제안 카드를 함께 보여 준다.
class GeneratingView extends StatelessWidget {
  const GeneratingView({
    super.key,
    required this.art,
    required this.adStatus,
    required this.onWatchAd,
    required this.onSkipAd,
  });

  final String art;
  final AdStatus adStatus;
  final VoidCallback onWatchAd;
  final VoidCallback onSkipAd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ChannelArt(art: art),
        Container(color: Colors.black.withValues(alpha: 0.55)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  l10n.generatingTitle,
                  key: const Key('generating_title'),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                if (adStatus == AdStatus.offered) ...[
                  const SizedBox(height: 32),
                  Card(
                    key: const Key('ad_offer'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(l10n.generatingAdOffer, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: const Key('skip_ad'),
                                  onPressed: onSkipAd,
                                  child: Text(l10n.generatingSkipAd),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  key: const Key('watch_ad'),
                                  onPressed: onWatchAd,
                                  child: Text(l10n.generatingWatchAd),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (adStatus == AdStatus.rewarded)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      l10n.adRewarded,
                      key: const Key('ad_rewarded'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
