import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulaki/features/auth/application/auth_providers.dart';

const _localeKey = 'settings.locale';

/// The chosen interface language, persisted on the device. Null means follow
/// the system language, which is the default.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_localeKey);
    return (stored == null || stored.isEmpty) ? null : Locale(stored);
  }

  /// Passing null returns to following the system language.
  Future<void> set(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
