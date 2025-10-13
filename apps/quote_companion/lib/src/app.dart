import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/l10n/app_localizations.dart';
import 'presentation/pages/quote_dashboard_page.dart';

/// Root widget for Quote Companion.
class QuoteCompanionApp extends StatelessWidget {
  /// Creates [QuoteCompanionApp].
  const QuoteCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quote Companion',
      locale: const Locale('ko'),
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> supportedLocales) {
        if (locale == null) {
          return const Locale('ko');
        }
        for (final Locale supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('ko');
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F5DE2),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F5DE2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.white,
          inactiveTrackColor: Colors.white.withOpacity(0.3),
          thumbColor: Colors.white,
          overlayColor: const Color(0xFF0F5DE2).withOpacity(0.12),
        ),
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const QuoteDashboardPage(),
    );
  }
}
