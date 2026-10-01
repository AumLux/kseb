import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../design/design.dart';
import '../errors/app_failure.dart';
import '../l10n/l10n.dart';
import '../location/location_rationale.dart';
import '../location/location_service.dart';
import '../ui/dialogs.dart';
import 'app_map.dart';
import 'location_picker_page.dart';

/// A form field for a place: mini map when set, plus "Use GPS" (fix from
/// the phone) and "Set on map" (drag the pin). [onChanged] receives the
/// coordinates and, for GPS fixes, the accuracy in metres.
class LocationField extends ConsumerStatefulWidget {
  const LocationField({
    super.key,
    required this.label,
    required this.lat,
    required this.lng,
    required this.onChanged,
    this.pinIcon = Icons.place_rounded,
  });

  final String label;
  final double? lat;
  final double? lng;
  final void Function(double lat, double lng, double? accuracyM) onChanged;
  final IconData pinIcon;

  @override
  ConsumerState<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends ConsumerState<LocationField> {
  bool _locating = false;
  double? _accuracy;

  bool get _has => widget.lat != null && widget.lng != null;

  Future<void> _gps() async {
    if (!await explainLocationIfNeeded(context, ref) || !mounted) return;
    setState(() => _locating = true);
    try {
      final loc = await ref.read(locationServiceProvider).current();
      _accuracy = loc.accuracyM;
      widget.onChanged(loc.lat, loc.lng, loc.accuracyM);
    } on AppFailure catch (f) {
      if (mounted) showSnack(context, failureMessage(context.l10n, f));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pick() async {
    final picked = await pickLocation(context, title: widget.label, lat: widget.lat, lng: widget.lng);
    if (picked == null) return;
    _accuracy = null;
    widget.onChanged(picked.lat, picked.lng, null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.label, style: AppTypography.label),
      const SizedBox(height: AppSpacing.xs + 2),
      AnimatedSize(
        duration: AppMotion.base,
        curve: AppMotion.curve,
        alignment: Alignment.topCenter,
        child: _has
            ? Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: LocationPreview(
                  height: 140,
                  title: widget.label,
                  points: [
                    MapPoint(
                      point: LatLng(widget.lat!, widget.lng!),
                      color: AppColors.primary,
                      icon: widget.pinIcon,
                      accuracyM: _accuracy,
                    ),
                  ],
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
      // Natural-width buttons that wrap to a second line when the labels are
      // long (Malayalam) instead of truncating.
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
        OutlinedButton.icon(
          onPressed: _locating ? null : _gps,
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)),
          icon: _locating
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location_rounded, size: 18),
          label: Text(l10n.wsUseGps),
        ),
        OutlinedButton.icon(
          onPressed: _pick,
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)),
          icon: const Icon(Icons.map_rounded, size: 18),
          label: Text(_has ? l10n.mapChangeOnMap : l10n.mapSetOnMap),
        ),
      ]),
    ]);
  }
}
