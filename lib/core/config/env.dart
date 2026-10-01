/// Build-time environment. Select with `--dart-define=AUMLUX_ENV=production`.
///
/// Publishable keys are safe to ship in the client: every table is protected
/// by row-level security. Never put a secret / service-role key here.
enum AppEnvironment { staging, production }

abstract final class Env {
  static const String _env = String.fromEnvironment('AUMLUX_ENV', defaultValue: 'staging');

  static AppEnvironment get environment =>
      _env == 'production' ? AppEnvironment.production : AppEnvironment.staging;

  static bool get isProduction => environment == AppEnvironment.production;

  /// Overrides (e.g. a local `supabase start` stack) take precedence.
  static const String _urlOverride = String.fromEnvironment('SUPABASE_URL');
  static const String _keyOverride = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static String get supabaseUrl {
    if (_urlOverride.isNotEmpty) return _urlOverride;
    return isProduction
        ? 'https://zjgqpyiceqofubjbevtv.supabase.co'
        : 'https://dtficnziewtaplbqoofn.supabase.co';
  }

  static String get supabasePublishableKey {
    if (_keyOverride.isNotEmpty) return _keyOverride;
    return isProduction
        ? 'sb_publishable_1X82dDKVwf-keni6ovFN6w_o0P8Nrtj'
        : 'sb_publishable_xP-FAW8BjMAGpWbjhBXc6Q_guDcWn1q';
  }

  /// Crew without an email sign in with their employee code, which maps to
  /// this domain. Must match `CREW_LOGIN_DOMAIN` in the admin-users function.
  static const String crewLoginDomain = 'staff.aumlux.internal';
}
