import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<Uint8List> readFileBytes(String path) => File(path).readAsBytes();

Future<void> deleteLocalFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

/// Copies a picked file into app storage so a queued upload survives the
/// picker's temp files being cleaned up. Returns the new path.
Future<String> persistForUpload(String sourcePath, String fileName) async {
  final dir = Directory('${(await _appDir()).path}${Platform.pathSeparator}outbox');
  if (!await dir.exists()) await dir.create(recursive: true);
  final target = '${dir.path}${Platform.pathSeparator}$fileName';
  await File(sourcePath).copy(target);
  return target;
}

Future<Directory> _appDir() => getApplicationDocumentsDirectory();
