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
}
