// Reads/deletes queued local files. Uploads are only queued on mobile; the
// web build stays online-only, so the stub throws.
export 'file_bytes_stub.dart' if (dart.library.io) 'file_bytes_io.dart';
