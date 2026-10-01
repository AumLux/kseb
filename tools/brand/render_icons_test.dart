// Renders every raster brand asset from BrandMarkPainter, so the launcher,
// web and favicon PNGs are pixel-identical to the in-app mark.
//
//   flutter test tools/brand/render_icons_test.dart
//
// Re-run after changing the mark; commit the regenerated PNGs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/widgets/brand_mark.dart';

Future<void> _render(String path, int px, {bool fullBleed = false, double inset = 0}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = px * (1 - inset * 2);
  canvas.translate(px * inset, px * inset);
  BrandMarkPainter(fullBleed: fullBleed, cornerFraction: 0.24).paint(canvas, Size.square(side));
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render brand icons', () async {
    const res = 'android/app/src/main/res';
    // Legacy (pre-adaptive, Android 7.x) launcher icons, with a small margin.
    for (final (dir, px) in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]) {
      await _render('$res/mipmap-$dir/ic_launcher.png', px, inset: 0.04);
    }
    await _render('web/icons/Icon-192.png', 192, inset: 0.04);
    await _render('web/icons/Icon-512.png', 512, inset: 0.04);
    // Maskable: full-bleed gradient, glyph already inside the 80% safe zone.
    await _render('web/icons/Icon-maskable-192.png', 192, fullBleed: true);
    await _render('web/icons/Icon-maskable-512.png', 512, fullBleed: true);
    await _render('web/favicon.png', 64);
    await _render('docs/brand/aumlux-mark-1024.png', 1024);
  });
}
