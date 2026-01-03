import 'package:flutter/material.dart';

import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';

import 'adage_controller.dart';
import 'adage_state.dart';
import 'adage_theme.dart';
import 'add_adage_page.dart';

class AdageHomePage extends StatefulWidget {
  const AdageHomePage({super.key, required this.controller});

  final AdageController controller;

  @override
  State<AdageHomePage> createState() => _AdageHomePageState();
}

class _AdageHomePageState extends State<AdageHomePage> {
  Future<void> _openCreateQuote() async {
    final draft = await Navigator.of(context).push<AdageQuoteDraft>(
      MaterialPageRoute(builder: (_) => const AddAdagePage()),
    );

    if (draft == null) {
      return;
    }

    await widget.controller.addQuote(
      body: draft.body,
      reference: draft.reference,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: _openCreateQuote,
            backgroundColor: AdageColors.accentPrimary,
            foregroundColor: AdageColors.backgroundBottom,
            child: const Icon(Icons.add_rounded),
          ),
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AdageColors.backgroundTop,
                  AdageColors.backgroundBottom,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 36,
                      ),
                      decoration: BoxDecoration(
                        color: AdageColors.card,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: AdageColors.accentPrimary.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AdageColors.accentPrimary.withOpacity(0.08),
                            offset: const Offset(0, 18),
                            blurRadius: 36,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          _AdageCard(
                            quote: state.current,
                            errorMessage: state.errorMessage,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  state.canShuffle ? widget.controller.showNextQuote : null,
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 20,
                              ),
                              label: const Text('새로운 격언 불꽃 켜기'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AdageColors.accentPrimary,
                                foregroundColor: AdageColors.backgroundTop,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdageCard extends StatelessWidget {
  const _AdageCard({required this.quote, required this.errorMessage});

  final AdageQuote? quote;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = errorMessage;

    if (quote == null) {
      return Text(
        message ?? '등록된 격언이 없습니다.',
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          fontSize: 18,
          color: AdageColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdageColors.quoteBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdageColors.accentPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: AdageColors.accentSecondary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '오늘의 격언',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AdageColors.accentSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            quote!.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 18,
              color: AdageColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            quote!.reference,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: AdageColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
