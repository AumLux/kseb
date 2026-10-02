import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/design.dart';

void main() {
  // Regression: on a desktop-width window the mesh blobs (sized from the
  // width) painted far below the hero and over Home's shortcuts and KPIs.
  testWidgets('the mesh backdrop is clipped to its own box on wide screens', (tester) async {
    tester.view
      ..physicalSize = const Size(1900, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: 240, child: GradientMesh()),
        Expanded(child: ColoredBox(color: Color(0xFFFFFFFF))),
      ]),
    ));

    final mesh = find.descendant(of: find.byType(GradientMesh), matching: find.byType(CustomPaint));
    expect(
      tester.renderObject(mesh),
      paints..clipRect(rect: const Rect.fromLTWH(0, 0, 1900, 240)),
    );
  });
}
