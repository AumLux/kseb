import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/providers.dart';

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// The chosen UI language, persisted on the device. Defaults to Malayalam
/// when the phone is set to Malayalam, English otherwise.
class LocaleController extends Notifier<Locale> {
  static const _key = 'aumlux.locale';

  @override
  Locale build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    if (saved != null) return Locale(saved);
    final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return device == 'ml' ? const Locale('ml') : const Locale('en');
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await ref.read(sharedPreferencesProvider).setString(_key, locale.languageCode);
  }
}
