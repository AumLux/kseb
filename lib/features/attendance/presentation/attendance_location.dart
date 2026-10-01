import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/maps/app_map.dart';
import '../../org/data/org_repository.dart';
import '../data/attendance_repository.dart';

/// The geofence of a section (centre + radius), if its location is set.
(LatLng, int)? sectionFence(OrgTree? tree, String? sectionId) {
  final s = tree?.byId(sectionId);
  if (s == null || s.lat == null || s.lng == null) return null;
  return (LatLng(s.lat!, s.lng!), s.geofenceRadiusM ?? 300);
}

/// Map points for a day's check-in (green) and check-out (indigo).
List<MapPoint> attendancePoints(AppLocalizations l10n, AttendanceDay d) => [
      if (d.checkInLat != null && d.checkInLng != null)
        MapPoint(
          point: LatLng(d.checkInLat!, d.checkInLng!),
          color: AppColors.success,
          icon: Icons.login_rounded,
          label: d.checkInAt == null ? l10n.attCheckInPoint : '${l10n.attCheckInPoint} · ${Fmt.time(d.checkInAt)}',
          accuracyM: d.checkInAccuracyM,
        ),
      if (d.hasCheckOutLocation)
        MapPoint(
          point: LatLng(d.checkOutLat!, d.checkOutLng!),
          color: AppColors.primary,
          icon: Icons.logout_rounded,
          label: d.checkOutAt == null ? l10n.attCheckOutPoint : '${l10n.attCheckOutPoint} · ${Fmt.time(d.checkOutAt)}',
          accuracyM: d.checkOutAccuracyM,
        ),
    ];

/// Map + readout of where a shift started and ended. Shows nothing for days
/// recorded without GPS (supervisor marks, leave).
class AttendanceLocation extends StatelessWidget {
  const AttendanceLocation({super.key, required this.day, this.fence, this.mapHeight = 156, this.title});

  final AttendanceDay day;
  final (LatLng, int)? fence;
  final double mapHeight;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final points = attendancePoints(l10n, day);
    if (points.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LocationPreview(points: points, fence: fence, height: mapHeight, title: title ?? l10n.attWhereTitle),
      const SizedBox(height: AppSpacing.md),
      _Readout(
        icon: Icons.login_rounded,
        color: AppColors.success,
        label: l10n.attCheckInPoint,
        distanceM: day.checkInDistanceM,
        accuracyM: day.checkInAccuracyM,
        outside: day.outsideGeofence,
        mocked: day.checkInMocked,
        hasPoint: day.checkInLat != null,
      ),
      if (day.checkOutAt != null) ...[
        const SizedBox(height: AppSpacing.sm),
        _Readout(
          icon: Icons.logout_rounded,
          color: AppColors.primary,
          label: l10n.attCheckOutPoint,
          distanceM: day.checkOutDistanceM,
          accuracyM: day.checkOutAccuracyM,
          outside: day.checkOutOutsideGeofence,
          mocked: day.checkOutMocked,
          hasPoint: day.hasCheckOutLocation,
        ),
      ],
    ]);
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.icon,
    required this.color,
    required this.label,
    required this.distanceM,
    required this.accuracyM,
    required this.outside,
    required this.mocked,
    required this.hasPoint,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int? distanceM;
  final double? accuracyM;
  final bool? outside;
  final bool mocked;
  final bool hasPoint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detail = [
      if (!hasPoint) l10n.attNoGps,
      if (distanceM != null) l10n.attDistanceFromSection(distanceM!),
      if (accuracyM != null) l10n.attAccuracy(accuracyM!.round()),
    ].join(' · ');
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      IconTile(icon, size: 32, color: color),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
          if (detail.isNotEmpty) Text(detail, style: AppTypography.caption),
          if (mocked || outside != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
              if (mocked)
                StatusChip(label: l10n.attMockedLocation, tone: StatusTone.danger, icon: Icons.gps_off_rounded, dense: true),
              if (outside == true)
                StatusChip(label: l10n.attOutsideGeofence, tone: StatusTone.warning, icon: Icons.wrong_location_rounded, dense: true)
              else if (outside == false)
                StatusChip(label: l10n.attInsideGeofence, tone: StatusTone.success, icon: Icons.where_to_vote_rounded, dense: true),
            ]),
          ],
        ]),
      ),
    ]);
  }
}
