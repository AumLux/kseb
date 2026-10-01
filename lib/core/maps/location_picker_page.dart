import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../design/design.dart';
import '../errors/app_failure.dart';
import '../l10n/l10n.dart';
import '../location/location_rationale.dart';
import '../location/location_service.dart';
import '../ui/dialogs.dart';
import 'app_map.dart';

/// Result of [LocationPickerPage].
typedef PickedLocation = ({double lat, double lng, int? radiusM});

/// Opens the full-screen picker. With [radiusM] set, a geofence slider is
/// shown (section setup) and the chosen radius is returned too.
Future<PickedLocation?> pickLocation(
  BuildContext context, {
  required String title,
  double? lat,
  double? lng,
  int? radiusM,
}) =>
    Navigator.of(context).push<PickedLocation>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LocationPickerPage(title: title, lat: lat, lng: lng, radiusM: radiusM),
    ));

/// Drag the map under a fixed centre pin to choose a point (Uber/Swiggy
/// style), or jump to the GPS fix. Optional geofence radius slider.
class LocationPickerPage extends ConsumerStatefulWidget {
  const LocationPickerPage({super.key, required this.title, this.lat, this.lng, this.radiusM});

  final String title;
  final double? lat;
  final double? lng;
  final int? radiusM;

  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  final _map = MapController();
  late LatLng _center = widget.lat != null && widget.lng != null
      ? LatLng(widget.lat!, widget.lng!)
      : MapConfig.fallbackCenter;
  late double _radius = (widget.radiusM ?? 300).toDouble();
  bool _dragging = false;
  bool _locating = false;

  bool get _withRadius => widget.radiusM != null;

  @override
  void initState() {
    super.initState();
    // Nothing chosen yet: start at the user's position.
    if (widget.lat == null) WidgetsBinding.instance.addPostFrameCallback((_) => _myLocation(silent: true));
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _myLocation({bool silent = false}) async {
    if (!await explainLocationIfNeeded(context, ref) || !mounted) return;
    setState(() => _locating = true);
    try {
      final loc = await ref.read(locationServiceProvider).current();
      if (!mounted) return;
      final p = LatLng(loc.lat, loc.lng);
      setState(() => _center = p);
      _map.move(p, 17);
    } on AppFailure catch (f) {
      if (mounted && !silent) showSnack(context, failureMessage(context.l10n, f));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
        Expanded(
          child: Stack(alignment: Alignment.center, children: [
            AppMap(
              controller: _map,
              center: _center,
              zoom: widget.lat == null ? 13 : 17,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && !_dragging) setState(() => _dragging = true);
                _center = camera.center;
              },
              layers: [
                if (_withRadius) CircleLayer(circles: [geofenceCircle(_center, _radius.round())]),
              ],
            ),
            // Fixed centre pin: it lifts while the map moves and drops on release.
            IgnorePointer(
              child: AnimatedSlide(
                duration: AppMotion.fast,
                offset: Offset(0, _dragging ? -0.62 : -0.5),
                child: const MapPin(color: AppColors.primary, icon: Icons.circle, size: 48),
              ),
            ),
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerUp: (_) {
                  if (_dragging) {
                    HapticFeedback.selectionClick();
                    setState(() => _dragging = false);
                  }
                },
              ),
            ),
            Positioned(
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: FloatingActionButton.small(
                heroTag: null,
                tooltip: l10n.mapMyLocation,
                backgroundColor: AppColors.canvas,
                foregroundColor: AppColors.primaryDeep,
                onPressed: _locating ? null : _myLocation,
                child: _locating
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded),
              ),
            ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const IconTile(Icons.place_rounded, size: 40),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.mapDragHint, style: AppTypography.caption),
                    Text(
                      '${_center.latitude.toStringAsFixed(6)}, ${_center.longitude.toStringAsFixed(6)}',
                      style: AppTypography.bodyTabular,
                    ),
                  ]),
                ),
              ]),
              if (_withRadius) ...[
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  Text(l10n.orgGeofence, style: AppTypography.label),
                  const Spacer(),
                  Text(l10n.mapMeters(_radius.round()), style: AppTypography.bodyTabular),
                ]),
                Slider(
                  value: _radius,
                  min: 25,
                  max: 2000,
                  divisions: 79,
                  label: l10n.mapMeters(_radius.round()),
                  onChanged: (v) => setState(() => _radius = v),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l10n.mapUseThisLocation,
                icon: Icons.check_rounded,
                expand: true,
                onPressed: () => Navigator.pop<PickedLocation>(
                  context,
                  (lat: _center.latitude, lng: _center.longitude, radiusM: _withRadius ? _radius.round() : null),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
