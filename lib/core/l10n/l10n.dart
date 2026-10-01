import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../errors/app_failure.dart';

export '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localised copy for common failure codes; otherwise the server's message.
String failureMessage(AppLocalizations l10n, Object error) {
  final f = AppFailure.from(error);
  return switch (f.code) {
    'network' => l10n.errorNetwork,
    'forbidden' => l10n.errorForbidden,
    'session_expired' => l10n.errorSessionExpired,
    'invalid_credentials' => l10n.errorInvalidCredentials,
    'weak_password' => l10n.errorWeakPassword,
    'same_password' => l10n.errorSamePassword,
    'not_active' => l10n.loginInactive,
    _ => f.message,
  };
}
