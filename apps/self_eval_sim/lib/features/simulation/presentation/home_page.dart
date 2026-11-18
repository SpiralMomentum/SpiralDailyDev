import 'package:flutter/material.dart';
import 'package:utils/utils.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/entities/catalog.dart';
import 'widgets/channel_art.dart';

/// 채널 선택 화면.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.languageCode,
    required this.loadContent,
    required this.onOpenChannel,
    required this.onOpenSettings,
  });

  final String languageCode;
  final Future<Result<LocalizedContent>> Function(String languageCode) loadContent;
  final void Function(BuildContext context, Channel channel, LocalizedContent content)
      onOpenChannel;
  final void Function(BuildContext context) onOpenSettings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Result<LocalizedContent>> _content = widget.loadContent(widget.languageCode);

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.languageCode != widget.languageCode) {
      _content = widget.loadContent(widget.languageCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            key: const Key('settings_button'),
            tooltip: l10n.homeSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => widget.onOpenSettings(context),
          ),
        ],
      ),
      body: FutureBuilder<Result<LocalizedContent>>(
        future: _content,
        builder: (context, snapshot) {
          final result = snapshot.data;
          if (result == null) return const Center(child: CircularProgressIndicator());
          return result.when(
            error: (_) => Center(child: Text(l10n.commonError, key: const Key('home_error'))),
            success: (content) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final channel in content.catalog.channels)
                  _ChannelCard(
                    key: Key('channel_${channel.id}'),
                    art: channel.art,
                    name: content.text.channelName(channel.id),
                    tagline: content.text.tagline(channel.id),
                    onTap: () => widget.onOpenChannel(context, channel, content),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    super.key,
    required this.art,
    required this.name,
    required this.tagline,
    required this.onTap,
  });

  final String art;
  final String name;
  final String tagline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ChannelArt(art: art),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tagline,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
