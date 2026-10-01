import 'dart:typed_data';

Future<Uint8List> readFileBytes(String path) =>
    throw UnsupportedError('Queued file uploads are not supported on this platform.');

Future<void> deleteLocalFile(String path) async {}

Future<String> persistForUpload(String sourcePath, String fileName) =>
    throw UnsupportedError('Queued uploads are mobile-only.');
