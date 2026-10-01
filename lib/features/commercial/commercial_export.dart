import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/l10n/l10n.dart';
import 'commercial_repository.dart';
import 'entities.dart';
import 'field_format.dart';

/// Columns worth printing on a one-page summary (long text is skipped).
List<FieldDef> printableFields(EntityDef e) =>
    e.fields.where((f) => f.kind != FieldKind.multiline && f.kind != FieldKind.phone).toList();

Uint8List buildEntityXlsx(AppLocalizations l, EntityDef e, List<DbRow> rows, Map<String, Map<String, String>> refs) {
  final excel = Excel.createExcel();
  final name = e.title(l).replaceAll(RegExp(r'[\\/?*\[\]:]'), '-');
  final sheet = excel[name.length > 31 ? name.substring(0, 31) : name];
  excel.setDefaultSheet(sheet.sheetName);
  excel.delete('Sheet1');
  sheet.appendRow([for (final f in e.fields) TextCellValue(f.label(l))]);
  for (final r in rows) {
    sheet.appendRow([
      for (final f in e.fields)
        switch (exportValue(l, f, r[f.key], refs[f.refEntity] ?? const {})) {
          null => TextCellValue(''),
          final num n => DoubleCellValue(n.toDouble()),
          final Object v => TextCellValue(v.toString()),
        },
    ]);
  }
  return Uint8List.fromList(excel.save()!);
}

Future<Uint8List> buildEntityPdf(
  AppLocalizations l,
  EntityDef e,
  List<DbRow> rows,
  Map<String, Map<String, String>> refs, {
  required String generatedBy,
}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
  final fields = printableFields(e);
  final doc = pw.Document(title: e.title(l), author: 'AumLux');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(20),
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(e.title(l), style: pw.TextStyle(font: bold, fontSize: 14, color: const PdfColor.fromInt(0xFF0D253D))),
      pw.Text('Generated ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())} by $generatedBy',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
      pw.SizedBox(height: 8),
    ]),
    footer: (c) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('Page ${c.pageNumber} of ${c.pagesCount}', style: const pw.TextStyle(fontSize: 7)),
    ),
    build: (_) => [
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: bold, fontSize: 6.5),
        cellStyle: const pw.TextStyle(fontSize: 6.5),
        headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF6F9FC)),
        cellPadding: const pw.EdgeInsets.all(2.5),
        headers: [for (final f in fields) f.label(l)],
        cellAlignments: {
          for (var i = 0; i < fields.length; i++)
            if (fields[i].kind == FieldKind.money) i: pw.Alignment.centerRight,
        },
        data: [
          for (final r in rows)
            [for (final f in fields) formatField(l, f, r[f.key], refs: refs[f.refEntity] ?? const {})],
        ],
      ),
    ],
  ));
  return doc.save();
}
