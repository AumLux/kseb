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

  @override
  String get exportTitle => 'ഫയൽ തയ്യാറാണ്';

  @override
  String get exportOpen => 'തുറക്കുക';

  @override
  String get exportShare => 'പങ്കിടുക';

  @override
  String get exportCancelled => 'എക്സ്പോർട്ട് റദ്ദാക്കി.';

  @override
  String get exportNoApp => 'ഈ ഫയൽ തുറക്കാൻ ആപ്പ് ഇല്ല.';

  @override
  String get attMe => 'ഞാൻ';

  @override
  String get attTeam => 'ടീം';

  @override
  String get attCheckIn => 'ചെക്ക് ഇൻ';

  @override
  String get attCheckOut => 'ചെക്ക് ഔട്ട്';

  @override
  String get attCheckedIn => 'ചെക്ക് ഇൻ ചെയ്തു';

  @override
  String get attCheckedOut => 'ചെക്ക് ഔട്ട് ചെയ്തു';

  @override
  String get attDoneForDay => 'ഇന്നത്തെ ജോലി പൂർത്തിയായി';

  @override
  String attWorked(String duration) {
    return '$duration ജോലി ചെയ്തു';
  }

  @override
  String get attLocating => 'സ്ഥാനം കണ്ടെത്തുന്നു…';

  @override
  String get attSynced => 'ഹാജർ രേഖപ്പെടുത്തി';

  @override
  String get attQueued =>
      'ഫോണിൽ സേവ് ചെയ്തു. നെറ്റ്‌വർക്ക് തിരിച്ചെത്തുമ്പോൾ സിങ്ക് ആകും.';

  @override
  String get attPendingSync => 'സിങ്ക് ചെയ്യാൻ കാത്തിരിക്കുന്നു';

  @override
  String get attNoLocationTitle => 'സ്ഥാനം ലഭ്യമല്ല';

  @override
  String get attNoLocationContinue => 'സ്ഥാനമില്ലാതെ രേഖപ്പെടുത്തുക';

  @override
  String get attNoLocationNote =>
      'ഈ എൻട്രിയിൽ സ്ഥാനമില്ലെന്ന് സൂപ്പർവൈസർക്ക് കാണാം.';

  @override
  String get attOpenSettings => 'സെറ്റിംഗ്സ് തുറക്കുക';

  @override
  String get attThisMonth => 'ഈ മാസം';

  @override
  String get attDaysPresent => 'ഹാജരായ ദിവസങ്ങൾ';

  @override
  String get attHoursWorked => 'ജോലി ചെയ്ത മണിക്കൂർ';

  @override
  String get attLeaveDays => 'അവധി ദിവസങ്ങൾ';

  @override
  String get attHistory => 'ചരിത്രം';

  @override
  String get attNoRecords => 'ഈ മാസം ഇതുവരെ ഹാജർ ഇല്ല';

  @override
  String get attStatusPresent => 'ഹാജർ';

  @override
  String get attStatusAbsent => 'ഹാജരില്ല';

  @override
  String get attStatusLeave => 'അവധി';

  @override
  String get attStatusHalfDay => 'അര ദിവസം';

  @override
  String get attStatusHoliday => 'പൊതു അവധി';

  @override
  String get attNotMarked => 'രേഖപ്പെടുത്തിയിട്ടില്ല';

  @override
  String get attFlagOutside => 'പരിധിക്ക് പുറത്ത്';

  @override
  String get attFlagMocked => 'വ്യാജ സ്ഥാനം';

  @override
  String get attFlagNoLocation => 'സ്ഥാനമില്ല';

  @override
  String get attVerified => 'പരിശോധിച്ചു';

  @override
  String attVerifySelected(int count) {
    return '$count പരിശോധിക്കുക';
  }

  @override
  String attVerifiedCount(int count) {
    return '$count പരിശോധിച്ചു';
  }

  @override
  String get attMark => 'ഹാജർ രേഖപ്പെടുത്തുക';

  @override
  String get attCorrect => 'രേഖ തിരുത്തുക';

  @override
  String get attReason => 'കാരണം';

  @override
  String get attReasonHint =>
      'ഉദാ. സബ്‌സ്റ്റേഷനിൽ ജോലി, ഫോണിൽ സിഗ്നൽ ഇല്ലായിരുന്നു';

  @override
  String get attReasonTooShort => 'കാരണം നൽകുക (കുറഞ്ഞത് 5 അക്ഷരങ്ങൾ)';

  @override
  String get attTeamEmpty => 'ഇതുവരെ നിങ്ങളുടെ കീഴിൽ ആരുമില്ല';

  @override
  String attSummaryLine(int present, int absent, int unmarked) {
    return '$present ഹാജർ · $absent ഹാജരില്ല · $unmarked രേഖപ്പെടുത്താത്തവർ';
  }

  @override
  String get attExportMuster => 'മസ്റ്റർ റോൾ';

  @override
  String attMusterTitle(String month) {
    return 'മസ്റ്റർ റോൾ — $month';
  }

  @override
  String get attExportPdf => 'PDF ഡൗൺലോഡ്';

  @override
  String get attExportXlsx => 'Excel ഡൗൺലോഡ്';

  @override
  String get attSelectSection => 'എന്റെ എല്ലാ സെക്ഷനുകളും';

  @override
  String get leaveTitle => 'അവധി';

  @override
  String get leaveMine => 'എന്റെ അവധി';

  @override
  String get leaveRequest => 'അവധി അപേക്ഷ';

  @override
  String get leaveFrom => 'മുതൽ';

  @override
  String get leaveTo => 'വരെ';

  @override
  String get leaveType => 'തരം';

  @override
  String get leaveTypeCasual => 'കാഷ്വൽ';

  @override
  String get leaveTypeSick => 'അസുഖ അവധി';

  @override
  String get leaveTypeEarned => 'ആർജിത അവധി';

  @override
  String get leaveTypeUnpaid => 'ശമ്പളമില്ലാത്ത അവധി';

  @override
  String get leaveTypeOther => 'മറ്റുള്ളവ';

  @override
  String get leaveReason => 'കാരണം';

  @override
  String get leaveSubmit => 'അപേക്ഷ അയയ്ക്കുക';

  @override
  String get leaveSent => 'അവധി അപേക്ഷ അയച്ചു';

  @override
  String get leaveEmpty => 'അവധി അപേക്ഷകളില്ല';

  @override
  String get leaveCancel => 'അപേക്ഷ റദ്ദാക്കുക';

  @override
  String leaveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ദിവസം',
      one: '1 ദിവസം',
    );
    return '$_temp0';
  }

  @override
  String get leaveDateOrder => 'അവസാന തീയതി ആരംഭ തീയതിക്ക് മുമ്പാകരുത്';

  @override
  String get statusPending => 'തീർപ്പാകാത്തത്';

  @override
  String get statusApproved => 'അംഗീകരിച്ചു';

  @override
  String get statusRejected => 'നിരസിച്ചു';

  @override
  String get statusCancelled => 'റദ്ദാക്കി';

  @override
  String get approvalsTitle => 'അംഗീകാരങ്ങൾ';

  @override
  String get approvalsEmpty => 'നിങ്ങൾക്കായി ഒന്നും കാത്തിരിക്കുന്നില്ല';

  @override
  String get approvalsEmptyHint => 'ടീമിന്റെ അപേക്ഷകൾ ഇവിടെ കാണാം.';

  @override
  String get approvalsApprove => 'അംഗീകരിക്കുക';

  @override
  String get approvalsReject => 'നിരസിക്കുക';

  @override
  String get approvalsRejectReason => 'നിരസിക്കാനുള്ള കാരണം';

  @override
  String get approvalsDone => 'പൂർത്തിയായി';

  @override
  String get approvalsKindLeave => 'അവധി';

  @override
  String get approvalsKindWorksheet => 'വർക്ക്ഷീറ്റ്';

  @override
  String get approvalsKindMaterial => 'സാമഗ്രി';

  @override
  String get approvalsKindBonus => 'ബോണസ്';

  @override
  String get approvalsOpen => 'തുറക്കുക';

  @override
  String get holidaysTitle => 'അവധി ദിവസങ്ങൾ';

  @override
  String get holidaysAdd => 'അവധി ചേർക്കുക';

  @override
  String get holidaysName => 'അവധിയുടെ പേര്';

  @override
  String get holidaysDate => 'തീയതി';

  @override
  String holidaysEmpty(int year) {
    return '$year-ലേക്ക് അവധികൾ ചേർത്തിട്ടില്ല';
  }

  @override
  String get holidaysNote =>
      'ചാന്ദ്ര കലണ്ടർ പ്രകാരമുള്ള അവധികൾ (വിഷു, ഓണം, ഈദ്, ദീപാവലി…) കേരള സർക്കാർ വിജ്ഞാപനം അനുസരിച്ച് ഓരോ വർഷവും ചേർക്കുക.';

  @override
  String holidaysDeleteConfirm(String name) {
    return '$name നീക്കം ചെയ്യണോ?';
  }

  @override
  String get commonDelete => 'നീക്കം ചെയ്യുക';

  @override
  String get commonDate => 'തീയതി';

  @override
  String get wsTitle => 'വർക്ക്ഷീറ്റുകൾ';

  @override
  String get wsNew => 'പുതിയ വർക്ക്ഷീറ്റ്';

  @override
  String get wsEdit => 'വർക്ക്ഷീറ്റ് തിരുത്തുക';

  @override
  String get wsMine => 'എന്റേത്';

  @override
  String get wsSection => 'എന്റെ സെക്ഷനുകൾ';

  @override
  String get wsAllStatuses => 'എല്ലാം';

  @override
  String get wsEmpty => 'ഇതുവരെ വർക്ക്ഷീറ്റുകളില്ല';

  @override
  String get wsEmptyHint =>
      'ജോലി തുടങ്ങുന്നതിന് മുമ്പ് വർക്ക്ഷീറ്റ് ഉണ്ടാക്കുക.';

  @override
  String get wsType => 'ജോലിയുടെ തരം';

  @override
  String get wsTypeProject => 'പ്രോജക്ട്';

  @override
  String get wsTypeMaintenance => 'അറ്റകുറ്റപ്പണി';

  @override
  String get wsTypeCalamity => 'പ്രകൃതിക്ഷോഭം / തകരാർ';

  @override
  String get wsJobTitle => 'ജോലിയുടെ പേര്';

  @override
  String get wsJobTitleHint => 'ഉദാ. കലൂർ ജംഗ്ഷനിൽ DP ഫ്യൂസ് മാറ്റൽ';

  @override
  String get wsLocation => 'സ്ഥലം / അടയാളം';

  @override
  String get wsUseGps => 'എന്റെ സ്ഥാനം ഉപയോഗിക്കുക';

  @override
  String wsGpsSet(int accuracy) {
    return 'GPS സേവ് ചെയ്തു (±$accuracy മീ)';
  }

  @override
  String get wsPermitBook => 'പെർമിറ്റ് ബുക്ക് നമ്പർ';

  @override
  String get wsDescription => 'ജോലിയുടെ വിവരണം';

  @override
  String get wsPlannedDate => 'നിശ്ചയിച്ച തീയതി';

  @override
  String get wsSaveDraft => 'ഡ്രാഫ്റ്റ് സേവ് ചെയ്യുക';

  @override
  String get wsSaveSubmit => 'സേവ് ചെയ്ത് സമർപ്പിക്കുക';

  @override
  String get wsSavedOffline =>
      'ഫോണിൽ സേവ് ചെയ്തു. നെറ്റ്‌വർക്ക് തിരിച്ചെത്തുമ്പോൾ അപ്‌ലോഡ് ആകും.';

  @override
  String get wsSubmitted => 'അംഗീകാരത്തിന് അയച്ചു';

  @override
  String get wsStatusDraft => 'ഡ്രാഫ്റ്റ്';

  @override
  String get wsStatusSubmitted => 'അംഗീകാരം കാത്ത്';

  @override
  String get wsStatusApproved => 'അംഗീകരിച്ചു';

  @override
  String get wsStatusRejected => 'നിരസിച്ചു';

  @override
  String get wsStatusInProgress => 'പുരോഗമിക്കുന്നു';

  @override
  String get wsStatusCompleted => 'പൂർത്തിയായി';

  @override
  String get wsStatusCancelled => 'റദ്ദാക്കി';

  @override
  String get wsRequestedBy => 'അപേക്ഷിച്ചത്';

  @override
  String get wsDecision => 'തീരുമാന കുറിപ്പ്';

  @override
  String get wsActionSubmit => 'അംഗീകാരത്തിന് സമർപ്പിക്കുക';

  @override
  String get wsActionApprove => 'അംഗീകരിക്കുക';

  @override
  String get wsActionReject => 'നിരസിക്കുക';

  @override
  String get wsActionStart => 'ജോലി ആരംഭിക്കുക';

  @override
  String get wsActionComplete => 'പൂർത്തിയായതായി രേഖപ്പെടുത്തുക';

  @override
  String get wsActionCancel => 'വർക്ക്ഷീറ്റ് റദ്ദാക്കുക';

  @override
  String get wsCompletionNote => 'ചെയ്ത ജോലി';

  @override
  String get wsCancelConfirm =>
      'ഈ വർക്ക്ഷീറ്റ് റദ്ദാക്കണോ? വീണ്ടും തുറക്കാനാകില്ല.';

  @override
  String get wsCrew => 'ജോലിക്കാർ';

  @override
  String get wsCrewEdit => 'ജോലിക്കാരെ മാറ്റുക';

  @override
  String get wsCrewEmpty => 'ജോലിക്കാരെ നിയോഗിച്ചിട്ടില്ല';

  @override
  String get wsPhotos => 'ഫോട്ടോകൾ';

  @override
  String get wsAddPhoto => 'ഫോട്ടോ ചേർക്കുക';

  @override
  String get wsCamera => 'ക്യാമറ';

  @override
  String get wsGallery => 'ഗാലറി';

  @override
  String get wsPhotosEmpty => 'ഇതുവരെ ഫോട്ടോകളില്ല';

  @override
  String get wsPhotoQueued =>
      'ഫോട്ടോ സേവ് ചെയ്തു; നെറ്റ്‌വർക്ക് ലഭിക്കുമ്പോൾ അപ്‌ലോഡ് ആകും.';

  @override
  String get wsPermit => 'പെർമിറ്റ് ടു വർക്ക്';

  @override
  String get wsPermitMissing =>
      'ഇതുവരെ ഒപ്പിട്ടിട്ടില്ല. സൂപ്പർവൈസർ പെർമിറ്റ് ഒപ്പിടുന്നതുവരെ ജോലി ആരംഭിക്കാനാകില്ല.';

  @override
  String get wsPermitSign => 'പെർമിറ്റ് ഒപ്പിടുക';

  @override
  String get wsPermitLcRef => 'ലൈൻ ക്ലിയർ (LC) റഫറൻസ്';

  @override
  String get wsPermitLcBy => 'LC നൽകിയത് (KSEB ഉദ്യോഗസ്ഥൻ)';

  @override
  String get wsPermitIsolation => 'ഐസൊലേഷൻ പോയിന്റുകൾ';

  @override
  String get wsPermitIsolationHint =>
      'ഉദാ. DP-14-ലെ AB സ്വിച്ച് തുറന്ന് പൂട്ടി';

  @override
  String get wsPermitEarthing => 'ഇരുവശത്തും എർത്തിംഗ് ചെയ്തു';

  @override
  String get wsPermitTestedDead =>
      'ടെസ്റ്റർ ഉപയോഗിച്ച് ലൈൻ ഡെഡ് എന്ന് ഉറപ്പാക്കി';

  @override
  String get wsPermitToolbox => 'ജോലിക്കാരുമായി ടൂൾബോക്സ് ടോക്ക് നടത്തി';

  @override
  String get wsPermitPpe => 'സുരക്ഷാ ഉപകരണങ്ങൾ ഉറപ്പാക്കി';

  @override
  String get wsPermitPpeRequired =>
      'ഹെൽമെറ്റ്, ഗ്ലൗസ്, സേഫ്റ്റി ബെൽറ്റ് നിർബന്ധം';

  @override
  String wsPermitSignedBy(String when) {
    return 'ഒപ്പിട്ടത് $when';
  }

  @override
  String get ppeHelmet => 'ഹെൽമെറ്റ്';

  @override
  String get ppeGloves => 'ഇൻസുലേറ്റഡ് ഗ്ലൗസ്';

  @override
  String get ppeSafetyBelt => 'സേഫ്റ്റി ബെൽറ്റ്';

  @override
  String get ppeBoots => 'സേഫ്റ്റി ബൂട്ട്';

  @override
  String get ppeInsulatedTools => 'ഇൻസുലേറ്റഡ് ഉപകരണങ്ങൾ';

  @override
  String get ppeReflectiveVest => 'റിഫ്ലക്ടീവ് വെസ്റ്റ്';

  @override
  String get incTitle => 'അപകടങ്ങൾ';

  @override
  String get incReport => 'അപകടം റിപ്പോർട്ട് ചെയ്യുക';

  @override
  String get incSeverity => 'ഗൗരവം';

  @override
  String get incNearMiss => 'തലനാരിഴയ്ക്ക് ഒഴിവായത്';

  @override
  String get incMinor => 'ചെറിയ പരിക്ക് / കേടുപാട്';

  @override
  String get incMajor => 'ഗുരുതര പരിക്ക് / കേടുപാട്';

  @override
  String get incFatal => 'മരണം';

  @override
  String get incOccurredAt => 'എപ്പോൾ';

  @override
  String get incDescription => 'എന്താണ് സംഭവിച്ചത്';

  @override
  String get incInjured => 'പരിക്കേറ്റവർ (പേരുകൾ)';

  @override
  String get incAction => 'ഉടൻ സ്വീകരിച്ച നടപടി';

  @override
  String get incReported => 'അപകടം റിപ്പോർട്ട് ചെയ്തു';

  @override
  String get incNone => 'അപകടങ്ങളില്ല';

  @override
  String get incStatusOpen => 'തുറന്നത്';

  @override
  String get incStatusInvestigating => 'അന്വേഷണത്തിൽ';

  @override
  String get incStatusClosed => 'അവസാനിപ്പിച്ചു';

  @override
  String get invTitle => 'സ്റ്റോക്ക് / സാമഗ്രികൾ';

  @override
  String get invStock => 'സ്റ്റോക്ക്';

  @override
  String get invRequests => 'അപേക്ഷകൾ';

  @override
  String get invSearch => 'സാമഗ്രിയോ കോഡോ തിരയുക';

  @override
  String get invAllStores => 'എല്ലാ സ്റ്റോറുകളും';

  @override
  String get invLowOnly => 'കുറവുള്ളവ മാത്രം';

  @override
  String get invOnHand => 'കൈവശം';

  @override
  String invReorderAt(String qty) {
    return '$qty-ൽ വീണ്ടും ഓർഡർ';
  }

  @override
  String get invLow => 'കുറവ്';

  @override
  String get invNoStock => 'ഇതുവരെ സ്റ്റോക്ക് രേഖപ്പെടുത്തിയിട്ടില്ല';

  @override
  String get invNoStockHint => 'ആദ്യ രസീത് അംഗീകരിച്ചശേഷം സ്റ്റോക്ക് കാണാം.';

  @override
  String get invNewRequest => 'പുതിയ അപേക്ഷ';

  @override
  String get invReqIssue => 'ഇഷ്യൂ (സ്റ്റോറിൽ നിന്ന് എടുക്കൽ)';

  @override
  String get invReqReturn => 'റിട്ടേൺ (ഉപയോഗിക്കാത്തത് തിരികെ)';

  @override
  String get invReqReceipt => 'രസീത് (പുതിയ സ്റ്റോക്ക് വരവ്)';

  @override
  String get invTypeIssue => 'ഇഷ്യൂ';

  @override
  String get invTypeReturn => 'റിട്ടേൺ';

  @override
  String get invTypeReceipt => 'രസീത്';

  @override
  String get invStore => 'സ്റ്റോർ';

  @override
  String get invMaterial => 'സാമഗ്രി';

  @override
  String get invQuantity => 'അളവ്';

  @override
  String get invQtyInvalid => 'പൂജ്യത്തിൽ കൂടുതൽ അളവ് നൽകുക';

  @override
  String invAvailable(String qty) {
    return 'ലഭ്യം: $qty';
  }

  @override
  String get invUnitPrice => 'യൂണിറ്റ് വില (₹)';

  @override
  String get invSupplier => 'വിതരണക്കാരൻ';

  @override
  String get invInvoice => 'ഇൻവോയ്സ് / DC നമ്പർ';

  @override
  String get invWorksheet => 'വർക്ക്ഷീറ്റിനായി';

  @override
  String get invNoWorksheet => 'വർക്ക്ഷീറ്റുമായി ബന്ധിപ്പിച്ചിട്ടില്ല';

  @override
  String get invPurpose => 'ആവശ്യം';

  @override
  String get invPriority => 'മുൻഗണന';

  @override
  String get invPriorityLow => 'കുറവ്';

  @override
  String get invPriorityMedium => 'ഇടത്തരം';

  @override
  String get invPriorityHigh => 'ഉയർന്നത്';

  @override
  String get invPriorityCritical => 'അടിയന്തരം';

  @override
  String get invRequiredBy => 'ആവശ്യമുള്ള തീയതി';

  @override
  String get invSubmit => 'അപേക്ഷ അയയ്ക്കുക';

  @override
  String get invRequestSent => 'അംഗീകാരത്തിന് അപേക്ഷ അയച്ചു';

  @override
  String get invRequestsEmpty => 'സാമഗ്രി അപേക്ഷകളില്ല';

  @override
  String get invMineFilter => 'എന്റേത്';

  @override
  String get invToDecide => 'തീരുമാനിക്കാനുള്ളവ';

  @override
  String get invAllFilter => 'എല്ലാം';

  @override
  String get invRequestDetail => 'സാമഗ്രി അപേക്ഷ';

  @override
  String get invRequestedBy => 'അപേക്ഷിച്ചത്';

  @override
  String get invDecidedBy => 'തീരുമാനിച്ചത്';

  @override
  String get invCancelRequest => 'അപേക്ഷ റദ്ദാക്കുക';

  @override
  String get invCancelConfirm => 'ഈ അപേക്ഷ റദ്ദാക്കണോ?';

  @override
  String get invLedger => 'സ്റ്റോക്ക് നീക്കങ്ങൾ';

  @override
  String get invLedgerEmpty => 'ഇതുവരെ നീക്കങ്ങളില്ല';

  @override
  String get invAdjust => 'സ്റ്റോക്ക് ക്രമീകരിക്കുക';

  @override
  String get invAdjustHelp =>
      'ചേർക്കാൻ പോസിറ്റീവ്, കുറയ്ക്കാൻ നെഗറ്റീവ് സംഖ്യ ഉപയോഗിക്കുക (ഭൗതിക എണ്ണം തിരുത്തൽ).';

  @override
  String get invScrap => 'സ്ക്രാപ്പ് ആയി രേഖപ്പെടുത്തുക';

  @override
  String get invTransfer => 'മാറ്റുക';

  @override
  String get invFromStore => 'ഏത് സ്റ്റോറിൽ നിന്ന്';

  @override
  String get invToStore => 'ഏത് സ്റ്റോറിലേക്ക്';

  @override
  String get invCatalog => 'സാമഗ്രി പട്ടിക';

  @override
  String get invAddMaterial => 'സാമഗ്രി ചേർക്കുക';

  @override
  String get invCode => 'കോഡ്';

  @override
  String get invName => 'പേര്';

  @override
  String get invCategory => 'വിഭാഗം';

  @override
  String get invUnit => 'യൂണിറ്റ്';

  @override
  String get invHsn => 'HSN കോഡ്';

  @override
  String get invReorderLevel => 'റീഓർഡർ നില';

  @override
  String get invStores => 'സ്റ്റോറുകൾ';

  @override
  String get invAddStore => 'സ്റ്റോർ ചേർക്കുക';

  @override
  String get invStoreName => 'സ്റ്റോറിന്റെ പേര്';

  @override
  String get invMaterialsUsed => 'സാമഗ്രികൾ';

  @override
  String get invMaterialsUsedEmpty => 'ഈ ജോലിക്ക് ഇതുവരെ സാമഗ്രി നൽകിയിട്ടില്ല';

  @override
  String invIssued(String qty) {
    return 'നൽകിയത് $qty';
  }

  @override
  String invReturned(String qty) {
    return 'തിരികെ $qty';
  }

  @override
  String get invRequestForJob => 'സാമഗ്രി ആവശ്യപ്പെടുക';

  @override
  String get invExportRegister => 'സ്റ്റോക്ക് രജിസ്റ്റർ';

  @override
  String get invTxnReceipt => 'രസീത്';

  @override
  String get invTxnIssue => 'ഇഷ്യൂ';

  @override
  String get invTxnReturn => 'റിട്ടേൺ';

  @override
  String get invTxnAdjustment => 'ക്രമീകരണം';

  @override
  String get invTxnTransferIn => 'മാറ്റി വന്നത്';

  @override
  String get invTxnTransferOut => 'മാറ്റി അയച്ചത്';

  @override
  String get invTxnScrap => 'സ്ക്രാപ്പ്';

  @override
  String get regSection => 'ഫീൽഡ് രജിസ്റ്ററുകൾ';

  @override
  String get openInMaps => 'മാപ്പിൽ തുറക്കുക';

  @override
  String get poleTitle => 'പോൾവാർ';

  @override
  String get poleNew => 'പോസ്റ്റ് രേഖപ്പെടുത്തുക';

  @override
  String get poleSearch => 'പോസ്റ്റ് നമ്പറോ ഫീഡറോ തിരയുക';

  @override
  String get poleEmpty => 'പോസ്റ്റുകൾ രേഖപ്പെടുത്തിയിട്ടില്ല';

  @override
  String get poleEmptyHint =>
      'സ്ഥലത്ത് വെച്ച് സർവേ ചെയ്യുക; ഓഫ്‌ലൈനിൽ ചേർത്തവ പിന്നീട് സിങ്ക് ആകും.';

  @override
  String get poleNumber => 'പോസ്റ്റ് നമ്പർ';

  @override
  String get poleFeeder => 'ഫീഡറിന്റെ പേര്';

  @override
  String get poleTransformer => 'ട്രാൻസ്‌ഫോർമർ / DP റഫറൻസ്';

  @override
  String get poleType => 'പോസ്റ്റിന്റെ തരം';

  @override
  String get poleTypePsc => 'PSC';

  @override
  String get poleTypeRcc => 'RCC';

  @override
  String get poleTypeSteel => 'സ്റ്റീൽ ട്യൂബുലാർ';

  @override
  String get poleTypeRail => 'റെയിൽ പോസ്റ്റ്';

  @override
  String get poleTypeWooden => 'മരം';

  @override
  String get poleTypeOther => 'മറ്റുള്ളവ';

  @override
  String get poleHeight => 'ഉയരം (മീ)';

  @override
  String get poleLandmark => 'അടയാളം';

  @override
  String get poleCondition => 'അവസ്ഥ';

  @override
  String get poleCondGood => 'നല്ലത്';

  @override
  String get poleCondLeaning => 'ചരിഞ്ഞത്';

  @override
  String get poleCondDamaged => 'കേടായത്';

  @override
  String get poleCondReplaced => 'മാറ്റിസ്ഥാപിച്ചു';

  @override
  String get poleRemarks => 'കുറിപ്പ്';

  @override
  String get poleGpsRequired => 'പോസ്റ്റിന്റെ GPS സ്ഥാനം രേഖപ്പെടുത്തുക';

  @override
  String get poleSaved => 'പോസ്റ്റ് രേഖപ്പെടുത്തി';

  @override
  String get poleDuplicate => 'ഈ സെക്ഷനിൽ ഈ പോസ്റ്റ് നമ്പർ നിലവിലുണ്ട്';

  @override
  String get assetTitle => 'ആസ്തികൾ';

  @override
  String get assetNew => 'ആസ്തി രജിസ്റ്റർ ചെയ്യുക';

  @override
  String get assetSearch => 'ടാഗ്, പേര് അല്ലെങ്കിൽ സീരിയൽ നമ്പർ തിരയുക';

  @override
  String get assetEmpty => 'ആസ്തികൾ രജിസ്റ്റർ ചെയ്തിട്ടില്ല';

  @override
  String get assetTag => 'ആസ്തി ടാഗ്';

  @override
  String get assetName => 'പേര് / വിവരണം';

  @override
  String get assetCategory => 'വിഭാഗം';

  @override
  String get assetCatTransformer => 'ട്രാൻസ്‌ഫോർമർ';

  @override
  String get assetCatPole => 'പോസ്റ്റ്';

  @override
  String get assetCatConductor => 'കണ്ടക്ടർ';

  @override
  String get assetCatMeter => 'മീറ്റർ';

  @override
  String get assetCatTool => 'ഉപകരണം';

  @override
  String get assetCatVehicle => 'വാഹനം';

  @override
  String get assetCatOther => 'മറ്റുള്ളവ';

  @override
  String get assetSerial => 'സീരിയൽ നമ്പർ';

  @override
  String get assetMake => 'നിർമ്മാതാവ്';

  @override
  String get assetRating => 'റേറ്റിംഗ് (ഉദാ. 100 kVA)';

  @override
  String get assetLocation => 'സ്ഥലം';

  @override
  String get assetPurchaseDate => 'വാങ്ങിയ തീയതി';

  @override
  String get assetPurchaseValue => 'വാങ്ങിയ വില (₹)';

  @override
  String get assetCondition => 'അവസ്ഥ';

  @override
  String get assetCondNew => 'പുതിയത്';

  @override
  String get assetCondGood => 'നല്ലത്';

  @override
  String get assetCondFair => 'തരക്കേടില്ല';

  @override
  String get assetCondPoor => 'മോശം';

  @override
  String get assetCondUnserviceable => 'ഉപയോഗശൂന്യം';

  @override
  String get assetStatus => 'നില';

  @override
  String get assetStatusInStore => 'സ്റ്റോറിൽ';

  @override
  String get assetStatusDeployed => 'സ്ഥാപിച്ചു';

  @override
  String get assetStatusUnderRepair => 'അറ്റകുറ്റപ്പണിയിൽ';

  @override
  String get assetStatusScrapped => 'സ്ക്രാപ്പ് ചെയ്തു';

  @override
  String get assetStatusLost => 'നഷ്ടപ്പെട്ടു';

  @override
  String get assetAssignedTo => 'ആർക്ക് നൽകി';

  @override
  String get assetUnassigned => 'ആർക്കും നൽകിയിട്ടില്ല';

  @override
  String get assetNotes => 'കുറിപ്പുകൾ';

  @override
  String get assetHistory => 'ചരിത്രം';

  @override
  String get assetEvAssign => 'നൽകുക';

  @override
  String get assetEvMove => 'സെക്ഷനിലേക്ക് മാറ്റുക';

  @override
  String get assetEvInspect => 'പരിശോധന രേഖപ്പെടുത്തുക';

  @override
  String get assetEvRepair => 'അറ്റകുറ്റപ്പണി രേഖപ്പെടുത്തുക';

  @override
  String get assetEvStatus => 'നില മാറ്റുക';

  @override
  String get assetEvScrap => 'സ്ക്രാപ്പ്';

  @override
  String get assetEvCreated => 'രജിസ്റ്റർ ചെയ്തു';

  @override
  String get assetEvAssigned => 'നൽകി';

  @override
  String get assetEvMoved => 'മാറ്റി';

  @override
  String get assetEvInspected => 'പരിശോധിച്ചു';

  @override
  String get assetEvRepaired => 'അറ്റകുറ്റപ്പണി ചെയ്തു';

  @override
  String get assetEvStatusChanged => 'നില മാറ്റി';

  @override
  String get assetEvScrapped => 'സ്ക്രാപ്പ് ചെയ്തു';

  @override
  String get assetScrapConfirm =>
      'ഈ ആസ്തി സ്ക്രാപ്പ് ചെയ്യണോ? ഇത് സ്ഥിരമായി രേഖപ്പെടുത്തും.';

  @override
  String get assetNote => 'കുറിപ്പ്';

  @override
  String get comTitle => 'വാണിജ്യം';

  @override
  String get comOverview => 'സംഗ്രഹം';

  @override
  String get comSearch => 'ടെൻഡർ, വർക്ക് ഓർഡർ, ഇൻവോയ്സ്, കത്തുകൾ തിരയുക';

  @override
  String get comNoResults => 'പൊരുത്തപ്പെടുന്ന രേഖകളില്ല';

  @override
  String get comExpiringSoon => 'ഉടൻ കാലാവധി തീരുന്ന നിക്ഷേപങ്ങൾ';

  @override
  String get comNothingExpiring =>
      'അടുത്ത 30 ദിവസത്തിൽ കാലാവധി തീരുന്ന നിക്ഷേപങ്ങളില്ല';

  @override
  String get comAgeing => 'ലഭിക്കാനുള്ള തുകയുടെ പഴക്കം';

  @override
  String comDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ദിവസം ബാക്കി',
      one: '1 ദിവസം ബാക്കി',
      zero: 'ഇന്ന് കാലാവധി തീരും',
    );
    return '$_temp0';
  }

  @override
  String get comNew => 'ചേർക്കുക';

  @override
  String get comEmpty => 'ഇതുവരെ ഒന്നും രേഖപ്പെടുത്തിയിട്ടില്ല';

  @override
  String get comExportXlsx => 'Excel എക്സ്പോർട്ട്';

  @override
  String get comExportPdf => 'PDF എക്സ്പോർട്ട്';

  @override
  String get comLinked => 'ബന്ധപ്പെട്ട രേഖകൾ';

  @override
  String get comDocuments => 'രേഖകൾ';

  @override
  String get comAttachPdf => 'PDF ചേർക്കുക';

  @override
  String get comNoDocuments => 'രേഖകൾ ചേർത്തിട്ടില്ല';

  @override
  String get comReadOnly =>
      'കാണാൻ മാത്രം — മാറ്റങ്ങൾ വരുത്തുന്നത് സി.ഒ.ഒ അല്ലെങ്കിൽ ഡയറക്ടർ';

  @override
  String get comAll => 'എല്ലാം';

  @override
  String get entTenders => 'ടെൻഡറുകൾ';

  @override
  String get entDeposits => 'EMD / SD / BG';

  @override
  String get entWorkOrders => 'വർക്ക് ഓർഡറുകൾ';

  @override
  String get entBills => 'ബില്ലുകൾ / ഇൻവോയ്സുകൾ';

  @override
  String get entLetters => 'ഡിസ്പാച്ച് / കത്തുകൾ';

  @override
  String get entGst => 'GST റിട്ടേണുകൾ';

  @override
  String get fReference => 'ടെൻഡർ / ജോലി റഫറൻസ്';

  @override
  String get fTitle => 'തലക്കെട്ട്';

  @override
  String get fTenderType => 'ടെൻഡർ തരം';

  @override
  String get fWorkCategory => 'ജോലി വിഭാഗം';

  @override
  String get fDepartment => 'വകുപ്പ്';

  @override
  String get fSection => 'സെക്ഷൻ ഓഫീസ്';

  @override
  String get fLocation => 'സ്ഥലം';

  @override
  String get fNoticeDate => 'നോട്ടീസ് തീയതി';

  @override
  String get fSubmissionDeadline => 'സമർപ്പിക്കേണ്ട അവസാന സമയം';

  @override
  String get fOpeningDate => 'തുറക്കുന്ന തീയതി';

  @override
  String get fWorkStartDate => 'ജോലി തുടങ്ങുന്ന തീയതി';

  @override
  String get fEstimate => 'എസ്റ്റിമേറ്റ് തുക';

  @override
  String get fEmd => 'EMD തുക';

  @override
  String get fSecurityDeposit => 'സെക്യൂരിറ്റി ഡെപ്പോസിറ്റ്';

  @override
  String get fQuoted => 'ക്വോട്ട് ചെയ്ത തുക';

  @override
  String get fContactPerson => 'ബന്ധപ്പെടേണ്ടയാൾ';

  @override
  String get fContactPhone => 'ബന്ധപ്പെടേണ്ട ഫോൺ';

  @override
  String get fRemarks => 'കുറിപ്പ്';

  @override
  String get fStatus => 'നില';

  @override
  String get fKind => 'തരം';

  @override
  String get fTender => 'ടെൻഡർ';

  @override
  String get fWorkOrder => 'വർക്ക് ഓർഡർ';

  @override
  String get fAmount => 'തുക';

  @override
  String get fPaymentMode => 'പണമടച്ച രീതി';

  @override
  String get fInstrumentNo => 'DD / BG / UTR നമ്പർ';

  @override
  String get fBank => 'ബാങ്ക്';

  @override
  String get fDepositDate => 'നിക്ഷേപിച്ച തീയതി';

  @override
  String get fValidityDate => 'സാധുത വരെ';

  @override
  String get fReleasedOn => 'തിരികെ ലഭിച്ചത്';

  @override
  String get fWoNumber => 'വർക്ക് ഓർഡർ നമ്പർ';

  @override
  String get fAgreementNo => 'കരാർ നമ്പർ';

  @override
  String get fAwardedAmount => 'അനുവദിച്ച തുക';

  @override
  String get fIssueDate => 'നൽകിയ തീയതി';

  @override
  String get fDueDate => 'പൂർത്തിയാക്കേണ്ട തീയതി';

  @override
  String get fInvoiceNo => 'ഇൻവോയ്സ് നമ്പർ';

  @override
  String get fBillType => 'ബിൽ തരം';

  @override
  String get fInvoiceDate => 'ഇൻവോയ്സ് തീയതി';

  @override
  String get fTaxAmount => 'നികുതി (GST) തുക';

  @override
  String get fPassedAmount => 'പാസാക്കിയ തുക';

  @override
  String get fPaidAmount => 'ലഭിച്ച തുക';

  @override
  String get fPaidOn => 'ലഭിച്ച തീയതി';

  @override
  String get fRefNo => 'റഫറൻസ് നമ്പർ';

  @override
  String get fDirection => 'വന്നത് / അയച്ചത്';

  @override
  String get fDocType => 'രേഖയുടെ തരം';

  @override
  String get fParty => 'അയച്ചയാൾ / ലഭിക്കുന്നയാൾ';

  @override
  String get fSubject => 'വിഷയം';

  @override
  String get fDocDate => 'തീയതി';

  @override
  String get fGstin => 'GSTIN';

  @override
  String get fLegalName => 'നിയമപരമായ പേര്';

  @override
  String get fReturnType => 'റിട്ടേൺ തരം';

  @override
  String get fPeriod => 'റിട്ടേൺ കാലയളവ് (മാസം)';

  @override
  String get fTaxable => 'നികുതി ബാധകമായ മൂല്യം';

  @override
  String get fCgst => 'CGST';

  @override
  String get fSgst => 'SGST';

  @override
  String get fIgst => 'IGST';

  @override
  String get fFiledOn => 'ഫയൽ ചെയ്തത്';

  @override
  String get fArn => 'ARN';

  @override
  String get fGstinInvalid => 'ശരിയായ 15 അക്ക GSTIN നൽകുക';

  @override
  String get fAmountInvalid => 'ശരിയായ തുക നൽകുക';

  @override
  String get optNone => '—';

  @override
  String get optTenderDraft => 'ഡ്രാഫ്റ്റ്';

  @override
  String get optTenderSubmitted => 'സമർപ്പിച്ചു';

  @override
  String get optTenderOpened => 'തുറന്നു';

  @override
  String get optTenderAwarded => 'ലഭിച്ചു';

  @override
  String get optTenderLost => 'ലഭിച്ചില്ല';

  @override
  String get optTenderCancelled => 'റദ്ദാക്കി';

  @override
  String get optDepEmd => 'EMD';

  @override
  String get optDepSd => 'സെക്യൂരിറ്റി ഡെപ്പോസിറ്റ്';

  @override
  String get optDepBg => 'ബാങ്ക് ഗ്യാരന്റി';

  @override
  String get optDepRetention => 'റിട്ടൻഷൻ';

  @override
  String get optDepHeld => 'കെട്ടിവെച്ചത്';

  @override
  String get optDepRefundRequested => 'തിരികെ ആവശ്യപ്പെട്ടു';

  @override
  String get optDepReleased => 'തിരികെ ലഭിച്ചു';

  @override
  String get optDepForfeited => 'കണ്ടുകെട്ടി';

  @override
  String get optModeDd => 'ഡിമാൻഡ് ഡ്രാഫ്റ്റ്';

  @override
  String get optModeBg => 'ബാങ്ക് ഗ്യാരന്റി';

  @override
  String get optModeOnline => 'ഓൺലൈൻ';

  @override
  String get optModeFdr => 'FDR';

  @override
  String get optModeCash => 'പണം';

  @override
  String get optModeOther => 'മറ്റുള്ളവ';

  @override
  String get optWoAwarded => 'ലഭിച്ചു';

  @override
  String get optWoInProgress => 'പുരോഗമിക്കുന്നു';

  @override
  String get optWoCompleted => 'പൂർത്തിയായി';

  @override
  String get optWoClosed => 'അവസാനിപ്പിച്ചു';

  @override
  String get optWoTerminated => 'റദ്ദാക്കി';

  @override
  String get optBillRa => 'റണ്ണിംഗ് അക്കൗണ്ട് (RA)';

  @override
  String get optBillFinal => 'ഫൈനൽ';

  @override
  String get optBillAdvance => 'അഡ്വാൻസ്';

  @override
  String get optBillOther => 'മറ്റുള്ളവ';

  @override
  String get optBillSubmitted => 'സമർപ്പിച്ചു';

  @override
  String get optBillPassed => 'പാസാക്കി';

  @override
  String get optBillPartiallyPaid => 'ഭാഗികമായി ലഭിച്ചു';

  @override
  String get optBillPaid => 'ലഭിച്ചു';

  @override
  String get optBillRejected => 'നിരസിച്ചു';

  @override
  String get optDirIn => 'ലഭിച്ചത്';

  @override
  String get optDirOut => 'അയച്ചത്';

  @override
  String get optDocLetter => 'കത്ത്';

  @override
  String get optDocNotice => 'നോട്ടീസ്';

  @override
  String get optDocCircular => 'സർക്കുലർ';

  @override
  String get optDocWorkOrder => 'വർക്ക് ഓർഡർ';

  @override
  String get optDocOther => 'മറ്റുള്ളവ';

  @override
  String get comPdfTooLarge => 'ഈ PDF 10 MB-യിൽ കൂടുതലാണ്.';

  @override
  String get notifTitle => 'അറിയിപ്പുകൾ';

  @override
  String get notifEmpty => 'പുതിയ അറിയിപ്പുകളില്ല';

  @override
  String get notifMarkAll => 'എല്ലാം വായിച്ചതായി അടയാളപ്പെടുത്തുക';

  @override
  String get notifChannelName => 'AumLux അപ്ഡേറ്റുകൾ';

  @override
  String get notifChannelDescription =>
      'അംഗീകാരങ്ങൾ, മുന്നറിയിപ്പുകൾ, ഓർമ്മപ്പെടുത്തലുകൾ';

  @override
  String get bonusTitle => 'ബോണസ്';

  @override
  String get bonusMyTotal => 'എനിക്ക് അംഗീകരിച്ച ബോണസ്';

  @override
  String get bonusPoints => 'പോയിന്റുകൾ';

  @override
  String get bonusAmount => 'തുക';

  @override
  String get bonusPropose => 'ബോണസ് ശുപാർശ ചെയ്യുക';

  @override
  String get bonusFor => 'ആർക്ക്';

  @override
  String get bonusReason => 'കാരണം';

  @override
  String get bonusReasonHint =>
      'ഉദാ. കൊടുങ്കാറ്റിന് ശേഷമുള്ള പുനഃസ്ഥാപന ഓവർടൈം, ഒക്ടോ 14–15';

  @override
  String get bonusNeedValue => 'പോയിന്റോ തുകയോ നൽകുക';

  @override
  String get bonusProposed => 'അംഗീകാരത്തിനായി ബോണസ് ശുപാർശ ചെയ്തു';

  @override
  String get bonusEmpty => 'ഇതുവരെ ബോണസ് രേഖകളില്ല';

  @override
  String get bonusPendingNote =>
      'ബോണസ് അംഗീകരിക്കുന്നത് സി.ഒ.ഒ അല്ലെങ്കിൽ ഡയറക്ടർ ആണ്.';

  @override
  String get locRationaleTitle => 'AumLux-ന് നിങ്ങളുടെ സ്ഥാനം എന്തിന്';

  @override
  String get locRationaleBody =>
      'ചെക്ക് ഇൻ/ഔട്ട് ചെയ്യുമ്പോഴോ സൈറ്റ് ഫോട്ടോ/പോസ്റ്റ് രേഖപ്പെടുത്തുമ്പോഴോ മാത്രമാണ് സ്ഥാനം രേഖപ്പെടുത്തുന്നത്. പശ്ചാത്തലത്തിൽ ഒരിക്കലും ട്രാക്ക് ചെയ്യുന്നില്ല.';

  @override
  String get updateTitle => 'അപ്ഡേറ്റ് ആവശ്യമാണ്';

  @override
  String get updateBody =>
      'AumLux-ന്റെ ഈ പതിപ്പ് ഇനി പിന്തുണയ്ക്കുന്നില്ല. തുടരാൻ പുതിയ പതിപ്പ് ഇൻസ്റ്റാൾ ചെയ്യുക — സേവ് ചെയ്ത വിവരങ്ങൾ നഷ്ടപ്പെടില്ല.';

  @override
  String get updateButton => 'അപ്ഡേറ്റ് ഡൗൺലോഡ് ചെയ്യുക';

  @override
  String get homeShortcuts => 'കുറുക്കുവഴികൾ';

  @override
  String homeOnDuty(String duration) {
    return 'ഡ്യൂട്ടിയിൽ · $duration';
  }

  @override
  String homeWorked(String duration) {
    return 'ജോലി ചെയ്തത് $duration';
  }

  @override
  String get commonClear => 'മായ്ക്കുക';

  @override
  String get commonSearch => 'തിരയുക';

  @override
  String get orgChooseSection => 'സെക്ഷൻ തിരഞ്ഞെടുക്കുക';

  @override
  String get orgSearchSections => 'സെക്ഷൻ, കോഡ് അല്ലെങ്കിൽ സ്ഥലം തിരയുക';

  @override
  String get orgAllCircles => 'എല്ലാ സർക്കിളുകളും';

  @override
  String orgSectionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count സെക്ഷനുകൾ',
      one: '1 സെക്ഷൻ',
    );
    return '$_temp0';
  }

  @override
  String get orgNoSectionsFound => 'പൊരുത്തപ്പെടുന്ന സെക്ഷനുകളില്ല';

  @override
  String get staffCodeAutoHelper => 'അടുത്ത ലഭ്യമായ ഐഡി — സ്വയം നൽകുന്നു';

  @override
  String get staffCodeUseCustom => 'സ്വന്തം ഐഡി ഉപയോഗിക്കുക';

  @override
  String get staffCodeUseAuto => 'സ്വയം സൃഷ്ടിക്കുക';

  @override
  String get mapTitle => 'മാപ്പ്';

  @override
  String get mapExpand => 'മുഴുവൻ മാപ്പ് തുറക്കുക';

  @override
  String get mapPoint => 'സ്ഥലം';

  @override
  String get mapOpenExternal => 'വഴി';

  @override
  String get mapMyLocation => 'എന്റെ സ്ഥലം';

  @override
  String get mapDragHint => 'പിൻ സ്ഥാപിക്കാൻ മാപ്പ് നീക്കുക';

  @override
  String mapMeters(int meters) {
    return '$meters മീ';
  }

  @override
  String get mapUseThisLocation => 'ഈ സ്ഥലം ഉപയോഗിക്കുക';

  @override
  String get mapSetOnMap => 'മാപ്പിൽ സജ്ജമാക്കുക';

  @override
  String get mapChangeOnMap => 'മാപ്പിൽ മാറ്റുക';

  @override
  String get mapNoLocation => 'സ്ഥലം നൽകിയിട്ടില്ല';

  @override
  String get attCheckInPoint => 'ചെക്ക്-ഇൻ';

  @override
  String get attCheckOutPoint => 'ചെക്ക്-ഔട്ട്';

  @override
  String get attWhereTitle => 'നിങ്ങൾ ചെക്ക്-ഇൻ ചെയ്ത സ്ഥലം';

  @override
  String attDistanceFromSection(int meters) {
    return 'സെക്ഷൻ ഓഫീസിൽ നിന്ന് $meters മീ';
  }

  @override
  String get attInsideGeofence => 'ജിയോഫെൻസിനുള്ളിൽ';

  @override
  String get attOutsideGeofence => 'ജിയോഫെൻസിന് പുറത്ത്';

  @override
  String get attMockedLocation => 'വ്യാജ ലൊക്കേഷൻ കണ്ടെത്തി';

  @override
  String get attNoGps => 'ജിപിഎസ് ഇല്ല';

  @override
  String attAccuracy(int meters) {
    return '±$meters മീ കൃത്യത';
  }

  @override
  String get attViewList => 'പട്ടിക';

  @override
  String get attViewMap => 'മാപ്പ്';

  @override
  String get attMapEmpty => 'ഈ ദിവസം ജിപിഎസ് ഉള്ള ചെക്ക്-ഇന്നുകളില്ല';

  @override
  String photoTakenAt(String time) {
    return 'എടുത്തത് $time';
  }

  @override
  String get photoNoLocation =>
      'ഈ ഫോട്ടോയ്ക്ക് ജിപിഎസ് ലൊക്കേഷൻ രേഖപ്പെടുത്തിയിട്ടില്ല';

  @override
  String get photoUploading => 'അപ്‌ലോഡ് ചെയ്യുന്നു';

  @override
  String get photoWaiting => 'കാത്തിരിക്കുന്നു';

  @override
  String get photoRecovered =>
      'ആപ്പ് അടയുന്നതിന് മുമ്പ് എടുത്ത ഫോട്ടോ വീണ്ടെടുത്തു';

  @override
  String get photoGpsTagged => 'ജിപിഎസ് ടാഗ് ചെയ്തു';

  @override
  String get wsMapLocation => 'പ്രവൃത്തി സ്ഥലം';

  @override
  String get poleMapLocation => 'പോസ്റ്റിന്റെ സ്ഥലം';

  @override
  String get commonDetails => 'വിശദാംശങ്ങൾ';

  @override
  String get invValue => 'മൂല്യം';

  @override
  String get commonOpen => 'തുറക്കുക';

  @override
  String get moreApp => 'ആപ്പ്';

  @override
  String get orgCountCircles => 'സർക്കിളുകൾ';

  @override
  String get orgCountDivisions => 'ഡിവിഷനുകൾ';

  @override
  String get orgCountSubdivisions => 'സബ് ഡിവിഷനുകൾ';

  @override
  String get orgCountSections => 'സെക്ഷനുകൾ';

  @override
  String get orgSearchUnits => 'സർക്കിൾ, ഡിവിഷൻ അല്ലെങ്കിൽ സെക്ഷൻ തിരയുക';

  @override
  String orgSectionsWithoutLocation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count സെക്ഷനുകൾക്ക് ഓഫീസ് സ്ഥലം നൽകിയിട്ടില്ല — അവിടെ ഹാജറിന് ജിയോഫെൻസ് ഇല്ല',
      one: '1 സെക്ഷന് ഓഫീസ് സ്ഥലം നൽകിയിട്ടില്ല — അവിടെ ഹാജറിന് ജിയോഫെൻസ് ഇല്ല',
    );
    return '$_temp0';
  }

  @override
  String get comRegisters => 'രജിസ്റ്ററുകൾ';

  @override
  String get comOutstanding => 'ലഭിക്കാനുള്ള തുക';

  @override
  String comUnpaidBills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count അടയ്ക്കാത്ത ബില്ലുകളിൽ',
      one: '1 അടയ്ക്കാത്ത ബില്ലിൽ',
      zero: 'അടയ്ക്കാത്ത ബില്ലുകളില്ല',
    );
    return '$_temp0';
  }

  @override
  String comAgeingDays(String range) {
    return '$range ദിവസം';
  }

  @override
  String get comOverdue90 => '90 ദിവസത്തിലധികം';

  @override
  String get comDaysShort => 'ദിവസം';

  @override
  String get orgOfficeLocation => 'ഓഫീസ് സ്ഥലം';
}
