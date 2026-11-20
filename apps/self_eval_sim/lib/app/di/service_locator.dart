import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import '../../features/model_pack/data/model_pack_repository_impl.dart';
import '../../features/model_pack/domain/model_pack.dart';
import '../../features/monetization/data/monetization_impl.dart';
import '../../features/monetization/domain/monetization.dart';
import '../../features/monetization/presentation/simulated_ad_page.dart';
import '../../features/settings/data/language_preference_repository_impl.dart';
import '../../features/settings/domain/settings.dart';
import '../../features/share/data/share_impl.dart';
import '../../features/share/domain/share.dart';
import '../../features/simulation/data/datasources/accumulation_file_data_source.dart';
import '../../features/simulation/data/datasources/content_asset_data_source.dart';
import '../../features/simulation/data/engine/fallback_narration_engine.dart';
import '../../features/simulation/data/engine/flutter_gemma_client.dart';
import '../../features/simulation/data/engine/llm_narration_engine.dart';
import '../../features/simulation/data/engine/template_narration_engine.dart';
import '../../features/simulation/data/repositories/accumulation_repository_impl.dart';
import '../../features/simulation/data/story/story_repository_impl.dart';
import '../../features/simulation/domain/story/story_repository.dart';
import '../../features/simulation/domain/story/story_use_cases.dart';
import '../../features/simulation/data/repositories/content_repository_impl.dart';
import '../../features/simulation/domain/repositories/accumulation_repository.dart';
import '../../features/simulation/domain/repositories/narration_engine.dart';
import '../../features/simulation/domain/usecases/compose_result_use_case.dart';
import '../../features/simulation/domain/usecases/extend_result_use_case.dart';
import '../../features/simulation/domain/usecases/history_use_cases.dart';
import '../../features/simulation/domain/usecases/load_content_use_case.dart';
import '../../features/simulation/domain/usecases/plan_attempt_use_case.dart';
import '../../features/simulation/domain/usecases/start_attempt_use_case.dart';
import '../app_config.dart';

final GetIt sl = GetIt.instance;

/// 저장소와 유스케이스를 조립한다.
abstract final class ServiceLocator {
  static Future<void> setup(AppConfig config, GlobalKey<NavigatorState> navigatorKey) async {
    await sl.reset();
    sl
      ..registerSingleton<AppConfig>(config)
      ..registerSingleton<GlobalKey<NavigatorState>>(navigatorKey)
      // model pack
      ..registerLazySingleton<ModelPackRepository>(
        () => ModelPackRepositoryImpl(
          config.modelSpec,
          config.modelSizeProbe,
          config.modelInstaller,
        ),
      )
      ..registerFactory(() => CheckModelPackUseCase(sl()))
      ..registerFactory(
        () => DownloadModelPackUseCase(sl(), maxBytes: config.maxModelBytes),
      )
      // simulation
      ..registerLazySingleton(
        () => ContentRepositoryImpl(ContentAssetDataSource(config.bundle)),
      )
      ..registerLazySingleton<StoryRepository>(
        () => StoryRepositoryImpl(config.documentsDirectory),
      )
      ..registerLazySingleton<AccumulationRepository>(
        () => AccumulationRepositoryImpl(
          AccumulationFileDataSource(config.documentsDirectory),
        ),
      )
      ..registerLazySingleton<FlutterGemmaClient>(
        () => FlutterGemmaClient(() => config.modelInstaller.activate(config.modelSpec)),
      )
      ..registerLazySingleton<NarrationEngine>(
        () => FallbackNarrationEngine(
          LlmNarrationEngine(
            sl<FlutterGemmaClient>(),
            () => config.bundle.loadString('assets/narration/prompts.json'),
          ),
          TemplateNarrationEngine(
            () => config.bundle.loadString('assets/narration/templates.json'),
          ),
          onPrimaryFailure: (kind, f) =>
              debugPrint('NARRATION_FALLBACK $kind ${f.runtimeType} ${f.message} ${f.cause}'),
        ),
      )
      ..registerFactory(() => LoadContentUseCase(sl<ContentRepositoryImpl>()))
      ..registerFactory(() => StartAttemptUseCase(config.random))
      ..registerFactory(() => PlanAttemptUseCase(sl(), config.random, config.clock))
      ..registerFactory(() => ComposeResultUseCase(sl(), config.random))
      ..registerFactory(() => const ExtendResultUseCase())
      ..registerFactory(() => StartMeetingUseCase(sl(), config.random))
      ..registerFactory(
        () => PlanMeetingUseCase(sl(), sl(), config.random, config.clock),
      )
      ..registerFactory(() => ComposeMeetingUseCase(sl(), config.random))
      ..registerFactory(() => GetHistorySummaryUseCase(sl()))
      ..registerFactory(() => ClearHistoryUseCase(sl(), sl()))
      // monetization
      ..registerSingleton<ConnectivityRepository>(config.connectivity)
      ..registerLazySingleton<RewardedAdRepository>(
        () => SimulatedRewardedAdRepository(
          () => navigatorKey.currentState!.push(SimulatedAdPage.route(config.adDuration)),
        ),
      )
      ..registerFactory(() => DecideAdOfferUseCase(sl()))
      ..registerFactory(() => ShowRewardedAdUseCase(sl()))
      // share
      ..registerLazySingleton<ShareRepository>(
        () => ShareRepositoryImpl(config.temporaryDirectory, config.shareSink),
      )
      ..registerFactory(() => ShareAnimationUseCase(sl()))
      // settings
      ..registerLazySingleton<LanguagePreferenceRepository>(
        () => LanguagePreferenceRepositoryImpl(config.documentsDirectory),
      );
  }
}
