// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '積み重ね評価';

  @override
  String get gateTitle => '最初に一度だけ、モデルのダウンロードが必要です';

  @override
  String get gateBody => 'ダウンロード後は、インターネットなしですべての評価が使えます。';

  @override
  String get gateDownload => 'ダウンロード';

  @override
  String gateDownloading(int percent) {
    return 'ダウンロード中 $percent%';
  }

  @override
  String get gateFailed => 'ダウンロードできませんでした。接続を確認して、もう一度お試しください。';

  @override
  String get gateTooLarge => 'モデルの容量が上限を超えています。';

  @override
  String get gateRetry => '再試行';

  @override
  String get homeTitle => 'どこで評価を受けますか？';

  @override
  String get homeSettings => '設定';

  @override
  String quizProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get generatingTitle => '結果を作成中';

  @override
  String get generatingAdOffer => '待っている間に広告を見ると、シーンが長くなります';

  @override
  String get generatingWatchAd => '広告を見る';

  @override
  String get generatingSkipAd => 'このまま待つ';

  @override
  String adPlaying(int seconds) {
    return '広告再生中 · $seconds秒';
  }

  @override
  String get adRewarded => '追加シーンが開きました';

  @override
  String get adFailed => '広告を読み込めませんでした';

  @override
  String get resultTapToContinue => 'タップして続ける';

  @override
  String get resultTitleLabel => '評価';

  @override
  String get resultShare => '共有';

  @override
  String get resultAgain => 'もう一度';

  @override
  String get resultHome => '最初へ';

  @override
  String get shareMaking => '共有画像を作成中';

  @override
  String get shareFailed => '共有画像を作成できませんでした';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSystem => '端末の設定に従う';

  @override
  String get settingsHistory => '累積記録';

  @override
  String settingsHistoryCount(int attempts, int manifestations) {
    return '試行 $attempts回 · 発現 $manifestations回';
  }

  @override
  String get settingsDeleteAll => '記録をすべて削除';

  @override
  String get settingsDeleteConfirmTitle => '記録をすべて削除しますか？';

  @override
  String get settingsDeleteConfirmBody => '削除した記録は元に戻せません。';

  @override
  String get settingsDeleted => '記録をすべて削除しました';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonError => '問題が発生しました。もう一度お試しください。';
}
