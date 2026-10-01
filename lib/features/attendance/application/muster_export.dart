import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/format/ist.dart';
import '../data/attendance_repository.dart';

/// Single-letter muster codes (legend printed on every export).
String musterCode(MusterCell c) => switch (c.status) {
      AttendanceStatus.present => 'P',
      AttendanceStatus.absent => 'A',
      AttendanceStatus.leave => 'L',
      AttendanceStatus.halfDay => 'HD',
      AttendanceStatus.holiday => 'H',
      null => c.isHoliday ? 'H' : '-',
    };

const musterLegend = 'P = Present · A = Absent · L = Leave · HD = Half day · H = Holiday · - = Not marked';

/// One person's row in the muster grid.
class MusterPerson {
  MusterPerson(this.employeeCode, this.fullName, this.cells);

  final String employeeCode;
  final String fullName;
  final List<MusterCell> cells;

  double get presentDays => cells.fold(0.0, (sum, c) => sum + switch (c.status) {
        AttendanceStatus.present => 1.0,
        AttendanceStatus.halfDay => 0.5,
        _ => 0.0,
      });

  int get leaveDays => cells.where((c) => c.status == AttendanceStatus.leave).length;
  int get absentDays => cells.where((c) => c.status == AttendanceStatus.absent).length;
  int get workedMinutes => cells.fold(0, (sum, c) => sum + (c.workedMinutes ?? 0));
}

List<MusterPerson> groupMuster(List<MusterCell> cells) {
  final byUser = <String, List<MusterCell>>{};
  for (final c in cells) {
    byUser.putIfAbsent(c.userId, () => []).add(c);
  }
  return [
    for (final list in byUser.values)
      MusterPerson(list.first.employeeCode, list.first.fullName,
          list..sort((a, b) => a.date.compareTo(b.date))),
  ]..sort((a, b) => a.fullName.compareTo(b.fullName));
}

String _hours(int minutes) => (minutes / 60).toStringAsFixed(1);

Future<Uint8List> buildMusterPdf({
  required List<MusterCell> cells,
  required DateTime month,
  required String title,
  required String generatedBy,
}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
  final people = groupMuster(cells);
  final days = List.generate(Ist.monthEnd(month).day, (i) => DateTime(month.year, month.month, i + 1));
  final small = pw.TextStyle(font: regular, fontSize: 6.5);
  final head = pw.TextStyle(font: bold, fontSize: 6.5);
  const ink = PdfColor.fromInt(0xFF0D253D);
  const soft = PdfColor.fromInt(0xFFF6F9FC);

  final doc = pw.Document(title: title, author: 'AumLux');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(20),
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    header: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 13, color: ink)),
        pw.SizedBox(height: 2),
        pw.Text(
          'Generated ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())} by $generatedBy · $musterLegend',
          style: pw.TextStyle(font: regular, fontSize: 7, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
      ],
    ),
    footer: (context) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: small),
    ),
    build: (context) => [
      pw.TableHelper.fromTextArray(
        headerStyle: head,
        cellStyle: small,
        headerDecoration: const pw.BoxDecoration(color: soft),
        cellAlignment: pw.Alignment.center,
        cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
        columnWidths: {
          0: const pw.FixedColumnWidth(34),
          1: const pw.FixedColumnWidth(70),
          for (var i = 0; i < days.length; i++) i + 2: const pw.FixedColumnWidth(13),
        },
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 2),
        headers: [
          'ID',
          'Name',
          for (final d in days) '${d.day}',
          'P', 'L', 'A', 'Hrs',
        ],
        data: [
          for (final p in people)
            [
              p.employeeCode,
              p.fullName,
              for (final c in p.cells) musterCode(c),
              p.presentDays.toStringAsFixed(p.presentDays % 1 == 0 ? 0 : 1),
              '${p.leaveDays}',
              '${p.absentDays}',
              _hours(p.workedMinutes),
            ],
        ],
      ),
      pw.SizedBox(height: 24),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          for (final who in ['Prepared by (Supervisor)', 'Verified by (Manager)', 'Approved by'])
            pw.Column(children: [
              pw.SizedBox(width: 160, child: pw.Divider(color: PdfColors.grey600)),
              pw.Text(who, style: small),
            ]),
        ],
      ),
    ],
  ));
  return doc.save();
}

Uint8List buildMusterXlsx({required List<MusterCell> cells, required DateTime month, required String title}) {
  final people = groupMuster(cells);
  final days = List.generate(Ist.monthEnd(month).day, (i) => i + 1);
  final excel = Excel.createExcel();
  final grid = excel['Muster'];
  final detail = excel['Check-in times'];
  excel.setDefaultSheet('Muster');
  excel.delete('Sheet1');

  grid.appendRow([TextCellValue(title)]);
  grid.appendRow([TextCellValue(musterLegend)]);
  grid.appendRow([
    TextCellValue('Employee ID'),
    TextCellValue('Name'),
    for (final d in days) IntCellValue(d),
    TextCellValue('Present'),
    TextCellValue('Leave'),
    TextCellValue('Absent'),
    TextCellValue('Hours'),
  ]);
  for (final p in people) {
    grid.appendRow([
      TextCellValue(p.employeeCode),
      TextCellValue(p.fullName),
      for (final c in p.cells) TextCellValue(musterCode(c)),
      DoubleCellValue(p.presentDays),
      IntCellValue(p.leaveDays),
      IntCellValue(p.absentDays),
      DoubleCellValue(double.parse(_hours(p.workedMinutes))),
    ]);
  }

  final timeFmt = DateFormat('HH:mm');
  detail.appendRow([
    TextCellValue('Employee ID'),
    TextCellValue('Name'),
    TextCellValue('Date'),
    TextCellValue('Status'),
    TextCellValue('Check-in'),
    TextCellValue('Check-out'),
    TextCellValue('Hours'),
    TextCellValue('Verified'),
  ]);
  for (final p in people) {
    for (final c in p.cells.where((c) => c.status != null)) {
      detail.appendRow([
        TextCellValue(p.employeeCode),
        TextCellValue(p.fullName),
        DateCellValue(year: c.date.year, month: c.date.month, day: c.date.day),
        TextCellValue(musterCode(c)),
        TextCellValue(c.checkInAt == null ? '' : timeFmt.format(c.checkInAt!.toUtc().add(Ist.offset))),
        TextCellValue(c.checkOutAt == null ? '' : timeFmt.format(c.checkOutAt!.toUtc().add(Ist.offset))),
        DoubleCellValue(double.parse(_hours(c.workedMinutes ?? 0))),
        TextCellValue(c.verified ? 'Yes' : 'No'),
      ]);
    }
  }
  return Uint8List.fromList(excel.save()!);
}
