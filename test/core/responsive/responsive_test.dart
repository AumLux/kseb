import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/design.dart';

Future<BuildContext> _at(WidgetTester tester, double width, {Widget? child}) async {
  tester.view
    ..physicalSize = Size(width, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(
    home: ResponsiveScope(
      child: Builder(builder: (context) {
        ctx = context;
        return Scaffold(body: Center(child: child ?? const SizedBox()));
      }),
    ),
  ));
  return ctx;
}

void main() {
  test('device classes by width', () {
    expect(Breakpoints.classify(280), DeviceClass.compact);
    expect(Breakpoints.classify(359), DeviceClass.compact);
    expect(Breakpoints.classify(360), DeviceClass.phone);
    expect(Breakpoints.classify(599), DeviceClass.phone);
    expect(Breakpoints.classify(600), DeviceClass.tablet);
    expect(Breakpoints.classify(1023), DeviceClass.tablet);
    expect(Breakpoints.classify(1024), DeviceClass.desktop);
  });

  test('type is only tightened below 360dp', () {
    expect(Breakpoints.textFactor(300), 0.88);
    expect(Breakpoints.textFactor(340), 0.93);
    expect(Breakpoints.textFactor(360), 1.0);
    expect(Breakpoints.textFactor(1920), 1.0);
  });

  testWidgets('responsive() falls back to the next narrower class', (tester) async {
    var ctx = await _at(tester, 1200);
    expect(ctx.responsive(phone: 1, tablet: 2), 2);
    expect(ctx.isDesktop && ctx.isWide, isTrue);
    ctx = await _at(tester, 320);
    expect(ctx.responsive(phone: 1, tablet: 2), 1);
    expect(ctx.isCompact, isTrue);
    expect(ctx.pageGutter, AppSpacing.pageGutter);
  });

  testWidgets('ResponsiveScope scales text on narrow screens, on top of the user setting', (tester) async {
    final narrow = await _at(tester, 300);
    expect(MediaQuery.textScalerOf(narrow).scale(10), closeTo(8.8, 0.001));
    final phone = await _at(tester, 390);
    expect(MediaQuery.textScalerOf(phone).scale(10), 10);
  });

  testWidgets('FitLabel shrinks instead of breaking a word', (tester) async {
    const style = TextStyle(fontSize: 12.5);
    final ctx = await _at(tester, 400);
    double fitted(double width) => FitLabel.fittedFontSize(
          text: 'New worksheet',
          style: style,
          maxWidth: width,
          textScaler: MediaQuery.textScalerOf(ctx),
          textDirection: TextDirection.ltr,
        );
    expect(fitted(200), 12.5, reason: 'fits: untouched');
    expect(fitted(60), lessThan(12.5), reason: '"worksheet" is wider than 60dp at 12.5');
    expect(fitted(10), 12.5 * 0.75, reason: 'never below minScale');
  });

  testWidgets('QuickAction labels fit a narrow tile', (tester) async {
    await _at(
      tester,
      300,
      child: SizedBox(
        width: 62,
        child: QuickAction(icon: Icons.handyman_rounded, label: 'New worksheet', onTap: () {}),
      ),
    );
    final text = tester.widget<Text>(find.text('New worksheet'));
    expect(text.style!.fontSize, lessThan(12.5));
  });
}
