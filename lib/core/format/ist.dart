/// India Standard Time helpers. IST is a fixed UTC+05:30 with no DST, so the
/// client can compute the same "work date" as the server
/// (`private.ist_date`) regardless of the phone's timezone setting.
abstract final class Ist {
  static const offset = Duration(hours: 5, minutes: 30);

  /// Calendar date in IST for an instant (time part dropped).
  static DateTime dateOf(DateTime instant) {
    final t = instant.toUtc().add(offset);
    return DateTime(t.year, t.month, t.day);
  }

  static DateTime today() => dateOf(DateTime.now());

  /// `YYYY-MM-DD`, as Postgres `date` columns expect.
  static String iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime monthStart(DateTime d) => DateTime(d.year, d.month);
  static DateTime monthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0);
}
