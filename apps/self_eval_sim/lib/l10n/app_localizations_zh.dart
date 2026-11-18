// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '累积评价';

  @override
  String get gateTitle => '首次使用需要先下载模型';

  @override
  String get gateBody => '下载后，所有评价都能离线进行。';

  @override
  String get gateDownload => '下载';

  @override
  String gateDownloading(int percent) {
    return '正在下载 $percent%';
  }

  @override
  String get gateFailed => '下载失败。请检查网络后重试。';

  @override
  String get gateTooLarge => '模型大小超出上限。';

  @override
  String get gateRetry => '重试';

  @override
  String get homeTitle => '想在哪里接受评价？';

  @override
  String get homeSettings => '设置';

  @override
  String quizProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get generatingTitle => '正在生成结果';

  @override
  String get generatingAdOffer => '等待时看个广告，场景会更长';

  @override
  String get generatingWatchAd => '看广告';

  @override
  String get generatingSkipAd => '直接等待';

  @override
  String adPlaying(int seconds) {
    return '广告播放中 · $seconds秒';
  }

  @override
  String get adRewarded => '已解锁额外场景';

  @override
  String get adFailed => '广告加载失败';

  @override
  String get resultTapToContinue => '点击继续';

  @override
  String get resultTitleLabel => '评价';

  @override
  String get resultShare => '分享';

  @override
  String get resultAgain => '再来一次';

  @override
  String get resultHome => '回到首页';

  @override
  String get shareMaking => '正在生成分享图片';

  @override
  String get shareFailed => '分享图片生成失败';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统设置';

  @override
  String get settingsHistory => '累积记录';

  @override
  String settingsHistoryCount(int attempts, int manifestations) {
    return '尝试 $attempts 次 · 显现 $manifestations 次';
  }

  @override
  String get settingsDeleteAll => '删除全部记录';

  @override
  String get settingsDeleteConfirmTitle => '要删除全部记录吗？';

  @override
  String get settingsDeleteConfirmBody => '删除后无法恢复。';

  @override
  String get settingsDeleted => '已删除全部记录';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonError => '出了点问题，请重试。';
}
