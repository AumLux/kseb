// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AumLux';

  @override
  String get appTagline => 'Field operations for KSEB works';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonClose => 'Close';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonSomethingWrong => 'Something went wrong';

  @override
  String get commonComingSoonTitle => 'On its way';

  @override
  String get commonComingSoonBody =>
      'This part of the app is being rebuilt and will be available in an upcoming update.';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Use your employee ID or work email.';

  @override
  String get loginIdentifierLabel => 'Employee ID or email';

  @override
  String get loginIdentifierHint => 'e.g. AUM0123';

  @override
  String get loginIdentifierRequired => 'Enter your employee ID or email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordRequired => 'Enter your password';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String loginCooldown(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s.';
  }

  @override
  String get loginForgot => 'Forgot password?';

  @override
  String get loginForgotTitle => 'Reset your password';

  @override
  String get loginForgotBody =>
      'For security, passwords are reset by your supervisor or manager. Ask them to reset it from Staff › your name › Reset password. You\'ll get a temporary password to sign in with.';

  @override
  String get loginInactive =>
      'Your account is not active. Contact your supervisor.';

  @override
  String get loginNoProfile =>
      'Your account isn\'t set up yet. Contact your manager.';

  @override
  String get loginIdleSignedOut =>
      'You were signed out after a period of inactivity.';

  @override
  String get changePasswordTitle => 'Set a new password';

  @override
  String get changePasswordSubtitle =>
      'Choose a password only you know. You\'ll use it from now on.';

  @override
  String get changePasswordNew => 'New password';

  @override
  String get changePasswordConfirm => 'Confirm new password';

  @override
  String get changePasswordRuleLength => 'At least 8 characters';

  @override
  String get changePasswordRuleMix => 'Letters and numbers';

  @override
  String get changePasswordMismatch => 'Passwords don\'t match';

  @override
  String get changePasswordSubmit => 'Save password';

  @override
  String get changePasswordDone => 'Password updated';

  @override
  String get navHome => 'Home';

  @override
  String get navAttendance => 'Attendance';

  @override
  String get navWork => 'Work';

  @override
  String get navMore => 'More';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeTodayTitle => 'Today';

  @override
  String get homeNotCheckedIn => 'Not checked in yet';

  @override
  String homeCheckedInAt(String time) {
    return 'Checked in at $time';
  }

  @override
  String homeCheckedOutAt(String time) {
    return 'Checked out at $time';
  }

  @override
  String get homeOverview => 'Overview';

  @override
  String get kpiPresentThisMonth => 'Present this month';

  @override
  String get kpiPendingApprovals => 'Waiting for you';

  @override
  String get kpiTeamPresentToday => 'Team present today';

  @override
  String get kpiWorkInProgress => 'Work in progress';

  @override
  String get kpiOpenIncidents => 'Open incidents';

  @override
  String get kpiLowStock => 'Low-stock items';

  @override
  String get kpiActiveWorkOrders => 'Active work orders';

  @override
  String get kpiOpenTenders => 'Open tenders';

  @override
  String get kpiDepositsHeld => 'Deposits held';

  @override
  String get kpiDepositsExpiring => 'Deposits expiring (30 days)';

  @override
  String get kpiReceivables => 'Receivables outstanding';

  @override
  String get kpiReceivables90 => 'Overdue > 90 days';

  @override
  String get kpiUnreadNotifications => 'Unread notifications';

  @override
  String get homeLoadFailed => 'Couldn\'t load your dashboard';

  @override
  String get moreTitle => 'More';

  @override
  String get moreProfile => 'My profile';

  @override
  String get moreSyncQueue => 'Sync queue';

  @override
  String get moreSyncQueueEmpty => 'Everything is synced';

  @override
  String get moreLanguage => 'Language';

  @override
  String get moreChangePassword => 'Change password';

  @override
  String get moreAbout => 'About & licences';

  @override
  String get moreSignOut => 'Sign out';

  @override
  String get moreSignOutConfirmTitle => 'Sign out?';

  @override
  String get moreSignOutConfirmBody =>
      'You\'ll need your employee ID or email and password to sign in again.';

  @override
  String moreSignOutPendingBody(int count) {
    return '$count items haven\'t synced yet. They stay on this phone and upload after you sign in again with the same account.';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalayalam => 'മലയാളം';

  @override
  String get syncTitle => 'Sync queue';

  @override
  String get syncPending => 'Waiting to sync';

  @override
  String get syncFailed => 'Couldn\'t sync';

  @override
  String get syncRetry => 'Retry';

  @override
  String get syncDiscard => 'Discard';

  @override
  String get syncDiscardConfirm =>
      'Discard this item? It will not be uploaded.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get offlineBanner =>
      'You\'re offline. Changes will sync when you\'re back online.';

  @override
  String pendingSync(int count) {
    return '$count pending';
  }

  @override
  String get roleStaff => 'Staff';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleCoo => 'COO';

  @override
  String get roleDirector => 'Director';

  @override
  String get errorNetwork =>
      'No connection. Check your mobile data or Wi-Fi and try again.';

  @override
  String get errorForbidden => 'You don\'t have permission to do that.';

  @override
  String get errorSessionExpired => 'Your session expired. Sign in again.';

  @override
  String get errorInvalidCredentials =>
      'Wrong employee ID / email or password.';

  @override
  String get errorWeakPassword =>
      'Use at least 8 characters with letters and numbers.';

  @override
  String get errorSamePassword =>
      'Choose a password different from the current one.';
}
