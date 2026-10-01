import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';

import '../design/design.dart';
import '../l10n/l10n.dart';
import '../ui/maps.dart';

/// Map tiles (ADR-0001). OpenStreetMap's standard tiles are free and need no
/// key; the usage policy asks for attribution, a real User-Agent and caching,
/// all handled here. Swap providers without a code change:
/// `--dart-define=MAP_TILE_URL=https://…/{z}/{x}/{y}.png`.
abstract final class MapConfig {
  static const tileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static const attribution = String.fromEnvironment('MAP_ATTRIBUTION', defaultValue: '© OpenStreetMap contributors');
  static const userAgentPackage = 'com.aumlux.app';
  static const maxZoom = 19.0;

  /// Kochi: a sensible default when nothing is known yet.
  static const fallbackCenter = LatLng(9.9816, 76.2999);
}

/// The base map used everywhere: tiles + attribution + [layers] on top.
/// [interactive] = false makes a static preview (taps go to [onTap]).
class AppMap extends StatelessWidget {
  const AppMap({
    super.key,
    required this.center,
    this.zoom = 16,
    this.layers = const [],
    this.interactive = true,
    this.controller,
    this.onPositionChanged,
    this.onTap,
    this.fitPoints,
  });

  final LatLng center;
  final double zoom;
  final List<Widget> layers;
  final bool interactive;
  final MapController? controller;
  final void Function(MapCamera camera, bool hasGesture)? onPositionChanged;
  final VoidCallback? onTap;

  /// When given (2+ points), the camera fits them all instead of [center]/[zoom].
  final List<LatLng>? fitPoints;

  @override
  Widget build(BuildContext context) {
    final fit = (fitPoints?.length ?? 0) > 1
        ? CameraFit.coordinates(
            coordinates: fitPoints!,
            padding: const EdgeInsets.all(56),
            maxZoom: 17,
          )
        : null;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        initialCameraFit: fit,
        maxZoom: MapConfig.maxZoom,
        minZoom: 3,
        backgroundColor: AppColors.canvasSunken,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
        onPositionChanged: onPositionChanged,
        onTap: onTap == null ? null : (_, _) => onTap!(),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrl,
          userAgentPackageName: MapConfig.userAgentPackage,
          maxNativeZoom: 19,
        ),
        ...layers,
        SimpleAttributionWidget(
          source: const Text(MapConfig.attribution, style: TextStyle(fontSize: 10)),
          backgroundColor: const Color(0xCCFFFFFF),
          onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'),
              mode: LaunchMode.externalApplication),
        ),
      ],
    );
  }
}

/// A teardrop pin in the brand style. [label] is a 1–2 char glyph (e.g. "IN").
class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.color, this.icon, this.size = 40, this.selected = false});

  final Color color;
  final IconData? icon;
  final double size;
  final bool selected;

  /// Marker anchored at the pin's tip.
  static Marker marker(LatLng point, Widget pin, {double size = 40, Key? key}) => Marker(
        key: key,
        point: point,
        width: size,
        height: size,
        alignment: Alignment.topCenter,
        child: pin,
      );

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: selected ? 1.2 : 1,
        duration: AppMotion.fast,
        child: Stack(alignment: Alignment.topCenter, children: [
          Icon(Icons.location_on_rounded, size: size, color: color, shadows: const [
            Shadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
          ]),
          Padding(
            padding: EdgeInsets.only(top: size * 0.16),
            child: Container(
              width: size * 0.36,
              height: size * 0.36,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: icon == null ? null : Icon(icon, size: size * 0.24, color: color),
            ),
          ),
        ]),
      );
}

/// Geofence ring around a section office.
CircleMarker geofenceCircle(LatLng center, int radiusM, {Color color = AppColors.primary}) => CircleMarker(
      point: center,
      radius: radiusM.toDouble(),
      useRadiusInMeter: true,
      color: color.withValues(alpha: 0.10),
      borderColor: color.withValues(alpha: 0.55),
      borderStrokeWidth: 1.5,
    );

