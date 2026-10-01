import 'package:intl/intl.dart';

/// Display formatting per DESIGN.md › Typography principles.
///
/// Money uses Indian digit grouping (₹ 1,23,456.00); dates use `dd MMM yyyy`.
abstract final class Fmt {
  static final NumberFormat _money =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);
  static final NumberFormat _moneyCompact =
      NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹ ');
  static final NumberFormat _qty = NumberFormat.decimalPattern('en_IN');
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _time = DateFormat('hh:mm a');

  static String money(num? value) => value == null ? '—' : _money.format(value);

  /// `₹ 12.5L`-style figures for KPI tiles.
  static String moneyCompact(num? value) =>
      value == null ? '—' : _moneyCompact.format(value);

  /// Quantities: no trailing zeros, grouped (1,250 / 12.5).
  static String qty(num? value, {String? unit}) {
    if (value == null) return '—';
    final text = _qty.format(value);
    return unit == null || unit.isEmpty ? text : '$text $unit';
  }

  static String date(DateTime? value) =>
      value == null ? '—' : _date.format(value.toLocal());

  static String dateTime(DateTime? value) =>
      value == null ? '—' : _dateTime.format(value.toLocal());

  static String time(DateTime? value) =>
      value == null ? '—' : _time.format(value.toLocal());

  /// "8h 30m" — for worked hours.
  static String duration(Duration? d) {
    if (d == null) return '—';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
