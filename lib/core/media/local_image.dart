// Thumbnail of a local file (queued uploads on phones). The web build never
// queues uploads, so its stub just draws a placeholder.
export 'local_image_stub.dart' if (dart.library.io) 'local_image_io.dart';
