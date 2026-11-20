// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '누적 평가';

  @override
  String get gateTitle => '처음 한 번, 모델을 내려받아야 해요';

  @override
  String get gateBody => '내려받은 뒤에는 인터넷 없이도 모든 평가가 동작합니다.';

  @override
  String get gateDownload => '내려받기';

  @override
  String gateDownloading(int percent) {
    return '내려받는 중 $percent%';
  }

  @override
  String get gateFailed => '내려받지 못했어요. 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get gateTooLarge => '모델 용량이 허용 상한을 넘었어요.';

  @override
  String get gateRetry => '다시 시도';

  @override
  String get homeTitle => '어디에서 평가받을까요?';

  @override
  String get homeSettings => '설정';

  @override
  String quizProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get generatingTitle => '결과를 만드는 중';

  @override
  String get generatingAdOffer => '기다리는 동안 광고를 보면 장면이 더 길어져요';

  @override
  String get generatingWatchAd => '광고 보기';

  @override
  String get generatingSkipAd => '그냥 기다리기';

  @override
  String adPlaying(int seconds) {
    return '광고 재생 중 · $seconds초';
  }

  @override
  String get adRewarded => '추가 장면이 열렸어요';

  @override
  String get adFailed => '광고를 불러오지 못했어요';

  @override
  String get resultTapToContinue => '탭해서 계속';

  @override
  String get resultTitleLabel => '평가';

  @override
  String get resultShare => '공유';

  @override
  String get resultAgain => '한 번 더';

  @override
  String get resultHome => '처음으로';

  @override
  String get shareMaking => '공유 이미지를 만드는 중';

  @override
  String get shareFailed => '공유 이미지를 만들지 못했어요';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageSystem => '기기 설정 따르기';

  @override
  String get settingsHistory => '누적 기록';

  @override
  String settingsHistoryCount(int attempts, int manifestations) {
    return '시행 $attempts회 · 발현 $manifestations회';
  }

  @override
  String get settingsDeleteAll => '기록 전체 삭제';

  @override
  String get settingsDeleteConfirmTitle => '기록을 모두 지울까요?';

  @override
  String get settingsDeleteConfirmBody => '지운 기록은 되돌릴 수 없어요.';

  @override
  String get settingsDeleted => '기록을 모두 지웠어요';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonError => '문제가 생겼어요. 다시 시도해 주세요.';
}
