import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

/// Android 네이티브 설정 채널. 채널이 없는 플랫폼에서는 무동작이다.
const MethodChannel androidChannel = MethodChannel('spend_ledger/android');

class RecentPackage extends Equatable {
  const RecentPackage({required this.package, required this.label});

  /// `{package, label}`
  factory RecentPackage.fromMap(Map<Object?, Object?> m) => RecentPackage(
    package: m['package']! as String,
    label: m['label']! as String,
  );

  final String package;
  final String label;

  @override
  List<Object?> get props => [package, label];
}

class AndroidBridge {
  const AndroidBridge({MethodChannel channel = androidChannel})
    : _channel = channel;

  final MethodChannel _channel;

  /// 네이티브 리스너가 수집할 패키지를 저장한다.
  Future<void> setAllowedPackages(List<String> packages) async {
    try {
      await _channel.invokeMethod<void>('setAllowedPackages', {
        'packages': packages,
      });
    } on MissingPluginException {
      return;
    }
  }

  Future<bool> listenerEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('listenerEnabled') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openListenerSettings() async {
    try {
      await _channel.invokeMethod<void>('openListenerSettings');
    } on MissingPluginException {
      return;
    }
  }

  Future<List<RecentPackage>> recentPackages() async {
    try {
      final list = await _channel.invokeListMethod<Object?>('recentPackages');
      return [
        for (final e in list ?? const <Object?>[])
          RecentPackage.fromMap(e! as Map<Object?, Object?>),
      ];
    } on MissingPluginException {
      return const [];
    }
  }
}