/// Accuracy halo around a GPS fix.
CircleMarker accuracyCircle(LatLng center, double radiusM, Color color) => CircleMarker(
      point: center,
      radius: radiusM,
      useRadiusInMeter: true,
      color: color.withValues(alpha: 0.12),
      borderColor: Colors.transparent,
      borderStrokeWidth: 0,
    );

/// One labelled point for [LocationPreview] / [MapViewPage].
class MapPoint {
  const MapPoint({required this.point, required this.color, this.icon, this.label, this.accuracyM});

  final LatLng point;
  final Color color;
  final IconData? icon;
  final String? label;
  final double? accuracyM;
}

/// Static mini-map card (rounded, non-interactive). Tap opens [MapViewPage].
class LocationPreview extends StatelessWidget {
  const LocationPreview({
    super.key,
    required this.points,
    this.fence,
    this.height = 168,
    this.title,
  });

  final List<MapPoint> points;

  /// Optional geofence (centre + radius in metres).
  final (LatLng, int)? fence;
  final double height;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final all = [for (final p in points) p.point, if (fence != null) fence!.$1];
    void open() => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => MapViewPage(title: title ?? context.l10n.mapTitle, points: points, fence: fence),
        ));
    return Semantics(
      button: true,
      label: title ?? context.l10n.mapTitle,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: SizedBox(
          height: height,
          child: Stack(children: [
            AppMap(
              center: points.first.point,
              zoom: 16,
              interactive: false,
              fitPoints: all.length > 1 ? all : null,
              onTap: open,
              layers: _layers(points, fence),
            ),
            Positioned(
              right: AppSpacing.sm,
              top: AppSpacing.sm,
              child: Material(
                color: AppColors.canvas,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: context.l10n.mapExpand,
                  icon: const Icon(Icons.open_in_full_rounded, size: 18),
                  onPressed: open,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

List<Widget> _layers(List<MapPoint> points, (LatLng, int)? fence) => [
      if (fence != null) CircleLayer(circles: [geofenceCircle(fence.$1, fence.$2)]),
      CircleLayer(circles: [
        for (final p in points)
          if (p.accuracyM != null && p.accuracyM! > 0) accuracyCircle(p.point, p.accuracyM!, p.color),
      ]),
      if (fence != null)
        MarkerLayer(markers: [
          Marker(
            point: fence.$1,
            width: 28,
            height: 28,
            child: const IconTile(Icons.location_city_rounded, size: 28, background: AppColors.canvas),
          ),
        ]),
      MarkerLayer(markers: [for (final p in points) MapPin.marker(p.point, MapPin(color: p.color, icon: p.icon))]),
    ];

/// Full-screen map of a few points, with a legend and "Open in Maps".
class MapViewPage extends StatelessWidget {
  const MapViewPage({super.key, required this.title, required this.points, this.fence});

  final String title;
  final List<MapPoint> points;
  final (LatLng, int)? fence;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = [for (final p in points) p.point, if (fence != null) fence!.$1];
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(children: [
        Expanded(
          child: AppMap(
            center: points.first.point,
            zoom: 17,
            fitPoints: all.length > 1 ? all : null,
            layers: _layers(points, fence),
          ),
        ),
        SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final p in points)
              AppListRow(
                leading: IconTile(p.icon ?? Icons.place_rounded, color: p.color, size: 36),
                title: p.label ?? l10n.mapPoint,
                subtitle: [
                  '${p.point.latitude.toStringAsFixed(5)}, ${p.point.longitude.toStringAsFixed(5)}',
                  if (p.accuracyM != null) '±${p.accuracyM!.round()} m',
                ].join('  ·  '),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: Text(l10n.mapOpenExternal),
                  onPressed: () => openInMaps(p.point.latitude, p.point.longitude),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
