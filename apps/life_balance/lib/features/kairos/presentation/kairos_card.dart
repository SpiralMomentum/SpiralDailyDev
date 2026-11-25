import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_config.dart';
import '../../balance/domain/calendar_date.dart';
import '../../tone/domain/phrase_keys.dart';
import '../../tone/domain/tone_table.dart';

typedef UrlOpener = Future<void> Function(Uri uri);

Future<void> openExternal(Uri uri) async {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// 외부 브라우저로 열 수 있는 http/https url만 Uri로 돌려준다. 그 외는 null.
Uri? webUriOrNull(String? url) {
  if (url == null) return null;
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) return null;
  return (uri.scheme == 'http' || uri.scheme == 'https') ? uri : null;
}

/// 카이로스 소개 카드. url이 없거나 http/https가 아니면 소개 문구만 보인다.
class KairosCard extends StatelessWidget {
  const KairosCard({
    super.key,
    required this.config,
    required this.tone,
    required this.today,
    this.opener = openExternal,
  });

  final AppConfig config;
  final ToneTable tone;
  final CalendarDate today;
  final UrlOpener opener;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = config.kairosUrl;
    final uri = webUriOrNull(url);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pickPhrase(tone, PhraseKeys.kairosIntro, today),
              style: theme.textTheme.bodyMedium,
            ),
            if (uri != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => opener(uri),
                child: Text(pickPhrase(tone, PhraseKeys.kairosCta, today)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
