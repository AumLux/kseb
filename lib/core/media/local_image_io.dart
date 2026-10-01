import 'dart:io';

import 'package:flutter/widgets.dart';

/// Decodes at [cacheWidth] pixels, not full size, so a strip of thumbnails
/// stays cheap on memory.
Widget localImage(String path, {required int cacheWidth, BoxFit fit = BoxFit.cover}) =>
    Image.file(File(path), cacheWidth: cacheWidth, fit: fit, gaplessPlayback: true);
