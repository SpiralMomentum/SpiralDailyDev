import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/report/content_report.dart';
import '../features/model_pack/domain/model_pack.dart';
import '../features/model_pack/presentation/model_gate_page.dart';
import '../features/settings/domain/settings.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/share/domain/share.dart';
import '../features/simulation/data/engine/flutter_gemma_client.dart';
import '../features/simulation/domain/entities/catalog.dart';
import '../features/simulation/domain/usecases/history_use_cases.dart';
import '../features/simulation/domain/usecases/load_content_use_case.dart';
import '../features/simulation/presentation/attempt_page.dart';
import '../features/simulation/presentation/bloc/attempt_bloc.dart';
import '../features/simulation/presentation/flow/attempt_flow.dart';
import '../features/simulation/presentation/flow/story_flow.dart';
import '../features/simulation/presentation/home_page.dart';
import '../features/simulation/presentation/widgets/scene_recorder.dart';
import '../features/monetization/domain/monetization.dart';
import '../l10n/app_localizations.dart';
import 'di/service_locator.dart';

/// 루트 위젯. 언어 설정은 앱 전체 공용 정보이므로 전역 상태([language])로 둔다.
class SelfEvalApp extends StatelessWidget {
  const SelfEvalApp({super.key, required this.navigatorKey, required this.language});

  final GlobalKey<NavigatorState> navigatorKey;
  final ValueNotifier<String?> language;

  static final supportedLocales = [for (final c in SupportedLanguages.codes) Locale(c)];

  static Locale resolveLocale(Locale? device, Iterable<Locale> supported) =>
      Locale(SupportedLanguages.resolve(device?.languageCode));

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
        valueListenable: language,
        builder: (context, code, _) => MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5B7B)),
            useMaterial3: true,
          ),
          locale: code == null ? null : Locale(code),
          supportedLocales: supportedLocales,
          localeResolutionCallback: resolveLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ModelGatePage(
            checkInstalled: sl<CheckModelPackUseCase>(),
            download: sl<DownloadModelPackUseCase>(),
            onReady: () => unawaited(sl<FlutterGemmaClient>().warmUp().catchError((_) {})),
            child: Builder(
              builder: (context) => HomePage(
                languageCode: Localizations.localeOf(context).languageCode,
                loadContent: sl<LoadContentUseCase>().call,
                onOpenChannel: _openChannel,
                onOpenSettings: _openSettings,
              ),
            ),
          ),
        ),
      );

  static void _openChannel(BuildContext context, Channel channel, LocalizedContent content) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttemptPage(
          createBloc: () => AttemptBloc(
            // 이야기가 있는 채널(무협)은 이야기 만남으로, 나머지는 기존 채널 시행으로 들어간다.
            createFlow: AttemptFlows.select(
              channel: channel,
              content: content,
              channelFlow: () => ChannelFlow(channel, content, sl(), sl(), sl(), sl()),
              storyFlow: (world, channel) =>
                  StoryFlow(world, content, sl(), sl(), sl(), channelArt: channel.art),
            ),
            decideAdOffer: sl<DecideAdOfferUseCase>().call,
            showRewardedAd: sl<ShowRewardedAdUseCase>().call,
          ),
          shareFrames: _shareFrames,
          reportContent: openContentReportMail,
        ),
      ),
    );
  }

  static Future<bool> _shareFrames(List<CapturedFrame> frames, String caption) async {
    final result = await sl<ShareAnimationUseCase>()(
      [
        for (final f in frames)
          ShareFrame(rgba: f.rgba, width: f.width, height: f.height, durationMs: f.durationMs),
      ],
      text: caption,
    );
    return result.isSuccess;
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          language: language.value,
          onLanguageChanged: (code) {
            language.value = code;
            sl<LanguagePreferenceRepository>().save(code);
          },
          loadHistory: () async => (await sl<GetHistorySummaryUseCase>()()).dataOrNull.let(
                (s) => (attempts: s.attempts, manifestations: s.manifestations),
              ),
          clearHistory: () async => (await sl<ClearHistoryUseCase>()()).isSuccess,
        ),
      ),
    );
  }
}

extension _Let<T extends Object> on T? {
  R? let<R>(R Function(T value) f) {
    final self = this;
    return self == null ? null : f(self);
  }
}
