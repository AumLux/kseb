import 'package:url_launcher/url_launcher.dart';

/// Opens a coordinate in the phone's maps app (Google Maps on the web).
Future<bool> openInMaps(double lat, double lng) => launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
      mode: LaunchMode.externalApplication,
    );
