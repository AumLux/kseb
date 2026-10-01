import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ml.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ml'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AumLux'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Field operations for KSEB works'**
  String get appTagline;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWrong;

  /// No description provided for @commonComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'On its way'**
  String get commonComingSoonTitle;

  /// No description provided for @commonComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This part of the app is being rebuilt and will be available in an upcoming update.'**
  String get commonComingSoonBody;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your employee ID or work email.'**
  String get loginSubtitle;

  /// No description provided for @loginIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee ID or email'**
  String get loginIdentifierLabel;

  /// No description provided for @loginIdentifierHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. AUM0123'**
  String get loginIdentifierHint;

  /// No description provided for @loginIdentifierRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your employee ID or email'**
  String get loginIdentifierRequired;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordRequired;

  /// No description provided for @loginShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePassword;

  /// No description provided for @loginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSubmit;

  /// No description provided for @loginCooldown.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s.'**
  String loginCooldown(int seconds);

  /// No description provided for @loginForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgot;

  /// No description provided for @loginForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get loginForgotTitle;

  /// No description provided for @loginForgotBody.
  ///
  /// In en, this message translates to:
  /// **'For security, passwords are reset by your supervisor or manager. Ask them to reset it from More › Staff › your name › Reset password. You\'ll get a temporary password to sign in with.'**
  String get loginForgotBody;

  /// No description provided for @loginInactive.
  ///
  /// In en, this message translates to:
  /// **'Your account is not active. Contact your supervisor.'**
  String get loginInactive;

  /// No description provided for @loginNoProfile.
  ///
  /// In en, this message translates to:
  /// **'Your account isn\'t set up yet. Contact your manager.'**
  String get loginNoProfile;

  /// No description provided for @loginIdleSignedOut.
  ///
  /// In en, this message translates to:
  /// **'You were signed out after a period of inactivity.'**
  String get loginIdleSignedOut;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a password only you know. You\'ll use it from now on.'**
  String get changePasswordSubtitle;

  /// No description provided for @changePasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNew;

  /// No description provided for @changePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirm;

  /// No description provided for @changePasswordRuleLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get changePasswordRuleLength;

  /// No description provided for @changePasswordRuleMix.
  ///
  /// In en, this message translates to:
  /// **'Letters and numbers'**
  String get changePasswordRuleMix;

  /// No description provided for @changePasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get changePasswordMismatch;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get changePasswordSubmit;

  /// No description provided for @changePasswordDone.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get changePasswordDone;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get navAttendance;

  /// No description provided for @navWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get navWork;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTodayTitle;

  /// No description provided for @homeNotCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Not checked in yet'**
  String get homeNotCheckedIn;

  /// No description provided for @homeCheckedInAt.
  ///
  /// In en, this message translates to:
  /// **'Checked in at {time}'**
  String homeCheckedInAt(String time);

  /// No description provided for @homeCheckedOutAt.
  ///
  /// In en, this message translates to:
  /// **'Checked out at {time}'**
  String homeCheckedOutAt(String time);

  /// No description provided for @homeOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get homeOverview;

  /// No description provided for @kpiPresentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Present this month'**
  String get kpiPresentThisMonth;

  /// No description provided for @kpiPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get kpiPendingApprovals;

  /// No description provided for @kpiTeamPresentToday.
  ///
  /// In en, this message translates to:
  /// **'Team present today'**
  String get kpiTeamPresentToday;

  /// No description provided for @kpiWorkInProgress.
  ///
  /// In en, this message translates to:
  /// **'Work in progress'**
  String get kpiWorkInProgress;

  /// No description provided for @kpiOpenIncidents.
  ///
  /// In en, this message translates to:
  /// **'Open incidents'**
  String get kpiOpenIncidents;

  /// No description provided for @kpiLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low-stock items'**
  String get kpiLowStock;

  /// No description provided for @kpiActiveWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'Active work orders'**
  String get kpiActiveWorkOrders;

  /// No description provided for @kpiOpenTenders.
  ///
  /// In en, this message translates to:
  /// **'Open tenders'**
  String get kpiOpenTenders;

  /// No description provided for @kpiDepositsHeld.
  ///
  /// In en, this message translates to:
  /// **'Deposits held'**
  String get kpiDepositsHeld;

  /// No description provided for @kpiDepositsExpiring.
  ///
  /// In en, this message translates to:
  /// **'Deposits expiring (30 days)'**
  String get kpiDepositsExpiring;

  /// No description provided for @kpiReceivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables outstanding'**
  String get kpiReceivables;

  /// No description provided for @kpiReceivables90.
  ///
  /// In en, this message translates to:
  /// **'Overdue > 90 days'**
  String get kpiReceivables90;

  /// No description provided for @kpiUnreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unread notifications'**
  String get kpiUnreadNotifications;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your dashboard'**
  String get homeLoadFailed;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @moreProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get moreProfile;

  /// No description provided for @moreSyncQueue.
  ///
  /// In en, this message translates to:
  /// **'Sync queue'**
  String get moreSyncQueue;

  /// No description provided for @moreSyncQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Everything is synced'**
  String get moreSyncQueueEmpty;

  /// No description provided for @moreLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get moreLanguage;

  /// No description provided for @moreChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get moreChangePassword;

  /// No description provided for @moreAbout.
  ///
  /// In en, this message translates to:
  /// **'About & licences'**
  String get moreAbout;

  /// No description provided for @moreSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get moreSignOut;

  /// No description provided for @moreSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get moreSignOutConfirmTitle;

  /// No description provided for @moreSignOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need your employee ID or email and password to sign in again.'**
  String get moreSignOutConfirmBody;

  /// No description provided for @moreSignOutPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{count} items haven\'t synced yet. They stay on this phone and upload after you sign in again with the same account.'**
  String moreSignOutPendingBody(int count);

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageMalayalam.
  ///
  /// In en, this message translates to:
  /// **'മലയാളം'**
  String get languageMalayalam;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync queue'**
  String get syncTitle;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get syncPending;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync'**
  String get syncFailed;

  /// No description provided for @syncRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get syncRetry;

  /// No description provided for @syncDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get syncDiscard;

  /// No description provided for @syncDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard this item? It will not be uploaded.'**
  String get syncDiscardConfirm;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Changes will sync when you\'re back online.'**
  String get offlineBanner;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingSync(int count);

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @roleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get roleSupervisor;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleCoo.
  ///
  /// In en, this message translates to:
  /// **'COO'**
  String get roleCoo;

  /// No description provided for @roleDirector.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get roleDirector;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your mobile data or Wi-Fi and try again.'**
  String get errorNetwork;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorForbidden;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong employee ID / email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters with letters and numbers.'**
  String get errorWeakPassword;

  /// No description provided for @errorSamePassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a password different from the current one.'**
  String get errorSamePassword;

  /// No description provided for @adminSection.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get adminSection;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffTitle;

  /// No description provided for @staffMyTeam.
  ///
  /// In en, this message translates to:
  /// **'My team'**
  String get staffMyTeam;

  /// No description provided for @staffSearch.
  ///
  /// In en, this message translates to:
  /// **'Search name, ID or phone'**
  String get staffSearch;

  /// No description provided for @staffAdd.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get staffAdd;

  /// No description provided for @staffEmpty.
  ///
  /// In en, this message translates to:
  /// **'No staff found'**
  String get staffEmpty;

  /// No description provided for @staffEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter.'**
  String get staffEmptyHint;

  /// No description provided for @staffFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get staffFilterAll;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// No description provided for @statusExited.
  ///
  /// In en, this message translates to:
  /// **'Exited'**
  String get statusExited;

  /// No description provided for @staffDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get staffDetails;

  /// No description provided for @staffEmployeeCode.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get staffEmployeeCode;

  /// No description provided for @staffFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get staffFullName;

  /// No description provided for @staffRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get staffRole;

  /// No description provided for @staffSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get staffSection;

  /// No description provided for @staffTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get staffTeam;

  /// No description provided for @staffNoTeam.
  ///
  /// In en, this message translates to:
  /// **'No team'**
  String get staffNoTeam;

  /// No description provided for @staffPhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get staffPhone;

  /// No description provided for @staffEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (officers only)'**
  String get staffEmail;

  /// No description provided for @staffEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for crew. They sign in with their employee ID.'**
  String get staffEmailHelper;

  /// No description provided for @staffDob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get staffDob;

  /// No description provided for @staffJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get staffJoined;

  /// No description provided for @staffEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get staffEdit;

  /// No description provided for @staffResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get staffResetPassword;

  /// No description provided for @staffResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset the password for {name}? They will need the new temporary password to sign in.'**
  String staffResetConfirm(String name);

  /// No description provided for @staffSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend login'**
  String get staffSuspend;

  /// No description provided for @staffReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get staffReactivate;

  /// No description provided for @staffMarkExited.
  ///
  /// In en, this message translates to:
  /// **'Mark as exited'**
  String get staffMarkExited;

  /// No description provided for @staffSuspendConfirm.
  ///
  /// In en, this message translates to:
  /// **'Suspend {name}? They are signed out immediately and cannot sign in until reactivated.'**
  String staffSuspendConfirm(String name);

  /// No description provided for @staffExitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark {name} as exited? Their login is disabled; their records are kept.'**
  String staffExitConfirm(String name);

  /// No description provided for @staffSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get staffSaved;

  /// No description provided for @staffCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'2–32 letters, digits, - or _'**
  String get staffCodeInvalid;

  /// No description provided for @staffPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit mobile number'**
  String get staffPhoneInvalid;

  /// No description provided for @staffEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get staffEmailInvalid;

  /// No description provided for @staffNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New staff member'**
  String get staffNewTitle;

  /// No description provided for @staffEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit staff member'**
  String get staffEditTitle;

  /// No description provided for @credentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share these sign-in details'**
  String get credentialsTitle;

  /// No description provided for @credentialsBody.
  ///
  /// In en, this message translates to:
  /// **'Give these to {name} in person. The password is shown only once and must be changed at first sign-in.'**
  String credentialsBody(String name);

  /// No description provided for @credentialsLoginId.
  ///
  /// In en, this message translates to:
  /// **'Sign in with'**
  String get credentialsLoginId;

  /// No description provided for @credentialsPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get credentialsPassword;

  /// No description provided for @credentialsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get credentialsCopy;

  /// No description provided for @credentialsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get credentialsCopied;

  /// No description provided for @credentialsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get credentialsDone;

  /// No description provided for @teamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teamsTitle;

  /// No description provided for @teamsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add team'**
  String get teamsAdd;

  /// No description provided for @teamsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No teams yet'**
  String get teamsEmpty;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamName;

  /// No description provided for @teamSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get teamSupervisor;

  /// No description provided for @teamNoSupervisor.
  ///
  /// In en, this message translates to:
  /// **'No supervisor'**
  String get teamNoSupervisor;

  /// No description provided for @teamActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get teamActive;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members} =1{1 member} other{{count} members}}'**
  String teamMembers(int count);

  /// No description provided for @orgTitle.
  ///
  /// In en, this message translates to:
  /// **'Organisation'**
  String get orgTitle;

  /// No description provided for @orgCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get orgCircle;

  /// No description provided for @orgDivision.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get orgDivision;

  /// No description provided for @orgSubdivision.
  ///
  /// In en, this message translates to:
  /// **'Sub-division'**
  String get orgSubdivision;

  /// No description provided for @orgSectionOffice.
  ///
  /// In en, this message translates to:
  /// **'Section office'**
  String get orgSectionOffice;

  /// No description provided for @orgAdd.
  ///
  /// In en, this message translates to:
  /// **'Add {level}'**
  String orgAdd(String level);

  /// No description provided for @orgCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get orgCode;

  /// No description provided for @orgName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get orgName;

  /// No description provided for @orgAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get orgAddress;

  /// No description provided for @orgLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get orgLatitude;

  /// No description provided for @orgLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get orgLongitude;

  /// No description provided for @orgGeofence.
  ///
  /// In en, this message translates to:
  /// **'Attendance radius (metres)'**
  String get orgGeofence;

  /// No description provided for @orgGeofenceHelper.
  ///
  /// In en, this message translates to:
  /// **'Check-ins farther than this from the section office are flagged.'**
  String get orgGeofenceHelper;

  /// No description provided for @orgCoordsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter both latitude and longitude, or neither'**
  String get orgCoordsInvalid;

  /// No description provided for @orgEmpty.
  ///
  /// In en, this message translates to:
  /// **'No organisation units yet'**
  String get orgEmpty;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldRequired(String field);

  /// No description provided for @orgNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get orgNoLocation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ml'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ml':
      return AppLocalizationsMl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
