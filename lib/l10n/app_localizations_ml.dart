// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appName => 'AumLux';

  @override
  String get appTagline => 'KSEB പ്രവൃത്തികൾക്കുള്ള ഫീൽഡ് ഓപ്പറേഷൻസ്';

  @override
  String get commonRetry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get commonCancel => 'റദ്ദാക്കുക';

  @override
  String get commonSave => 'സേവ് ചെയ്യുക';

  @override
  String get commonContinue => 'തുടരുക';

  @override
  String get commonClose => 'അടയ്ക്കുക';

  @override
  String get commonLoading => 'ലോഡ് ചെയ്യുന്നു…';

  @override
  String get commonSomethingWrong => 'എന്തോ പിശക് സംഭവിച്ചു';

  @override
  String get commonComingSoonTitle => 'ഉടൻ വരുന്നു';

  @override
  String get commonComingSoonBody =>
      'ആപ്പിന്റെ ഈ ഭാഗം പുതുക്കി നിർമ്മിക്കുകയാണ്. അടുത്ത അപ്ഡേറ്റിൽ ലഭ്യമാകും.';

  @override
  String get loginTitle => 'സൈൻ ഇൻ';

  @override
  String get loginSubtitle =>
      'നിങ്ങളുടെ എംപ്ലോയീ ഐഡി അല്ലെങ്കിൽ ഓഫീസ് ഇമെയിൽ ഉപയോഗിക്കുക.';

  @override
  String get loginIdentifierLabel => 'എംപ്ലോയീ ഐഡി അല്ലെങ്കിൽ ഇമെയിൽ';

  @override
  String get loginIdentifierHint => 'ഉദാ. AUM0123';

  @override
  String get loginIdentifierRequired => 'എംപ്ലോയീ ഐഡി അല്ലെങ്കിൽ ഇമെയിൽ നൽകുക';

  @override
  String get loginPasswordLabel => 'പാസ്‌വേഡ്';

  @override
  String get loginPasswordRequired => 'പാസ്‌വേഡ് നൽകുക';

  @override
  String get loginShowPassword => 'പാസ്‌വേഡ് കാണിക്കുക';

  @override
  String get loginHidePassword => 'പാസ്‌വേഡ് മറയ്ക്കുക';

  @override
  String get loginSubmit => 'സൈൻ ഇൻ';

  @override
  String loginCooldown(int seconds) {
    return 'വളരെയധികം ശ്രമങ്ങൾ. $seconds സെക്കൻഡിന് ശേഷം വീണ്ടും ശ്രമിക്കുക.';
  }

  @override
  String get loginForgot => 'പാസ്‌വേഡ് മറന്നോ?';

  @override
  String get loginForgotTitle => 'പാസ്‌വേഡ് റീസെറ്റ് ചെയ്യുക';

  @override
  String get loginForgotBody =>
      'സുരക്ഷയ്ക്കായി പാസ്‌വേഡ് റീസെറ്റ് ചെയ്യുന്നത് നിങ്ങളുടെ സൂപ്പർവൈസറോ മാനേജരോ ആണ്. More › Staff › നിങ്ങളുടെ പേര് › Reset password വഴി റീസെറ്റ് ചെയ്യാൻ അവരോട് ആവശ്യപ്പെടുക. സൈൻ ഇൻ ചെയ്യാൻ ഒരു താൽക്കാലിക പാസ്‌വേഡ് ലഭിക്കും.';

  @override
  String get loginInactive =>
      'നിങ്ങളുടെ അക്കൗണ്ട് സജീവമല്ല. സൂപ്പർവൈസറെ ബന്ധപ്പെടുക.';

  @override
  String get loginNoProfile =>
      'നിങ്ങളുടെ അക്കൗണ്ട് ഇതുവരെ സജ്ജമാക്കിയിട്ടില്ല. മാനേജരെ ബന്ധപ്പെടുക.';

  @override
  String get loginIdleSignedOut =>
      'കുറച്ചുനേരം ഉപയോഗിക്കാതിരുന്നതിനാൽ സൈൻ ഔട്ട് ചെയ്തു.';

  @override
  String get changePasswordTitle => 'പുതിയ പാസ്‌വേഡ് സജ്ജമാക്കുക';

  @override
  String get changePasswordSubtitle =>
      'നിങ്ങൾക്ക് മാത്രം അറിയാവുന്ന ഒരു പാസ്‌വേഡ് തിരഞ്ഞെടുക്കുക. ഇനി മുതൽ ഇതാണ് ഉപയോഗിക്കേണ്ടത്.';

  @override
  String get changePasswordNew => 'പുതിയ പാസ്‌വേഡ്';

  @override
  String get changePasswordConfirm => 'പുതിയ പാസ്‌വേഡ് ഉറപ്പാക്കുക';

  @override
  String get changePasswordRuleLength => 'കുറഞ്ഞത് 8 അക്ഷരങ്ങൾ';

  @override
  String get changePasswordRuleMix => 'അക്ഷരങ്ങളും അക്കങ്ങളും';

  @override
  String get changePasswordMismatch => 'പാസ്‌വേഡുകൾ ഒന്നല്ല';

  @override
  String get changePasswordSubmit => 'പാസ്‌വേഡ് സേവ് ചെയ്യുക';

  @override
  String get changePasswordDone => 'പാസ്‌വേഡ് മാറ്റി';

  @override
  String get navHome => 'ഹോം';

  @override
  String get navAttendance => 'ഹാജർ';

  @override
  String get navWork => 'ജോലി';

  @override
  String get navMore => 'കൂടുതൽ';

  @override
  String get homeGreetingMorning => 'സുപ്രഭാതം';

  @override
  String get homeGreetingAfternoon => 'ശുഭ ഉച്ച';

  @override
  String get homeGreetingEvening => 'ശുഭ സായാഹ്നം';

  @override
  String get homeTodayTitle => 'ഇന്ന്';

  @override
  String get homeNotCheckedIn => 'ഇതുവരെ ചെക്ക് ഇൻ ചെയ്തിട്ടില്ല';

  @override
  String homeCheckedInAt(String time) {
    return '$time-ന് ചെക്ക് ഇൻ ചെയ്തു';
  }

  @override
  String homeCheckedOutAt(String time) {
    return '$time-ന് ചെക്ക് ഔട്ട് ചെയ്തു';
  }

  @override
  String get homeOverview => 'സംഗ്രഹം';

  @override
  String get kpiPresentThisMonth => 'ഈ മാസം ഹാജർ';

  @override
  String get kpiPendingApprovals => 'നിങ്ങളുടെ അംഗീകാരം കാത്ത്';

  @override
  String get kpiTeamPresentToday => 'ഇന്ന് ടീമിൽ ഹാജർ';

  @override
  String get kpiWorkInProgress => 'നടന്നുകൊണ്ടിരിക്കുന്ന ജോലി';

  @override
  String get kpiOpenIncidents => 'തീർപ്പാകാത്ത അപകടങ്ങൾ';

  @override
  String get kpiLowStock => 'സ്റ്റോക്ക് കുറവുള്ളവ';

  @override
  String get kpiActiveWorkOrders => 'സജീവ വർക്ക് ഓർഡറുകൾ';

  @override
  String get kpiOpenTenders => 'തുറന്ന ടെൻഡറുകൾ';

  @override
  String get kpiDepositsHeld => 'നിക്ഷേപങ്ങൾ (കെട്ടിവെച്ചത്)';

  @override
  String get kpiDepositsExpiring => 'കാലാവധി തീരുന്ന നിക്ഷേപങ്ങൾ (30 ദിവസം)';

  @override
  String get kpiReceivables => 'ലഭിക്കാനുള്ള തുക';

  @override
  String get kpiReceivables90 => '90 ദിവസത്തിലേറെ കുടിശ്ശിക';

  @override
  String get kpiUnreadNotifications => 'വായിക്കാത്ത അറിയിപ്പുകൾ';

  @override
  String get homeLoadFailed => 'ഡാഷ്‌ബോർഡ് ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get moreTitle => 'കൂടുതൽ';

  @override
  String get moreProfile => 'എന്റെ പ്രൊഫൈൽ';

  @override
  String get moreSyncQueue => 'സിങ്ക് ക്യൂ';

  @override
  String get moreSyncQueueEmpty => 'എല്ലാം സിങ്ക് ചെയ്തു';

  @override
  String get moreLanguage => 'ഭാഷ';

  @override
  String get moreChangePassword => 'പാസ്‌വേഡ് മാറ്റുക';

  @override
  String get moreAbout => 'ആപ്പിനെക്കുറിച്ച് & ലൈസൻസുകൾ';

  @override
  String get moreSignOut => 'സൈൻ ഔട്ട്';

  @override
  String get moreSignOutConfirmTitle => 'സൈൻ ഔട്ട് ചെയ്യണോ?';

  @override
  String get moreSignOutConfirmBody =>
      'വീണ്ടും സൈൻ ഇൻ ചെയ്യാൻ എംപ്ലോയീ ഐഡി/ഇമെയിലും പാസ്‌വേഡും വേണം.';

  @override
  String moreSignOutPendingBody(int count) {
    return '$count എണ്ണം ഇതുവരെ സിങ്ക് ആയിട്ടില്ല. അവ ഈ ഫോണിൽ തന്നെ ഉണ്ടാകും; ഇതേ അക്കൗണ്ടിൽ വീണ്ടും സൈൻ ഇൻ ചെയ്യുമ്പോൾ അപ്‌ലോഡ് ആകും.';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalayalam => 'മലയാളം';

  @override
  String get syncTitle => 'സിങ്ക് ക്യൂ';

  @override
  String get syncPending => 'സിങ്ക് ചെയ്യാൻ കാത്തിരിക്കുന്നു';

  @override
  String get syncFailed => 'സിങ്ക് ചെയ്യാനായില്ല';

  @override
  String get syncRetry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get syncDiscard => 'ഒഴിവാക്കുക';

  @override
  String get syncDiscardConfirm => 'ഇത് ഒഴിവാക്കണോ? ഇത് അപ്‌ലോഡ് ചെയ്യില്ല.';

  @override
  String get syncNow => 'ഇപ്പോൾ സിങ്ക് ചെയ്യുക';

  @override
  String get offlineBanner =>
      'നിങ്ങൾ ഓഫ്‌ലൈനാണ്. നെറ്റ്‌വർക്ക് തിരിച്ചെത്തുമ്പോൾ മാറ്റങ്ങൾ സിങ്ക് ആകും.';

  @override
  String pendingSync(int count) {
    return '$count ബാക്കി';
  }

  @override
  String get roleStaff => 'സ്റ്റാഫ്';

  @override
  String get roleSupervisor => 'സൂപ്പർവൈസർ';

  @override
  String get roleManager => 'മാനേജർ';

  @override
  String get roleCoo => 'സി.ഒ.ഒ';

  @override
  String get roleDirector => 'ഡയറക്ടർ';

  @override
  String get errorNetwork =>
      'കണക്ഷൻ ഇല്ല. മൊബൈൽ ഡാറ്റ അല്ലെങ്കിൽ വൈ-ഫൈ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get errorForbidden => 'ഇത് ചെയ്യാൻ നിങ്ങൾക്ക് അനുമതിയില്ല.';

  @override
  String get errorSessionExpired =>
      'സെഷൻ കാലഹരണപ്പെട്ടു. വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get errorInvalidCredentials =>
      'എംപ്ലോയീ ഐഡി / ഇമെയിൽ അല്ലെങ്കിൽ പാസ്‌വേഡ് തെറ്റാണ്.';

  @override
  String get errorWeakPassword =>
      'അക്ഷരങ്ങളും അക്കങ്ങളും ചേർന്ന കുറഞ്ഞത് 8 അക്ഷരങ്ങൾ ഉപയോഗിക്കുക.';

  @override
  String get errorSamePassword =>
      'ഇപ്പോഴത്തേതിൽ നിന്ന് വ്യത്യസ്തമായ പാസ്‌വേഡ് തിരഞ്ഞെടുക്കുക.';

  @override
  String get adminSection => 'ഭരണ നിർവ്വഹണം';

  @override
  String get staffTitle => 'ജീവനക്കാർ';

  @override
  String get staffMyTeam => 'എന്റെ ടീം';

  @override
  String get staffSearch => 'പേര്, ഐഡി അല്ലെങ്കിൽ ഫോൺ തിരയുക';

  @override
  String get staffAdd => 'ജീവനക്കാരെ ചേർക്കുക';

  @override
  String get staffEmpty => 'ജീവനക്കാരെ കണ്ടെത്തിയില്ല';

  @override
  String get staffEmptyHint => 'മറ്റൊരു തിരയലോ ഫിൽട്ടറോ പരീക്ഷിക്കുക.';

  @override
  String get staffFilterAll => 'എല്ലാം';

  @override
  String get statusActive => 'സജീവം';

  @override
  String get statusSuspended => 'താൽക്കാലികമായി തടഞ്ഞു';

  @override
  String get statusExited => 'പിരിഞ്ഞുപോയി';

  @override
  String get staffDetails => 'വിവരങ്ങൾ';

  @override
  String get staffEmployeeCode => 'എംപ്ലോയീ ഐഡി';

  @override
  String get staffFullName => 'മുഴുവൻ പേര്';

  @override
  String get staffRole => 'പദവി';

  @override
  String get staffSection => 'സെക്ഷൻ';

  @override
  String get staffTeam => 'ടീം';

  @override
  String get staffNoTeam => 'ടീം ഇല്ല';

  @override
  String get staffPhone => 'മൊബൈൽ നമ്പർ';

  @override
  String get staffEmail => 'ഇമെയിൽ (ഓഫീസർമാർക്ക് മാത്രം)';

  @override
  String get staffEmailHelper =>
      'ഫീൽഡ് ജീവനക്കാർക്ക് ഒഴിച്ചിടുക. അവർ എംപ്ലോയീ ഐഡി ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യും.';

  @override
  String get staffDob => 'ജനനത്തീയതി';

  @override
  String get staffJoined => 'ചേർന്നത്';

  @override
  String get staffEdit => 'വിവരങ്ങൾ തിരുത്തുക';

  @override
  String get staffResetPassword => 'പാസ്‌വേഡ് റീസെറ്റ് ചെയ്യുക';

  @override
  String staffResetConfirm(String name) {
    return '$name-ന്റെ പാസ്‌വേഡ് റീസെറ്റ് ചെയ്യണോ? സൈൻ ഇൻ ചെയ്യാൻ പുതിയ താൽക്കാലിക പാസ്‌വേഡ് വേണം.';
  }

  @override
  String get staffSuspend => 'ലോഗിൻ താൽക്കാലികമായി തടയുക';

  @override
  String get staffReactivate => 'വീണ്ടും സജീവമാക്കുക';

  @override
  String get staffMarkExited => 'പിരിഞ്ഞുപോയതായി രേഖപ്പെടുത്തുക';

  @override
  String staffSuspendConfirm(String name) {
    return '$name-നെ തടയണോ? ഉടൻ സൈൻ ഔട്ട് ആകും; വീണ്ടും സജീവമാക്കുന്നതുവരെ സൈൻ ഇൻ ചെയ്യാനാകില്ല.';
  }

  @override
  String staffExitConfirm(String name) {
    return '$name പിരിഞ്ഞുപോയതായി രേഖപ്പെടുത്തണോ? ലോഗിൻ നിർത്തലാക്കും; രേഖകൾ സൂക്ഷിക്കും.';
  }

  @override
  String get staffSaved => 'സേവ് ചെയ്തു';

  @override
  String get staffCodeInvalid => '2–32 അക്ഷരങ്ങൾ, അക്കങ്ങൾ, - അല്ലെങ്കിൽ _';

  @override
  String get staffPhoneInvalid => '10 അക്ക മൊബൈൽ നമ്പർ നൽകുക';

  @override
  String get staffEmailInvalid => 'ശരിയായ ഇമെയിൽ നൽകുക';

  @override
  String get staffNewTitle => 'പുതിയ ജീവനക്കാരൻ';

  @override
  String get staffEditTitle => 'ജീവനക്കാരന്റെ വിവരങ്ങൾ തിരുത്തുക';

  @override
  String get credentialsTitle => 'സൈൻ ഇൻ വിവരങ്ങൾ കൈമാറുക';

  @override
  String credentialsBody(String name) {
    return 'ഇവ $name-ന് നേരിട്ട് നൽകുക. പാസ്‌വേഡ് ഒരിക്കൽ മാത്രമേ കാണിക്കൂ; ആദ്യ സൈൻ ഇന്നിൽ മാറ്റണം.';
  }

  @override
  String get credentialsLoginId => 'സൈൻ ഇൻ ചെയ്യേണ്ടത്';

  @override
  String get credentialsPassword => 'താൽക്കാലിക പാസ്‌വേഡ്';

  @override
  String get credentialsCopy => 'പകർത്തുക';

  @override
  String get credentialsCopied => 'പകർത്തി';

  @override
  String get credentialsDone => 'പൂർത്തിയായി';

  @override
  String get teamsTitle => 'ടീമുകൾ';

  @override
  String get teamsAdd => 'ടീം ചേർക്കുക';

  @override
  String get teamsEmpty => 'ഇതുവരെ ടീമുകളില്ല';

  @override
  String get teamName => 'ടീമിന്റെ പേര്';

  @override
  String get teamSupervisor => 'സൂപ്പർവൈസർ';

  @override
  String get teamNoSupervisor => 'സൂപ്പർവൈസർ ഇല്ല';

  @override
  String get teamActive => 'സജീവം';

  @override
  String teamMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count അംഗങ്ങൾ',
      one: '1 അംഗം',
      zero: 'അംഗങ്ങളില്ല',
    );
    return '$_temp0';
  }

  @override
  String get orgTitle => 'സ്ഥാപന ഘടന';

  @override
  String get orgCircle => 'സർക്കിൾ';

  @override
  String get orgDivision => 'ഡിവിഷൻ';

  @override
  String get orgSubdivision => 'സബ് ഡിവിഷൻ';

  @override
  String get orgSectionOffice => 'സെക്ഷൻ ഓഫീസ്';

  @override
  String orgAdd(String level) {
    return '$level ചേർക്കുക';
  }

  @override
  String get orgCode => 'കോഡ്';

  @override
  String get orgName => 'പേര്';

  @override
  String get orgAddress => 'വിലാസം';

  @override
  String get orgLatitude => 'അക്ഷാംശം';

  @override
  String get orgLongitude => 'രേഖാംശം';

  @override
  String get orgGeofence => 'ഹാജർ പരിധി (മീറ്റർ)';

  @override
  String get orgGeofenceHelper =>
      'സെക്ഷൻ ഓഫീസിൽ നിന്ന് ഇതിലും അകലെയുള്ള ചെക്ക് ഇന്നുകൾ അടയാളപ്പെടുത്തും.';

  @override
  String get orgCoordsInvalid =>
      'അക്ഷാംശവും രേഖാംശവും രണ്ടും നൽകുക, അല്ലെങ്കിൽ രണ്ടും ഒഴിവാക്കുക';

  @override
  String get orgEmpty => 'ഇതുവരെ യൂണിറ്റുകളില്ല';

  @override
  String fieldRequired(String field) {
    return '$field ആവശ്യമാണ്';
  }

  @override
  String get orgNoLocation => 'സ്ഥാനം നൽകിയിട്ടില്ല';
}
