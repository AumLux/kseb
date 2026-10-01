import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/design.dart';

import 'contrast_test.dart' show contrast;

Color _labelColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color ??
    DefaultTextStyle.of(tester.element(find.text(text))).style.color!;

void main() {
  // Regression: selected pills were ink-on-ink (label unreadable).
  testWidgets('selected filter pills have readable white labels on ink', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Row(children: [
          FilterChip(label: const Text('Active'), selected: true, onSelected: (_) {}),
          ChoiceChip(label: const Text('Mine'), selected: false, onSelected: (_) {}),
        ]),
      ),
    ));
    final selected = _labelColor(tester, 'Active');
    final unselected = _labelColor(tester, 'Mine');
    expect(contrast(selected, AppColors.ink), greaterThanOrEqualTo(4.5), reason: 'label on the ink pill');
    expect(contrast(unselected, AppColors.canvas), greaterThanOrEqualTo(4.5), reason: 'label on the white pill');
  });
}
