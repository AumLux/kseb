import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/format/formatters.dart';

void main() {
  test('money uses Indian grouping and the rupee symbol', () {
    expect(Fmt.money(123456.5), '₹ 1,23,456.50');
    expect(Fmt.money(null), '—');
  });

  test('quantities drop trailing zeros and append unit', () {
    expect(Fmt.qty(1250), '1,250');
    expect(Fmt.qty(12.5, unit: 'm'), '12.5 m');
  });

  test('dates are dd MMM yyyy', () {
    expect(Fmt.date(DateTime(2026, 10, 1)), '01 Oct 2026');
  });

  test('durations read as hours and minutes', () {
    expect(Fmt.duration(const Duration(hours: 8, minutes: 30)), '8h 30m');
    expect(Fmt.duration(const Duration(minutes: 45)), '45m');
    expect(Fmt.duration(const Duration(hours: 9)), '9h');
  });
}
