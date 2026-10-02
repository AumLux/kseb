import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression: a bottom sheet opened from a tab's root page (More, Attendance,
/// Work…) was shown on that tab's navigator, i.e. *under* the bottom
/// navigation bar, which covered its last option (the language picker's
/// "മലയാളം"). Every sheet must open on the root navigator.
void main() {
  test('every showModalBottomSheet opens on the root navigator', () {
    final call = RegExp(r'showModalBottomSheet<[^>]*>\(');
    final missing = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in call.allMatches(src)) {
        final args = src.substring(m.end).split('builder:').first;
        if (!args.contains('useRootNavigator: true')) {
          missing.add('${f.path}:${'\n'.allMatches(src.substring(0, m.start)).length + 1}');
        }
      }
    }
    expect(missing, isEmpty, reason: 'pass useRootNavigator: true (or use showAppSheet)');
  });
}
