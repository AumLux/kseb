import 'package:intl/intl.dart';

import '../../core/format/formatters.dart';
import '../../core/format/ist.dart';
import '../../core/l10n/l10n.dart';
import 'entities.dart';

/// Human display for a stored value (money in ₹ en_IN, IST dates, option
/// labels, referenced record names).
String formatField(AppLocalizations l, FieldDef f, Object? v, {Map<String, String> refs = const {}}) {
  if (v == null || (v is String && v.isEmpty)) return '—';
  return switch (f.kind) {
    FieldKind.money => Fmt.money(v is num ? v : num.tryParse(v.toString())),
    FieldKind.date => Fmt.date(DateTime.tryParse(v.toString())),
    FieldKind.datetime => () {
        final t = DateTime.tryParse(v.toString());
        return t == null ? '—' : DateFormat('dd MMM yyyy, hh:mm a').format(t.toUtc().add(Ist.offset));
      }(),
    FieldKind.month => () {
        final t = DateTime.tryParse(v.toString());
        return t == null ? '—' : DateFormat('MMM yyyy').format(t);
      }(),
    FieldKind.choice => f.labelFor(l, v.toString()),
    FieldKind.ref => refs[v] ?? '—',
    _ => v.toString(),
  };
}

/// Plain value for spreadsheets: numbers stay numeric, dates ISO.
Object? exportValue(AppLocalizations l, FieldDef f, Object? v, Map<String, String> refs) => switch (f.kind) {
      FieldKind.money => v is num ? v : num.tryParse('${v ?? ''}'),
      FieldKind.choice => v == null ? null : f.labelFor(l, v.toString()),
      FieldKind.ref => v == null ? null : refs[v],
      FieldKind.datetime || FieldKind.date || FieldKind.month => v == null ? null : formatField(l, f, v),
      _ => v,
    };
