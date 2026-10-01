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
      'For security, passwords are reset by your supervisor or manager. Ask them to reset it from More › Staff › your name › Reset password. You\'ll get a temporary password to sign in with.';

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

  @override
  String get adminSection => 'Administration';

  @override
  String get staffTitle => 'Staff';

  @override
  String get staffMyTeam => 'My team';

  @override
  String get staffSearch => 'Search name, ID or phone';

  @override
  String get staffAdd => 'Add staff';

  @override
  String get staffEmpty => 'No staff found';

  @override
  String get staffEmptyHint => 'Try a different search or filter.';

  @override
  String get staffFilterAll => 'All';

  @override
  String get statusActive => 'Active';

  @override
  String get statusSuspended => 'Suspended';

  @override
  String get statusExited => 'Exited';

  @override
  String get staffDetails => 'Details';

  @override
  String get staffEmployeeCode => 'Employee ID';

  @override
  String get staffFullName => 'Full name';

  @override
  String get staffRole => 'Role';

  @override
  String get staffSection => 'Section';

  @override
  String get staffTeam => 'Team';

  @override
  String get staffNoTeam => 'No team';

  @override
  String get staffPhone => 'Mobile number';

  @override
  String get staffEmail => 'Email (officers only)';

  @override
  String get staffEmailHelper =>
      'Leave empty for crew. They sign in with their employee ID.';

  @override
  String get staffDob => 'Date of birth';

  @override
  String get staffJoined => 'Joined';

  @override
  String get staffEdit => 'Edit details';

  @override
  String get staffResetPassword => 'Reset password';

  @override
  String staffResetConfirm(String name) {
    return 'Reset the password for $name? They will need the new temporary password to sign in.';
  }

  @override
  String get staffSuspend => 'Suspend login';

  @override
  String get staffReactivate => 'Reactivate';

  @override
  String get staffMarkExited => 'Mark as exited';

  @override
  String staffSuspendConfirm(String name) {
    return 'Suspend $name? They are signed out immediately and cannot sign in until reactivated.';
  }

  @override
  String staffExitConfirm(String name) {
    return 'Mark $name as exited? Their login is disabled; their records are kept.';
  }

  @override
  String get staffSaved => 'Saved';

  @override
  String get staffCodeInvalid => '2–32 letters, digits, - or _';

  @override
  String get staffPhoneInvalid => 'Enter a 10-digit mobile number';

  @override
  String get staffEmailInvalid => 'Enter a valid email';

  @override
  String get staffNewTitle => 'New staff member';

  @override
  String get staffEditTitle => 'Edit staff member';

  @override
  String get credentialsTitle => 'Share these sign-in details';

  @override
  String credentialsBody(String name) {
    return 'Give these to $name in person. The password is shown only once and must be changed at first sign-in.';
  }

  @override
  String get credentialsLoginId => 'Sign in with';

  @override
  String get credentialsPassword => 'Temporary password';

  @override
  String get credentialsCopy => 'Copy';

  @override
  String get credentialsCopied => 'Copied';

  @override
  String get credentialsDone => 'Done';

  @override
  String get teamsTitle => 'Teams';

  @override
  String get teamsAdd => 'Add team';

  @override
  String get teamsEmpty => 'No teams yet';

  @override
  String get teamName => 'Team name';

  @override
  String get teamSupervisor => 'Supervisor';

  @override
  String get teamNoSupervisor => 'No supervisor';

  @override
  String get teamActive => 'Active';

  @override
  String teamMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'No members',
    );
    return '$_temp0';
  }

  @override
  String get orgTitle => 'Organisation';

  @override
  String get orgCircle => 'Circle';

  @override
  String get orgDivision => 'Division';

  @override
  String get orgSubdivision => 'Sub-division';

  @override
  String get orgSectionOffice => 'Section office';

  @override
  String orgAdd(String level) {
    return 'Add $level';
  }

  @override
  String get orgCode => 'Code';

  @override
  String get orgName => 'Name';

  @override
  String get orgAddress => 'Address';

  @override
  String get orgLatitude => 'Latitude';

  @override
  String get orgLongitude => 'Longitude';

  @override
  String get orgGeofence => 'Attendance radius (metres)';

  @override
  String get orgGeofenceHelper =>
      'Check-ins farther than this from the section office are flagged.';

  @override
  String get orgCoordsInvalid =>
      'Enter both latitude and longitude, or neither';

  @override
  String get orgEmpty => 'No organisation units yet';

  @override
  String fieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get orgNoLocation => 'Location not set';
}
