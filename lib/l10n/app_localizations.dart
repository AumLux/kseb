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

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Your file is ready'**
  String get exportTitle;

  /// No description provided for @exportOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get exportOpen;

  /// No description provided for @exportShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get exportShare;

  /// No description provided for @exportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled.'**
  String get exportCancelled;

  /// No description provided for @exportNoApp.
  ///
  /// In en, this message translates to:
  /// **'No app found to open this file.'**
  String get exportNoApp;

  /// No description provided for @attMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get attMe;

  /// No description provided for @attTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get attTeam;

  /// No description provided for @attCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get attCheckIn;

  /// No description provided for @attCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check out'**
  String get attCheckOut;

  /// No description provided for @attCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get attCheckedIn;

  /// No description provided for @attCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out'**
  String get attCheckedOut;

  /// No description provided for @attDoneForDay.
  ///
  /// In en, this message translates to:
  /// **'Day complete'**
  String get attDoneForDay;

  /// No description provided for @attWorked.
  ///
  /// In en, this message translates to:
  /// **'Worked {duration}'**
  String attWorked(String duration);

  /// No description provided for @attLocating.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get attLocating;

  /// No description provided for @attSynced.
  ///
  /// In en, this message translates to:
  /// **'Attendance recorded'**
  String get attSynced;

  /// No description provided for @attQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved on your phone. It will sync when you\'re back online.'**
  String get attQueued;

  /// No description provided for @attPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get attPendingSync;

  /// No description provided for @attNoLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get attNoLocationTitle;

  /// No description provided for @attNoLocationContinue.
  ///
  /// In en, this message translates to:
  /// **'Record without location'**
  String get attNoLocationContinue;

  /// No description provided for @attNoLocationNote.
  ///
  /// In en, this message translates to:
  /// **'Your supervisor will see that this entry has no location.'**
  String get attNoLocationNote;

  /// No description provided for @attOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get attOpenSettings;

  /// No description provided for @attThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get attThisMonth;

  /// No description provided for @attDaysPresent.
  ///
  /// In en, this message translates to:
  /// **'Days present'**
  String get attDaysPresent;

  /// No description provided for @attHoursWorked.
  ///
  /// In en, this message translates to:
  /// **'Hours worked'**
  String get attHoursWorked;

  /// No description provided for @attLeaveDays.
  ///
  /// In en, this message translates to:
  /// **'Leave days'**
  String get attLeaveDays;

  /// No description provided for @attHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get attHistory;

  /// No description provided for @attNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No attendance yet this month'**
  String get attNoRecords;

  /// No description provided for @attStatusPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attStatusPresent;

  /// No description provided for @attStatusAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attStatusAbsent;

  /// No description provided for @attStatusLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get attStatusLeave;

  /// No description provided for @attStatusHalfDay.
  ///
  /// In en, this message translates to:
  /// **'Half day'**
  String get attStatusHalfDay;

  /// No description provided for @attStatusHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get attStatusHoliday;

  /// No description provided for @attNotMarked.
  ///
  /// In en, this message translates to:
  /// **'Not marked'**
  String get attNotMarked;

  /// No description provided for @attFlagOutside.
  ///
  /// In en, this message translates to:
  /// **'Outside area'**
  String get attFlagOutside;

  /// No description provided for @attFlagMocked.
  ///
  /// In en, this message translates to:
  /// **'Mock location'**
  String get attFlagMocked;

  /// No description provided for @attFlagNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get attFlagNoLocation;

  /// No description provided for @attVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get attVerified;

  /// No description provided for @attVerifySelected.
  ///
  /// In en, this message translates to:
  /// **'Verify {count}'**
  String attVerifySelected(int count);

  /// No description provided for @attVerifiedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} verified'**
  String attVerifiedCount(int count);

  /// No description provided for @attMark.
  ///
  /// In en, this message translates to:
  /// **'Mark attendance'**
  String get attMark;

  /// No description provided for @attCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct record'**
  String get attCorrect;

  /// No description provided for @attReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get attReason;

  /// No description provided for @attReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Worked at substation, phone had no signal'**
  String get attReasonHint;

  /// No description provided for @attReasonTooShort.
  ///
  /// In en, this message translates to:
  /// **'Give a reason (at least 5 characters)'**
  String get attReasonTooShort;

  /// No description provided for @attTeamEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one reports to you yet'**
  String get attTeamEmpty;

  /// No description provided for @attSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{present} present · {absent} absent · {unmarked} not marked'**
  String attSummaryLine(int present, int absent, int unmarked);

  /// No description provided for @attExportMuster.
  ///
  /// In en, this message translates to:
  /// **'Muster roll'**
  String get attExportMuster;

  /// No description provided for @attMusterTitle.
  ///
  /// In en, this message translates to:
  /// **'Muster roll — {month}'**
  String attMusterTitle(String month);

  /// No description provided for @attExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get attExportPdf;

  /// No description provided for @attExportXlsx.
  ///
  /// In en, this message translates to:
  /// **'Download Excel'**
  String get attExportXlsx;

  /// No description provided for @attSelectSection.
  ///
  /// In en, this message translates to:
  /// **'All my sections'**
  String get attSelectSection;

  /// No description provided for @leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveTitle;

  /// No description provided for @leaveMine.
  ///
  /// In en, this message translates to:
  /// **'My leave'**
  String get leaveMine;

  /// No description provided for @leaveRequest.
  ///
  /// In en, this message translates to:
  /// **'Request leave'**
  String get leaveRequest;

  /// No description provided for @leaveFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get leaveFrom;

  /// No description provided for @leaveTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get leaveTo;

  /// No description provided for @leaveType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get leaveType;

  /// No description provided for @leaveTypeCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get leaveTypeCasual;

  /// No description provided for @leaveTypeSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get leaveTypeSick;

  /// No description provided for @leaveTypeEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get leaveTypeEarned;

  /// No description provided for @leaveTypeUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get leaveTypeUnpaid;

  /// No description provided for @leaveTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get leaveTypeOther;

  /// No description provided for @leaveReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get leaveReason;

  /// No description provided for @leaveSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get leaveSubmit;

  /// No description provided for @leaveSent.
  ///
  /// In en, this message translates to:
  /// **'Leave request sent'**
  String get leaveSent;

  /// No description provided for @leaveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No leave requests'**
  String get leaveEmpty;

  /// No description provided for @leaveCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get leaveCancel;

  /// No description provided for @leaveDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String leaveDays(int count);

  /// No description provided for @leaveDateOrder.
  ///
  /// In en, this message translates to:
  /// **'End date can\'t be before start date'**
  String get leaveDateOrder;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @approvalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvalsTitle;

  /// No description provided for @approvalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for you'**
  String get approvalsEmpty;

  /// No description provided for @approvalsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Requests from your team appear here.'**
  String get approvalsEmptyHint;

  /// No description provided for @approvalsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approvalsApprove;

  /// No description provided for @approvalsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get approvalsReject;

  /// No description provided for @approvalsRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejecting'**
  String get approvalsRejectReason;

  /// No description provided for @approvalsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get approvalsDone;

  /// No description provided for @approvalsKindLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get approvalsKindLeave;

  /// No description provided for @approvalsKindWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Worksheet'**
  String get approvalsKindWorksheet;

  /// No description provided for @approvalsKindMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get approvalsKindMaterial;

  /// No description provided for @approvalsKindBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get approvalsKindBonus;

  /// No description provided for @approvalsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get approvalsOpen;

  /// No description provided for @holidaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidaysTitle;

  /// No description provided for @holidaysAdd.
  ///
  /// In en, this message translates to:
  /// **'Add holiday'**
  String get holidaysAdd;

  /// No description provided for @holidaysName.
  ///
  /// In en, this message translates to:
  /// **'Holiday name'**
  String get holidaysName;

  /// No description provided for @holidaysDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get holidaysDate;

  /// No description provided for @holidaysEmpty.
  ///
  /// In en, this message translates to:
  /// **'No holidays added for {year}'**
  String holidaysEmpty(int year);

  /// No description provided for @holidaysNote.
  ///
  /// In en, this message translates to:
  /// **'Add lunar-calendar holidays (Vishu, Onam, Eid, Deepavali…) each year from the Kerala Government notification.'**
  String get holidaysNote;

  /// No description provided for @holidaysDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String holidaysDeleteConfirm(String name);

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonDelete;

  /// No description provided for @commonDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get commonDate;

  /// No description provided for @wsTitle.
  ///
  /// In en, this message translates to:
  /// **'Worksheets'**
  String get wsTitle;

  /// No description provided for @wsNew.
  ///
  /// In en, this message translates to:
  /// **'New worksheet'**
  String get wsNew;

  /// No description provided for @wsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit worksheet'**
  String get wsEdit;

  /// No description provided for @wsMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get wsMine;

  /// No description provided for @wsSection.
  ///
  /// In en, this message translates to:
  /// **'My sections'**
  String get wsSection;

  /// No description provided for @wsAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get wsAllStatuses;

  /// No description provided for @wsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No worksheets yet'**
  String get wsEmpty;

  /// No description provided for @wsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Create a worksheet before starting a job.'**
  String get wsEmptyHint;

  /// No description provided for @wsType.
  ///
  /// In en, this message translates to:
  /// **'Work type'**
  String get wsType;

  /// No description provided for @wsTypeProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get wsTypeProject;

  /// No description provided for @wsTypeMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get wsTypeMaintenance;

  /// No description provided for @wsTypeCalamity.
  ///
  /// In en, this message translates to:
  /// **'Calamity / breakdown'**
  String get wsTypeCalamity;

  /// No description provided for @wsJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get wsJobTitle;

  /// No description provided for @wsJobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Replace DP fuse at Kaloor junction'**
  String get wsJobTitleHint;

  /// No description provided for @wsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location / landmark'**
  String get wsLocation;

  /// No description provided for @wsUseGps.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get wsUseGps;

  /// No description provided for @wsGpsSet.
  ///
  /// In en, this message translates to:
  /// **'GPS saved (±{accuracy} m)'**
  String wsGpsSet(int accuracy);

  /// No description provided for @wsPermitBook.
  ///
  /// In en, this message translates to:
  /// **'Permit book no.'**
  String get wsPermitBook;

  /// No description provided for @wsDescription.
  ///
  /// In en, this message translates to:
  /// **'Work description'**
  String get wsDescription;

  /// No description provided for @wsPlannedDate.
  ///
  /// In en, this message translates to:
  /// **'Planned date'**
  String get wsPlannedDate;

  /// No description provided for @wsSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get wsSaveDraft;

  /// No description provided for @wsSaveSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save & submit'**
  String get wsSaveSubmit;

  /// No description provided for @wsSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on your phone. It will upload when you\'re back online.'**
  String get wsSavedOffline;

  /// No description provided for @wsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Sent for approval'**
  String get wsSubmitted;

  /// No description provided for @wsStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get wsStatusDraft;

  /// No description provided for @wsStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Waiting approval'**
  String get wsStatusSubmitted;

  /// No description provided for @wsStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get wsStatusApproved;

  /// No description provided for @wsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get wsStatusRejected;

  /// No description provided for @wsStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get wsStatusInProgress;

  /// No description provided for @wsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get wsStatusCompleted;

  /// No description provided for @wsStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get wsStatusCancelled;

  /// No description provided for @wsRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by'**
  String get wsRequestedBy;

  /// No description provided for @wsDecision.
  ///
  /// In en, this message translates to:
  /// **'Decision note'**
  String get wsDecision;

  /// No description provided for @wsActionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval'**
  String get wsActionSubmit;

  /// No description provided for @wsActionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get wsActionApprove;

  /// No description provided for @wsActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get wsActionReject;

  /// No description provided for @wsActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start work'**
  String get wsActionStart;

  /// No description provided for @wsActionComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get wsActionComplete;

  /// No description provided for @wsActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel worksheet'**
  String get wsActionCancel;

  /// No description provided for @wsCompletionNote.
  ///
  /// In en, this message translates to:
  /// **'What was done'**
  String get wsCompletionNote;

  /// No description provided for @wsCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this worksheet? It can\'t be reopened.'**
  String get wsCancelConfirm;

  /// No description provided for @wsCrew.
  ///
  /// In en, this message translates to:
  /// **'Crew'**
  String get wsCrew;

  /// No description provided for @wsCrewEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit crew'**
  String get wsCrewEdit;

  /// No description provided for @wsCrewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No crew assigned'**
  String get wsCrewEmpty;

  /// No description provided for @wsPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get wsPhotos;

  /// No description provided for @wsAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get wsAddPhoto;

  /// No description provided for @wsCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get wsCamera;

  /// No description provided for @wsGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get wsGallery;

  /// No description provided for @wsPhotosEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get wsPhotosEmpty;

  /// No description provided for @wsPhotoQueued.
  ///
  /// In en, this message translates to:
  /// **'Photo saved; it uploads when you\'re online.'**
  String get wsPhotoQueued;

  /// No description provided for @wsPermit.
  ///
  /// In en, this message translates to:
  /// **'Permit to work'**
  String get wsPermit;

  /// No description provided for @wsPermitMissing.
  ///
  /// In en, this message translates to:
  /// **'Not signed yet. Work can\'t start until a supervisor signs the permit.'**
  String get wsPermitMissing;

  /// No description provided for @wsPermitSign.
  ///
  /// In en, this message translates to:
  /// **'Sign permit'**
  String get wsPermitSign;

  /// No description provided for @wsPermitLcRef.
  ///
  /// In en, this message translates to:
  /// **'Line clear (LC) reference'**
  String get wsPermitLcRef;

  /// No description provided for @wsPermitLcBy.
  ///
  /// In en, this message translates to:
  /// **'LC issued by (KSEB officer)'**
  String get wsPermitLcBy;

  /// No description provided for @wsPermitIsolation.
  ///
  /// In en, this message translates to:
  /// **'Isolation points'**
  String get wsPermitIsolation;

  /// No description provided for @wsPermitIsolationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. AB switch at DP-14 opened and locked'**
  String get wsPermitIsolationHint;

  /// No description provided for @wsPermitEarthing.
  ///
  /// In en, this message translates to:
  /// **'Earthing done on both sides'**
  String get wsPermitEarthing;

  /// No description provided for @wsPermitTestedDead.
  ///
  /// In en, this message translates to:
  /// **'Line tested dead with tester'**
  String get wsPermitTestedDead;

  /// No description provided for @wsPermitToolbox.
  ///
  /// In en, this message translates to:
  /// **'Toolbox talk done with the crew'**
  String get wsPermitToolbox;

  /// No description provided for @wsPermitPpe.
  ///
  /// In en, this message translates to:
  /// **'PPE confirmed'**
  String get wsPermitPpe;

  /// No description provided for @wsPermitPpeRequired.
  ///
  /// In en, this message translates to:
  /// **'Helmet, gloves and safety belt are mandatory'**
  String get wsPermitPpeRequired;

  /// No description provided for @wsPermitSignedBy.
  ///
  /// In en, this message translates to:
  /// **'Signed {when}'**
  String wsPermitSignedBy(String when);

  /// No description provided for @ppeHelmet.
  ///
  /// In en, this message translates to:
  /// **'Helmet'**
  String get ppeHelmet;

  /// No description provided for @ppeGloves.
  ///
  /// In en, this message translates to:
  /// **'Insulated gloves'**
  String get ppeGloves;

  /// No description provided for @ppeSafetyBelt.
  ///
  /// In en, this message translates to:
  /// **'Safety belt'**
  String get ppeSafetyBelt;

  /// No description provided for @ppeBoots.
  ///
  /// In en, this message translates to:
  /// **'Safety boots'**
  String get ppeBoots;

  /// No description provided for @ppeInsulatedTools.
  ///
  /// In en, this message translates to:
  /// **'Insulated tools'**
  String get ppeInsulatedTools;

  /// No description provided for @ppeReflectiveVest.
  ///
  /// In en, this message translates to:
  /// **'Reflective vest'**
  String get ppeReflectiveVest;

  /// No description provided for @incTitle.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get incTitle;

  /// No description provided for @incReport.
  ///
  /// In en, this message translates to:
  /// **'Report incident'**
  String get incReport;

  /// No description provided for @incSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get incSeverity;

  /// No description provided for @incNearMiss.
  ///
  /// In en, this message translates to:
  /// **'Near miss'**
  String get incNearMiss;

  /// No description provided for @incMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor injury / damage'**
  String get incMinor;

  /// No description provided for @incMajor.
  ///
  /// In en, this message translates to:
  /// **'Major injury / damage'**
  String get incMajor;

  /// No description provided for @incFatal.
  ///
  /// In en, this message translates to:
  /// **'Fatal'**
  String get incFatal;

  /// No description provided for @incOccurredAt.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get incOccurredAt;

  /// No description provided for @incDescription.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get incDescription;

  /// No description provided for @incInjured.
  ///
  /// In en, this message translates to:
  /// **'People injured (names)'**
  String get incInjured;

  /// No description provided for @incAction.
  ///
  /// In en, this message translates to:
  /// **'Immediate action taken'**
  String get incAction;

  /// No description provided for @incReported.
  ///
  /// In en, this message translates to:
  /// **'Incident reported'**
  String get incReported;

  /// No description provided for @incNone.
  ///
  /// In en, this message translates to:
  /// **'No incidents'**
  String get incNone;

  /// No description provided for @incStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get incStatusOpen;

  /// No description provided for @incStatusInvestigating.
  ///
  /// In en, this message translates to:
  /// **'Investigating'**
  String get incStatusInvestigating;

  /// No description provided for @incStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get incStatusClosed;

  /// No description provided for @invTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get invTitle;

  /// No description provided for @invStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get invStock;

  /// No description provided for @invRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get invRequests;

  /// No description provided for @invSearch.
  ///
  /// In en, this message translates to:
  /// **'Search material or code'**
  String get invSearch;

  /// No description provided for @invAllStores.
  ///
  /// In en, this message translates to:
  /// **'All stores'**
  String get invAllStores;

  /// No description provided for @invLowOnly.
  ///
  /// In en, this message translates to:
  /// **'Low stock only'**
  String get invLowOnly;

  /// No description provided for @invOnHand.
  ///
  /// In en, this message translates to:
  /// **'On hand'**
  String get invOnHand;

  /// No description provided for @invReorderAt.
  ///
  /// In en, this message translates to:
  /// **'Reorder at {qty}'**
  String invReorderAt(String qty);

  /// No description provided for @invLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get invLow;

  /// No description provided for @invNoStock.
  ///
  /// In en, this message translates to:
  /// **'No stock recorded yet'**
  String get invNoStock;

  /// No description provided for @invNoStockHint.
  ///
  /// In en, this message translates to:
  /// **'Stock appears after the first approved receipt.'**
  String get invNoStockHint;

  /// No description provided for @invNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get invNewRequest;

  /// No description provided for @invReqIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue (take from store)'**
  String get invReqIssue;

  /// No description provided for @invReqReturn.
  ///
  /// In en, this message translates to:
  /// **'Return (unused to store)'**
  String get invReqReturn;

  /// No description provided for @invReqReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt (new stock in)'**
  String get invReqReceipt;

  /// No description provided for @invTypeIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get invTypeIssue;

  /// No description provided for @invTypeReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get invTypeReturn;

  /// No description provided for @invTypeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get invTypeReceipt;

  /// No description provided for @invStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get invStore;

  /// No description provided for @invMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get invMaterial;

  /// No description provided for @invQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get invQuantity;

  /// No description provided for @invQtyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity above zero'**
  String get invQtyInvalid;

  /// No description provided for @invAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available: {qty}'**
  String invAvailable(String qty);

  /// No description provided for @invUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price (₹)'**
  String get invUnitPrice;

  /// No description provided for @invSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get invSupplier;

  /// No description provided for @invInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice / DC no.'**
  String get invInvoice;

  /// No description provided for @invWorksheet.
  ///
  /// In en, this message translates to:
  /// **'For worksheet'**
  String get invWorksheet;

  /// No description provided for @invNoWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Not linked to a worksheet'**
  String get invNoWorksheet;

  /// No description provided for @invPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get invPurpose;

  /// No description provided for @invPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get invPriority;

  /// No description provided for @invPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get invPriorityLow;

  /// No description provided for @invPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get invPriorityMedium;

  /// No description provided for @invPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get invPriorityHigh;

  /// No description provided for @invPriorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get invPriorityCritical;

  /// No description provided for @invRequiredBy.
  ///
  /// In en, this message translates to:
  /// **'Required by'**
  String get invRequiredBy;

  /// No description provided for @invSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get invSubmit;

  /// No description provided for @invRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent for approval'**
  String get invRequestSent;

  /// No description provided for @invRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No material requests'**
  String get invRequestsEmpty;

  /// No description provided for @invMineFilter.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get invMineFilter;

  /// No description provided for @invToDecide.
  ///
  /// In en, this message translates to:
  /// **'To decide'**
  String get invToDecide;

  /// No description provided for @invAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get invAllFilter;

  /// No description provided for @invRequestDetail.
  ///
  /// In en, this message translates to:
  /// **'Material request'**
  String get invRequestDetail;

  /// No description provided for @invRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by'**
  String get invRequestedBy;

  /// No description provided for @invDecidedBy.
  ///
  /// In en, this message translates to:
  /// **'Decided by'**
  String get invDecidedBy;

  /// No description provided for @invCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get invCancelRequest;

  /// No description provided for @invCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get invCancelConfirm;

  /// No description provided for @invLedger.
  ///
  /// In en, this message translates to:
  /// **'Stock movements'**
  String get invLedger;

  /// No description provided for @invLedgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No movements yet'**
  String get invLedgerEmpty;

  /// No description provided for @invAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get invAdjust;

  /// No description provided for @invAdjustHelp.
  ///
  /// In en, this message translates to:
  /// **'Use a positive number to add, negative to remove (physical count correction).'**
  String get invAdjustHelp;

  /// No description provided for @invScrap.
  ///
  /// In en, this message translates to:
  /// **'Record as scrap'**
  String get invScrap;

  /// No description provided for @invTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get invTransfer;

  /// No description provided for @invFromStore.
  ///
  /// In en, this message translates to:
  /// **'From store'**
  String get invFromStore;

  /// No description provided for @invToStore.
  ///
  /// In en, this message translates to:
  /// **'To store'**
  String get invToStore;

  /// No description provided for @invCatalog.
  ///
  /// In en, this message translates to:
  /// **'Material catalogue'**
  String get invCatalog;

  /// No description provided for @invAddMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add material'**
  String get invAddMaterial;

  /// No description provided for @invCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get invCode;

  /// No description provided for @invName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get invName;

  /// No description provided for @invCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get invCategory;

  /// No description provided for @invUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get invUnit;

  /// No description provided for @invHsn.
  ///
  /// In en, this message translates to:
  /// **'HSN code'**
  String get invHsn;

  /// No description provided for @invReorderLevel.
  ///
  /// In en, this message translates to:
  /// **'Reorder level'**
  String get invReorderLevel;

  /// No description provided for @invStores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get invStores;

  /// No description provided for @invAddStore.
  ///
  /// In en, this message translates to:
  /// **'Add store'**
  String get invAddStore;

  /// No description provided for @invStoreName.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get invStoreName;

  /// No description provided for @invMaterialsUsed.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get invMaterialsUsed;

  /// No description provided for @invMaterialsUsedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No materials issued for this job yet'**
  String get invMaterialsUsedEmpty;

  /// No description provided for @invIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued {qty}'**
  String invIssued(String qty);

  /// No description provided for @invReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned {qty}'**
  String invReturned(String qty);

  /// No description provided for @invRequestForJob.
  ///
  /// In en, this message translates to:
  /// **'Request material'**
  String get invRequestForJob;

  /// No description provided for @invExportRegister.
  ///
  /// In en, this message translates to:
  /// **'Stock register'**
  String get invExportRegister;

  /// No description provided for @invTxnReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get invTxnReceipt;

  /// No description provided for @invTxnIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get invTxnIssue;

  /// No description provided for @invTxnReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get invTxnReturn;

  /// No description provided for @invTxnAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get invTxnAdjustment;

  /// No description provided for @invTxnTransferIn.
  ///
  /// In en, this message translates to:
  /// **'Transfer in'**
  String get invTxnTransferIn;

  /// No description provided for @invTxnTransferOut.
  ///
  /// In en, this message translates to:
  /// **'Transfer out'**
  String get invTxnTransferOut;

  /// No description provided for @invTxnScrap.
  ///
  /// In en, this message translates to:
  /// **'Scrap'**
  String get invTxnScrap;
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
