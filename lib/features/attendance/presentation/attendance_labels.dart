import 'package:flutter/material.dart' show Icons;

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../data/attendance_repository.dart';

String attendanceStatusLabel(AppLocalizations l10n, AttendanceStatus s) => switch (s) {
      AttendanceStatus.present => l10n.attStatusPresent,
      AttendanceStatus.absent => l10n.attStatusAbsent,
      AttendanceStatus.leave => l10n.attStatusLeave,
      AttendanceStatus.halfDay => l10n.attStatusHalfDay,
      AttendanceStatus.holiday => l10n.attStatusHoliday,
    };

StatusChip attendanceChip(AppLocalizations l10n, AttendanceStatus? s, {bool dense = false}) => s == null
    ? StatusChip(label: l10n.attNotMarked, tone: StatusTone.warning, dense: dense)
    : StatusChip.fromDomain(s.db, label: attendanceStatusLabel(l10n, s));

/// Review flags a supervisor should see before verifying.
List<StatusChip> attendanceFlags(AppLocalizations l10n, AttendanceDay d) => [
      if (d.checkInMocked)
        StatusChip(label: l10n.attFlagMocked, tone: StatusTone.danger, icon: Icons.gps_off_rounded, dense: true),
      if (d.outsideGeofence == true)
        StatusChip(
            label: d.checkInDistanceM == null
                ? l10n.attFlagOutside
                : '${l10n.attFlagOutside} · ${(d.checkInDistanceM! / 1000).toStringAsFixed(1)} km',
            tone: StatusTone.warning,
            icon: Icons.wrong_location_rounded,
            dense: true),
      if (d.source == 'device' && !d.hasLocation && d.checkInAt != null)
        StatusChip(label: l10n.attFlagNoLocation, tone: StatusTone.warning, icon: Icons.location_disabled_rounded, dense: true),
      if (d.verified)
        StatusChip(label: l10n.attVerified, tone: StatusTone.success, icon: Icons.verified_rounded, dense: true),
    ];
