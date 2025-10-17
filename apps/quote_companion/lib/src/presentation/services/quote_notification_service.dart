import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/quote.dart';

/// Handles rendering the currently active quote as a system notification.
class QuoteNotificationService {
  QuoteNotificationService(this._notificationsPlugin);

  static const int _notificationId = 9001;
  static const String _androidChannelId = 'quote_companion_persistent_quote';
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    _androidChannelId,
    'Daily inspiration',
    description: 'Keeps the latest quote visible in the status bar.',
    importance: Importance.high,
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _initialised = false;

  /// Ensures the underlying platform integrations are ready.
  Future<void> ensureInitialized() async {
    if (_initialised) {
      return;
    }

    if (kIsWeb) {
      _initialised = true;
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_androidChannel);
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: false, sound: true);
    }

    _initialised = true;
  }

  /// Displays the provided [quote] as a persistent notification.
  Future<void> showQuote(Quote quote) async {
    await ensureInitialized();

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    final String title = quote.author.isEmpty ? 'Quote Companion' : quote.author;
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      priority: Priority.high,
      importance: Importance.high,
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.reminder,
      showWhen: false,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        '“${quote.text}”',
        contentTitle: title,
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      _notificationId,
      title,
      '“${quote.text}”',
      platformDetails,
      payload: quote.id,
    );
  }

  /// Clears the persistent notification.
  Future<void> clearQuote() async {
    if (!_initialised) {
      return;
    }
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    await _notificationsPlugin.cancel(_notificationId);
  }
}
