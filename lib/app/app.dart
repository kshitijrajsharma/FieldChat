import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulaki/app/auth_gate.dart';
import 'package:hulaki/design/app_theme.dart';
import 'package:hulaki/features/settings/locale_provider.dart';
import 'package:hulaki/l10n/app_localizations.dart';

/// Application root. Holds the theme and the top-level navigation surface.
///
/// The supported languages come from whichever ARB files exist in lib/l10n, so
/// a new translation needs no change here.
class HulakiApp extends ConsumerWidget {
  const HulakiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Hulaki',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthGate(),
    );
  }
}
