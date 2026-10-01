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

  @override
  String get exportTitle => 'Your file is ready';

  @override
  String get exportOpen => 'Open';

  @override
  String get exportShare => 'Share';

  @override
  String get exportCancelled => 'Export cancelled.';

  @override
  String get exportNoApp => 'No app found to open this file.';

  @override
  String get attMe => 'Me';

  @override
  String get attTeam => 'Team';

  @override
  String get attCheckIn => 'Check in';

  @override
  String get attCheckOut => 'Check out';

  @override
  String get attCheckedIn => 'Checked in';

  @override
  String get attCheckedOut => 'Checked out';

  @override
  String get attDoneForDay => 'Day complete';

  @override
  String attWorked(String duration) {
    return 'Worked $duration';
  }

  @override
  String get attLocating => 'Getting your location…';

  @override
  String get attSynced => 'Attendance recorded';

  @override
  String get attQueued =>
      'Saved on your phone. It will sync when you\'re back online.';

  @override
  String get attPendingSync => 'Waiting to sync';

  @override
  String get attNoLocationTitle => 'Location unavailable';

  @override
  String get attNoLocationContinue => 'Record without location';

  @override
  String get attNoLocationNote =>
      'Your supervisor will see that this entry has no location.';

  @override
  String get attOpenSettings => 'Open settings';

  @override
  String get attThisMonth => 'This month';

  @override
  String get attDaysPresent => 'Days present';

  @override
  String get attHoursWorked => 'Hours worked';

  @override
  String get attLeaveDays => 'Leave days';

  @override
  String get attHistory => 'History';

  @override
  String get attNoRecords => 'No attendance yet this month';

  @override
  String get attStatusPresent => 'Present';

  @override
  String get attStatusAbsent => 'Absent';

  @override
  String get attStatusLeave => 'Leave';

  @override
  String get attStatusHalfDay => 'Half day';

  @override
  String get attStatusHoliday => 'Holiday';

  @override
  String get attNotMarked => 'Not marked';

  @override
  String get attFlagOutside => 'Outside area';

  @override
  String get attFlagMocked => 'Mock location';

  @override
  String get attFlagNoLocation => 'No location';

  @override
  String get attVerified => 'Verified';

  @override
  String attVerifySelected(int count) {
    return 'Verify $count';
  }

  @override
  String attVerifiedCount(int count) {
    return '$count verified';
  }

  @override
  String get attMark => 'Mark attendance';

  @override
  String get attCorrect => 'Correct record';

  @override
  String get attReason => 'Reason';

  @override
  String get attReasonHint => 'e.g. Worked at substation, phone had no signal';

  @override
  String get attReasonTooShort => 'Give a reason (at least 5 characters)';

  @override
  String get attTeamEmpty => 'No one reports to you yet';

  @override
  String attSummaryLine(int present, int absent, int unmarked) {
    return '$present present · $absent absent · $unmarked not marked';
  }

  @override
  String get attExportMuster => 'Muster roll';

  @override
  String attMusterTitle(String month) {
    return 'Muster roll — $month';
  }

  @override
  String get attExportPdf => 'Download PDF';

  @override
  String get attExportXlsx => 'Download Excel';

  @override
  String get attSelectSection => 'All my sections';

  @override
  String get leaveTitle => 'Leave';

  @override
  String get leaveMine => 'My leave';

  @override
  String get leaveRequest => 'Request leave';

  @override
  String get leaveFrom => 'From';

  @override
  String get leaveTo => 'To';

  @override
  String get leaveType => 'Type';

  @override
  String get leaveTypeCasual => 'Casual';

  @override
  String get leaveTypeSick => 'Sick';

  @override
  String get leaveTypeEarned => 'Earned';

  @override
  String get leaveTypeUnpaid => 'Unpaid';

  @override
  String get leaveTypeOther => 'Other';

  @override
  String get leaveReason => 'Reason';

  @override
  String get leaveSubmit => 'Send request';

  @override
  String get leaveSent => 'Leave request sent';

  @override
  String get leaveEmpty => 'No leave requests';

  @override
  String get leaveCancel => 'Cancel request';

  @override
  String leaveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get leaveDateOrder => 'End date can\'t be before start date';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get approvalsTitle => 'Approvals';

  @override
  String get approvalsEmpty => 'Nothing waiting for you';

  @override
  String get approvalsEmptyHint => 'Requests from your team appear here.';

  @override
  String get approvalsApprove => 'Approve';

  @override
  String get approvalsReject => 'Reject';

  @override
  String get approvalsRejectReason => 'Reason for rejecting';

  @override
  String get approvalsDone => 'Done';

  @override
  String get approvalsKindLeave => 'Leave';

  @override
  String get approvalsKindWorksheet => 'Worksheet';

  @override
  String get approvalsKindMaterial => 'Material';

  @override
  String get approvalsKindBonus => 'Bonus';

  @override
  String get approvalsOpen => 'Open';

  @override
  String get holidaysTitle => 'Holidays';

  @override
  String get holidaysAdd => 'Add holiday';

  @override
  String get holidaysName => 'Holiday name';

  @override
  String get holidaysDate => 'Date';

  @override
  String holidaysEmpty(int year) {
    return 'No holidays added for $year';
  }

  @override
  String get holidaysNote =>
      'Add lunar-calendar holidays (Vishu, Onam, Eid, Deepavali…) each year from the Kerala Government notification.';

  @override
  String holidaysDeleteConfirm(String name) {
    return 'Remove $name?';
  }

  @override
  String get commonDelete => 'Remove';

  @override
  String get commonDate => 'Date';

  @override
  String get wsTitle => 'Worksheets';

  @override
  String get wsNew => 'New worksheet';

  @override
  String get wsEdit => 'Edit worksheet';

  @override
  String get wsMine => 'Mine';

  @override
  String get wsSection => 'My sections';

  @override
  String get wsAllStatuses => 'All';

  @override
  String get wsEmpty => 'No worksheets yet';

  @override
  String get wsEmptyHint => 'Create a worksheet before starting a job.';

  @override
  String get wsType => 'Work type';

  @override
  String get wsTypeProject => 'Project';

  @override
  String get wsTypeMaintenance => 'Maintenance';

  @override
  String get wsTypeCalamity => 'Calamity / breakdown';

  @override
  String get wsJobTitle => 'Job title';

  @override
  String get wsJobTitleHint => 'e.g. Replace DP fuse at Kaloor junction';

  @override
  String get wsLocation => 'Location / landmark';

  @override
  String get wsUseGps => 'Use my location';

  @override
  String wsGpsSet(int accuracy) {
    return 'GPS saved (±$accuracy m)';
  }

  @override
  String get wsPermitBook => 'Permit book no.';

  @override
  String get wsDescription => 'Work description';

  @override
  String get wsPlannedDate => 'Planned date';

  @override
  String get wsSaveDraft => 'Save draft';

  @override
  String get wsSaveSubmit => 'Save & submit';

  @override
  String get wsSavedOffline =>
      'Saved on your phone. It will upload when you\'re back online.';

  @override
  String get wsSubmitted => 'Sent for approval';

  @override
  String get wsStatusDraft => 'Draft';

  @override
  String get wsStatusSubmitted => 'Waiting approval';

  @override
  String get wsStatusApproved => 'Approved';

  @override
  String get wsStatusRejected => 'Rejected';

  @override
  String get wsStatusInProgress => 'In progress';

  @override
  String get wsStatusCompleted => 'Completed';

  @override
  String get wsStatusCancelled => 'Cancelled';

  @override
  String get wsRequestedBy => 'Requested by';

  @override
  String get wsDecision => 'Decision note';

  @override
  String get wsActionSubmit => 'Submit for approval';

  @override
  String get wsActionApprove => 'Approve';

  @override
  String get wsActionReject => 'Reject';

  @override
  String get wsActionStart => 'Start work';

  @override
  String get wsActionComplete => 'Mark completed';

  @override
  String get wsActionCancel => 'Cancel worksheet';

  @override
  String get wsCompletionNote => 'What was done';

  @override
  String get wsCancelConfirm => 'Cancel this worksheet? It can\'t be reopened.';

  @override
  String get wsCrew => 'Crew';

  @override
  String get wsCrewEdit => 'Edit crew';

  @override
  String get wsCrewEmpty => 'No crew assigned';

  @override
  String get wsPhotos => 'Photos';

  @override
  String get wsAddPhoto => 'Add photo';

  @override
  String get wsCamera => 'Camera';

  @override
  String get wsGallery => 'Gallery';

  @override
  String get wsPhotosEmpty => 'No photos yet';

  @override
  String get wsPhotoQueued => 'Photo saved; it uploads when you\'re online.';

  @override
  String get wsPermit => 'Permit to work';

  @override
  String get wsPermitMissing =>
      'Not signed yet. Work can\'t start until a supervisor signs the permit.';

  @override
  String get wsPermitSign => 'Sign permit';

  @override
  String get wsPermitLcRef => 'Line clear (LC) reference';

  @override
  String get wsPermitLcBy => 'LC issued by (KSEB officer)';

  @override
  String get wsPermitIsolation => 'Isolation points';

  @override
  String get wsPermitIsolationHint =>
      'e.g. AB switch at DP-14 opened and locked';

  @override
  String get wsPermitEarthing => 'Earthing done on both sides';

  @override
  String get wsPermitTestedDead => 'Line tested dead with tester';

  @override
  String get wsPermitToolbox => 'Toolbox talk done with the crew';

  @override
  String get wsPermitPpe => 'PPE confirmed';

  @override
  String get wsPermitPpeRequired =>
      'Helmet, gloves and safety belt are mandatory';

  @override
  String wsPermitSignedBy(String when) {
    return 'Signed $when';
  }

  @override
  String get ppeHelmet => 'Helmet';

  @override
  String get ppeGloves => 'Insulated gloves';

  @override
  String get ppeSafetyBelt => 'Safety belt';

  @override
  String get ppeBoots => 'Safety boots';

  @override
  String get ppeInsulatedTools => 'Insulated tools';

  @override
  String get ppeReflectiveVest => 'Reflective vest';

  @override
  String get incTitle => 'Incidents';

  @override
  String get incReport => 'Report incident';

  @override
  String get incSeverity => 'Severity';

  @override
  String get incNearMiss => 'Near miss';

  @override
  String get incMinor => 'Minor injury / damage';

  @override
  String get incMajor => 'Major injury / damage';

  @override
  String get incFatal => 'Fatal';

  @override
  String get incOccurredAt => 'When';

  @override
  String get incDescription => 'What happened';

  @override
  String get incInjured => 'People injured (names)';

  @override
  String get incAction => 'Immediate action taken';

  @override
  String get incReported => 'Incident reported';

  @override
  String get incNone => 'No incidents';

  @override
  String get incStatusOpen => 'Open';

  @override
  String get incStatusInvestigating => 'Investigating';

  @override
  String get incStatusClosed => 'Closed';

  @override
  String get invTitle => 'Inventory';

  @override
  String get invStock => 'Stock';

  @override
  String get invRequests => 'Requests';

  @override
  String get invSearch => 'Search material or code';

  @override
  String get invAllStores => 'All stores';

  @override
  String get invLowOnly => 'Low stock only';

  @override
  String get invOnHand => 'On hand';

  @override
  String invReorderAt(String qty) {
    return 'Reorder at $qty';
  }

  @override
  String get invLow => 'Low';

  @override
  String get invNoStock => 'No stock recorded yet';

  @override
  String get invNoStockHint =>
      'Stock appears after the first approved receipt.';

  @override
  String get invNewRequest => 'New request';

  @override
  String get invReqIssue => 'Issue (take from store)';

  @override
  String get invReqReturn => 'Return (unused to store)';

  @override
  String get invReqReceipt => 'Receipt (new stock in)';

  @override
  String get invTypeIssue => 'Issue';

  @override
  String get invTypeReturn => 'Return';

  @override
  String get invTypeReceipt => 'Receipt';

  @override
  String get invStore => 'Store';

  @override
  String get invMaterial => 'Material';

  @override
  String get invQuantity => 'Quantity';

  @override
  String get invQtyInvalid => 'Enter a quantity above zero';

  @override
  String invAvailable(String qty) {
    return 'Available: $qty';
  }

  @override
  String get invUnitPrice => 'Unit price (₹)';

  @override
  String get invSupplier => 'Supplier';

  @override
  String get invInvoice => 'Invoice / DC no.';

  @override
  String get invWorksheet => 'For worksheet';

  @override
  String get invNoWorksheet => 'Not linked to a worksheet';

  @override
  String get invPurpose => 'Purpose';

  @override
  String get invPriority => 'Priority';

  @override
  String get invPriorityLow => 'Low';

  @override
  String get invPriorityMedium => 'Medium';

  @override
  String get invPriorityHigh => 'High';

  @override
  String get invPriorityCritical => 'Critical';

  @override
  String get invRequiredBy => 'Required by';

  @override
  String get invSubmit => 'Send request';

  @override
  String get invRequestSent => 'Request sent for approval';

  @override
  String get invRequestsEmpty => 'No material requests';

  @override
  String get invMineFilter => 'Mine';

  @override
  String get invToDecide => 'To decide';

  @override
  String get invAllFilter => 'All';

  @override
  String get invRequestDetail => 'Material request';

  @override
  String get invRequestedBy => 'Requested by';

  @override
  String get invDecidedBy => 'Decided by';

  @override
  String get invCancelRequest => 'Cancel request';

  @override
  String get invCancelConfirm => 'Cancel this request?';

  @override
  String get invLedger => 'Stock movements';

  @override
  String get invLedgerEmpty => 'No movements yet';

  @override
  String get invAdjust => 'Adjust stock';

  @override
  String get invAdjustHelp =>
      'Use a positive number to add, negative to remove (physical count correction).';

  @override
  String get invScrap => 'Record as scrap';

  @override
  String get invTransfer => 'Transfer';

  @override
  String get invFromStore => 'From store';

  @override
  String get invToStore => 'To store';

  @override
  String get invCatalog => 'Material catalogue';

  @override
  String get invAddMaterial => 'Add material';

  @override
  String get invCode => 'Code';

  @override
  String get invName => 'Name';

  @override
  String get invCategory => 'Category';

  @override
  String get invUnit => 'Unit';

  @override
  String get invHsn => 'HSN code';

  @override
  String get invReorderLevel => 'Reorder level';

  @override
  String get invStores => 'Stores';

  @override
  String get invAddStore => 'Add store';

  @override
  String get invStoreName => 'Store name';

  @override
  String get invMaterialsUsed => 'Materials';

  @override
  String get invMaterialsUsedEmpty => 'No materials issued for this job yet';

  @override
  String invIssued(String qty) {
    return 'Issued $qty';
  }

  @override
  String invReturned(String qty) {
    return 'Returned $qty';
  }

  @override
  String get invRequestForJob => 'Request material';

  @override
  String get invExportRegister => 'Stock register';

  @override
  String get invTxnReceipt => 'Receipt';

  @override
  String get invTxnIssue => 'Issue';

  @override
  String get invTxnReturn => 'Return';

  @override
  String get invTxnAdjustment => 'Adjustment';

  @override
  String get invTxnTransferIn => 'Transfer in';

  @override
  String get invTxnTransferOut => 'Transfer out';

  @override
  String get invTxnScrap => 'Scrap';

  @override
  String get regSection => 'Field registers';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get poleTitle => 'Polevar';

  @override
  String get poleNew => 'Record pole';

  @override
  String get poleSearch => 'Search pole no. or feeder';

  @override
  String get poleEmpty => 'No poles recorded';

  @override
  String get poleEmptyHint =>
      'Survey poles on site; entries made offline sync later.';

  @override
  String get poleNumber => 'Pole number';

  @override
  String get poleFeeder => 'Feeder name';

  @override
  String get poleTransformer => 'Transformer / DP reference';

  @override
  String get poleType => 'Pole type';

  @override
  String get poleTypePsc => 'PSC';

  @override
  String get poleTypeRcc => 'RCC';

  @override
  String get poleTypeSteel => 'Steel tubular';

  @override
  String get poleTypeRail => 'Rail pole';

  @override
  String get poleTypeWooden => 'Wooden';

  @override
  String get poleTypeOther => 'Other';

  @override
  String get poleHeight => 'Height (m)';

  @override
  String get poleLandmark => 'Landmark';

  @override
  String get poleCondition => 'Condition';

  @override
  String get poleCondGood => 'Good';

  @override
  String get poleCondLeaning => 'Leaning';

  @override
  String get poleCondDamaged => 'Damaged';

  @override
  String get poleCondReplaced => 'Replaced';

  @override
  String get poleRemarks => 'Remarks';

  @override
  String get poleGpsRequired => 'Capture the pole\'s GPS location';

  @override
  String get poleSaved => 'Pole recorded';

  @override
  String get poleDuplicate => 'This pole number already exists in this section';

  @override
  String get assetTitle => 'Assets';

  @override
  String get assetNew => 'Register asset';

  @override
  String get assetSearch => 'Search tag, name or serial no.';

  @override
  String get assetEmpty => 'No assets registered';

  @override
  String get assetTag => 'Asset tag';

  @override
  String get assetName => 'Name / description';

  @override
  String get assetCategory => 'Category';

  @override
  String get assetCatTransformer => 'Transformer';

  @override
  String get assetCatPole => 'Pole';

  @override
  String get assetCatConductor => 'Conductor';

  @override
  String get assetCatMeter => 'Meter';

  @override
  String get assetCatTool => 'Tool / equipment';

  @override
  String get assetCatVehicle => 'Vehicle';

  @override
  String get assetCatOther => 'Other';

  @override
  String get assetSerial => 'Serial number';

  @override
  String get assetMake => 'Make';

  @override
  String get assetRating => 'Rating (e.g. 100 kVA)';

  @override
  String get assetLocation => 'Location';

  @override
  String get assetPurchaseDate => 'Purchase date';

  @override
  String get assetPurchaseValue => 'Purchase value (₹)';

  @override
  String get assetCondition => 'Condition';

  @override
  String get assetCondNew => 'New';

  @override
  String get assetCondGood => 'Good';

  @override
  String get assetCondFair => 'Fair';

  @override
  String get assetCondPoor => 'Poor';

  @override
  String get assetCondUnserviceable => 'Unserviceable';

  @override
  String get assetStatus => 'Status';

  @override
  String get assetStatusInStore => 'In store';

  @override
  String get assetStatusDeployed => 'Deployed';

  @override
  String get assetStatusUnderRepair => 'Under repair';

  @override
  String get assetStatusScrapped => 'Scrapped';

  @override
  String get assetStatusLost => 'Lost';

  @override
  String get assetAssignedTo => 'Assigned to';

  @override
  String get assetUnassigned => 'Not assigned';

  @override
  String get assetNotes => 'Notes';

  @override
  String get assetHistory => 'History';

  @override
  String get assetEvAssign => 'Assign';

  @override
  String get assetEvMove => 'Move to section';

  @override
  String get assetEvInspect => 'Record inspection';

  @override
  String get assetEvRepair => 'Record repair';

  @override
  String get assetEvStatus => 'Change status';

  @override
  String get assetEvScrap => 'Scrap';

  @override
  String get assetEvCreated => 'Registered';

  @override
  String get assetEvAssigned => 'Assigned';

  @override
  String get assetEvMoved => 'Moved';

  @override
  String get assetEvInspected => 'Inspected';

  @override
  String get assetEvRepaired => 'Repaired';

  @override
  String get assetEvStatusChanged => 'Status changed';

  @override
  String get assetEvScrapped => 'Scrapped';

  @override
  String get assetScrapConfirm =>
      'Scrap this asset? This is recorded permanently.';

  @override
  String get assetNote => 'Note';

  @override
  String get comTitle => 'Commercial';

  @override
  String get comOverview => 'Overview';

  @override
  String get comSearch => 'Search tenders, work orders, invoices, letters';

  @override
  String get comNoResults => 'No matching records';

  @override
  String get comExpiringSoon => 'Deposits expiring soon';

  @override
  String get comNothingExpiring => 'No deposits expiring in the next 30 days';

  @override
  String get comAgeing => 'Receivables ageing';

  @override
  String comDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
      zero: 'Expires today',
    );
    return '$_temp0';
  }

  @override
  String get comNew => 'Add';

  @override
  String get comEmpty => 'Nothing recorded yet';

  @override
  String get comExportXlsx => 'Export Excel';

  @override
  String get comExportPdf => 'Export PDF';

  @override
  String get comLinked => 'Linked records';

  @override
  String get comDocuments => 'Documents';

  @override
  String get comAttachPdf => 'Attach PDF';

  @override
  String get comNoDocuments => 'No documents attached';

  @override
  String get comReadOnly =>
      'View only — changes are made by the COO or Director';

  @override
  String get comAll => 'All';

  @override
  String get entTenders => 'Tenders';

  @override
  String get entDeposits => 'EMD / SD / BG';

  @override
  String get entWorkOrders => 'Work orders';

  @override
  String get entBills => 'Bills / invoices';

  @override
  String get entLetters => 'Dispatch / letters';

  @override
  String get entGst => 'GST returns';

  @override
  String get fReference => 'Tender / work reference';

  @override
  String get fTitle => 'Title';

  @override
  String get fTenderType => 'Tender type';

  @override
  String get fWorkCategory => 'Work category';

  @override
  String get fDepartment => 'Department';

  @override
  String get fSection => 'Section office';

  @override
  String get fLocation => 'Location';

  @override
  String get fNoticeDate => 'Notice date';

  @override
  String get fSubmissionDeadline => 'Submission deadline';

  @override
  String get fOpeningDate => 'Opening date';

  @override
  String get fWorkStartDate => 'Work start date';

  @override
  String get fEstimate => 'Estimate amount';

  @override
  String get fEmd => 'EMD amount';

  @override
  String get fSecurityDeposit => 'Security deposit';

  @override
  String get fQuoted => 'Quoted amount';

  @override
  String get fContactPerson => 'Contact person';

  @override
  String get fContactPhone => 'Contact phone';

  @override
  String get fRemarks => 'Remarks';

  @override
  String get fStatus => 'Status';

  @override
  String get fKind => 'Type';

  @override
  String get fTender => 'Tender';

  @override
  String get fWorkOrder => 'Work order';

  @override
  String get fAmount => 'Amount';

  @override
  String get fPaymentMode => 'Payment mode';

  @override
  String get fInstrumentNo => 'DD / BG / UTR no.';

  @override
  String get fBank => 'Bank';

  @override
  String get fDepositDate => 'Deposit date';

  @override
  String get fValidityDate => 'Valid until';

  @override
  String get fReleasedOn => 'Released on';

  @override
  String get fWoNumber => 'Work order no.';

  @override
  String get fAgreementNo => 'Agreement no.';

  @override
  String get fAwardedAmount => 'Awarded amount';

  @override
  String get fIssueDate => 'Issue date';

  @override
  String get fDueDate => 'Completion due';

  @override
  String get fInvoiceNo => 'Invoice no.';

  @override
  String get fBillType => 'Bill type';

  @override
  String get fInvoiceDate => 'Invoice date';

  @override
  String get fTaxAmount => 'Tax (GST) amount';

  @override
  String get fPassedAmount => 'Passed amount';

  @override
  String get fPaidAmount => 'Paid amount';

  @override
  String get fPaidOn => 'Paid on';

  @override
  String get fRefNo => 'Reference no.';

  @override
  String get fDirection => 'In / out';

  @override
  String get fDocType => 'Document type';

  @override
  String get fParty => 'From / to';

  @override
  String get fSubject => 'Subject';

  @override
  String get fDocDate => 'Date';

  @override
  String get fGstin => 'GSTIN';

  @override
  String get fLegalName => 'Legal name';

  @override
  String get fReturnType => 'Return type';

  @override
  String get fPeriod => 'Return period (month)';

  @override
  String get fTaxable => 'Taxable value';

  @override
  String get fCgst => 'CGST';

  @override
  String get fSgst => 'SGST';

  @override
  String get fIgst => 'IGST';

  @override
  String get fFiledOn => 'Filed on';

  @override
  String get fArn => 'ARN';

  @override
  String get fGstinInvalid => 'Enter a valid 15-character GSTIN';

  @override
  String get fAmountInvalid => 'Enter a valid amount';

  @override
  String get optNone => '—';

  @override
  String get optTenderDraft => 'Draft';

  @override
  String get optTenderSubmitted => 'Submitted';

  @override
  String get optTenderOpened => 'Opened';

  @override
  String get optTenderAwarded => 'Awarded';

  @override
  String get optTenderLost => 'Lost';

  @override
  String get optTenderCancelled => 'Cancelled';

  @override
  String get optDepEmd => 'EMD';

  @override
  String get optDepSd => 'Security deposit';

  @override
  String get optDepBg => 'Bank guarantee';

  @override
  String get optDepRetention => 'Retention';

  @override
  String get optDepHeld => 'Held';

  @override
  String get optDepRefundRequested => 'Refund requested';

  @override
  String get optDepReleased => 'Released';

  @override
  String get optDepForfeited => 'Forfeited';

  @override
  String get optModeDd => 'Demand draft';

  @override
  String get optModeBg => 'Bank guarantee';

  @override
  String get optModeOnline => 'Online';

  @override
  String get optModeFdr => 'FDR';

  @override
  String get optModeCash => 'Cash';

  @override
  String get optModeOther => 'Other';

  @override
  String get optWoAwarded => 'Awarded';

  @override
  String get optWoInProgress => 'In progress';

  @override
  String get optWoCompleted => 'Completed';

  @override
  String get optWoClosed => 'Closed';

  @override
  String get optWoTerminated => 'Terminated';

  @override
  String get optBillRa => 'Running account (RA)';

  @override
  String get optBillFinal => 'Final';

  @override
  String get optBillAdvance => 'Advance';

  @override
  String get optBillOther => 'Other';

  @override
  String get optBillSubmitted => 'Submitted';

  @override
  String get optBillPassed => 'Passed';

  @override
  String get optBillPartiallyPaid => 'Partially paid';

  @override
  String get optBillPaid => 'Paid';

  @override
  String get optBillRejected => 'Rejected';

  @override
  String get optDirIn => 'Received';

  @override
  String get optDirOut => 'Sent';

  @override
  String get optDocLetter => 'Letter';

  @override
  String get optDocNotice => 'Notice';

  @override
  String get optDocCircular => 'Circular';

  @override
  String get optDocWorkOrder => 'Work order';

  @override
  String get optDocOther => 'Other';

  @override
  String get comPdfTooLarge => 'This PDF is larger than 10 MB.';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifEmpty => 'You\'re all caught up';

  @override
  String get notifMarkAll => 'Mark all read';

  @override
  String get notifChannelName => 'AumLux updates';

  @override
  String get notifChannelDescription => 'Approvals, alerts and reminders';

  @override
  String get bonusTitle => 'Bonus';

  @override
  String get bonusMyTotal => 'My approved bonus';

  @override
  String get bonusPoints => 'Points';

  @override
  String get bonusAmount => 'Amount';

  @override
  String get bonusPropose => 'Propose bonus';

  @override
  String get bonusFor => 'For';

  @override
  String get bonusReason => 'Reason';

  @override
  String get bonusReasonHint => 'e.g. Storm restoration overtime, 14–15 Oct';

  @override
  String get bonusNeedValue => 'Enter points or an amount';

  @override
  String get bonusProposed => 'Bonus proposed for approval';

  @override
  String get bonusEmpty => 'No bonus entries yet';

  @override
  String get bonusPendingNote => 'Bonuses are approved by the COO or Director.';

  @override
  String get locRationaleTitle => 'Why AumLux needs your location';

  @override
  String get locRationaleBody =>
      'Your location is recorded only at the moment you check in or out, or capture a site photo or pole. It is never tracked in the background.';

  @override
  String get updateTitle => 'Update required';

  @override
  String get updateBody =>
      'This version of AumLux is no longer supported. Install the latest version to continue — your saved data is kept.';

  @override
  String get updateButton => 'Download update';
}
