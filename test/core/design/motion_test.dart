import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/design.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion, size: const Size(400, 800)),
        child: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('LazyListView builds only the rows on screen', (tester) async {
    var built = 0;
    await tester.pumpWidget(_wrap(LazyListView(
      header: const [Text('header')],
      itemCount: 1000,
      itemBuilder: (context, i) {
        built++;
        return SizedBox(height: 56, child: Text('row $i'));
      },
      footer: const [Text('footer')],
    )));
    expect(find.text('header'), findsOneWidget);
    expect(find.text('row 0'), findsOneWidget);
    expect(built, lessThan(40), reason: 'eager lists built all 1000 rows');
  });

  testWidgets('Pressable taps once and scales back after release', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(Center(
      child: Pressable(onTap: () => taps++, child: const SizedBox(width: 120, height: 48, child: Text('Go'))),
    )));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Go')));
    await tester.pump(); // first frame starts the ticker (elapsed 0)
    await tester.pump(const Duration(milliseconds: 100));
    final scale = find.descendant(of: find.byType(Pressable), matching: find.byType(ScaleTransition));
    final pressed = tester.widget<ScaleTransition>(scale).scale.value;
    expect(pressed, lessThan(1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.widget<ScaleTransition>(scale).scale.value, 1);
  });

  testWidgets('FadeSlideIn settles without timers, staggered or not', (tester) async {
    await tester.pumpWidget(_wrap(const Column(children: [
      FadeSlideIn(child: Text('a')),
      FadeSlideIn(index: 5, child: Text('b')),
    ])));
    await tester.pumpAndSettle();
    final opacities = tester.widgetList<FadeTransition>(find.byType(FadeTransition)).map((f) => f.opacity.value);
    expect(opacities, everyElement(1.0));
  });

  testWidgets('reduce motion shows content immediately', (tester) async {
    await tester.pumpWidget(_wrap(const FadeSlideIn(index: 3, child: Text('now')), reduceMotion: true));
    await tester.pump();
    expect(tester.widget<FadeTransition>(find.byType(FadeTransition).first).opacity.value, 1.0);
  });

  testWidgets('the brand mark paints at any size', (tester) async {
    await tester.pumpWidget(_wrap(const Row(children: [BrandMark(size: 24), BrandMark(size: 96, tile: false)])));
    expect(find.bySemanticsLabel('AumLux'), findsNWidgets(2));
  });
}
