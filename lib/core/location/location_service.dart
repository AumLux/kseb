import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../errors/app_failure.dart';

/// A GPS fix captured at the moment of an action (check-in, photo, survey).
class CapturedLocation {
  const CapturedLocation({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.isMocked,
  });

  final double lat;
  final double lng;
  final double accuracyM;

  /// Android reports fixes from mock-location apps; the server stores the
  /// flag so supervisors can see it.
  final bool isMocked;
}

abstract interface class LocationService {
  /// Throws [AppFailure] with code `location_off`, `location_denied`,
  /// `location_denied_forever` or `location_timeout`.
  Future<CapturedLocation> current();

  /// True while the OS permission prompt hasn't been answered yet, i.e. the
  /// next [current] call would show it.
  Future<bool> permissionUndecided();

  /// Asks for permission if it hasn't been decided; true when granted.
  /// Never throws. Call before opening the camera so the GPS fix can be
  /// taken while the camera is open (no prompt over the camera).
  Future<bool> requestPermission();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<bool> requestPermission() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      return p == LocationPermission.whileInUse || p == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> permissionUndecided() async {
    try {
      return await Geolocator.checkPermission() == LocationPermission.denied;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<CapturedLocation> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppFailure('location_off', 'Turn on location (GPS) and try again.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AppFailure('location_denied', 'Location permission is needed to record attendance.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppFailure('location_denied_forever',
          'Location permission is blocked. Allow it in the phone settings for AumLux.');
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return CapturedLocation(
        lat: p.latitude,
        lng: p.longitude,
        accuracyM: p.accuracy,
        isMocked: p.isMocked,
      );
    } on Exception {
      // Weak GPS (indoors / under cover): fall back to the last known fix if
      // it is recent enough to be meaningful.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && DateTime.now().difference(last.timestamp) < const Duration(minutes: 10)) {
        return CapturedLocation(
          lat: last.latitude,
          lng: last.longitude,
          accuracyM: last.accuracy,
          isMocked: last.isMocked,
        );
      }
      throw const AppFailure('location_timeout',
          "Couldn't get your location. Move to an open area and try again.", retryable: true);
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => GeolocatorLocationService());

Future<void> openLocationSettings() => Geolocator.openAppSettings();
