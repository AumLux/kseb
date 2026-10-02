import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/design.dart';
import '../../../core/export/file_export.dart';
import '../../../core/format/ist.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../../core/ui/sheets.dart';
import '../data/inventory_repository.dart';

/// Stock register (all movements) for a month, as Excel.
Uint8List buildStockRegisterXlsx({
  required List<LedgerEntry> entries,
  required Map<String, CatalogItem> materials,
  required Map<String, Store> stores,
  required String title,
}) {
  final excel = Excel.createExcel();
  final sheet = excel['Register'];
  excel.setDefaultSheet('Register');
  excel.delete('Sheet1');
  final fmt = DateFormat('dd-MM-yyyy HH:mm');
  sheet.appendRow([TextCellValue(title)]);
  sheet.appendRow([
    for (final h in ['Date', 'Store', 'Material code', 'Material', 'Unit', 'Type', 'Qty in', 'Qty out', 'Unit price', 'Reference / note'])
      TextCellValue(h),
  ]);
  for (final e in entries) {
    final m = materials[e.materialId];
    sheet.appendRow([
      TextCellValue(fmt.format(e.createdAt.toUtc().add(Ist.offset))),
      TextCellValue(stores[e.storeId]?.name ?? ''),
      TextCellValue(m?.code ?? ''),
      TextCellValue(m?.name ?? ''),
      TextCellValue(m?.unit ?? ''),
      TextCellValue(e.txnType),
      e.qtyDelta > 0 ? DoubleCellValue(e.qtyDelta.toDouble()) : TextCellValue(''),
      e.qtyDelta < 0 ? DoubleCellValue(-e.qtyDelta.toDouble()) : TextCellValue(''),
      e.unitPrice == null ? TextCellValue('') : DoubleCellValue(e.unitPrice!.toDouble()),
      TextCellValue(e.note ?? ''),
    ]);
  }
  return Uint8List.fromList(excel.save()!);
}

Future<void> exportStockRegister(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final thisMonth = Ist.monthStart(Ist.today());
  final months = [for (var i = 0; i < 12; i++) DateTime(thisMonth.year, thisMonth.month - i)];
  final month = await showAppSheet<DateTime>(
    context,
    builder: (context) => SheetScaffold(
      title: l10n.invExportRegister,
      subtitle: l10n.invPickMonth,
      leading: const IconTile(Icons.table_view_rounded, color: AppColors.success, size: 48),
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.6,
          children: [
            for (final (i, m) in months.indexed)
              Pressable(
                onTap: () => Navigator.pop(context, m),
                borderRadius: AppRadius.mdAll,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == 0 ? AppColors.primarySoft : AppColors.canvas,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: i == 0 ? AppColors.primary : AppColors.hairline),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(DateFormat.MMM(Localizations.localeOf(context).toString()).format(m),
                        style: AppTypography.subtitle.copyWith(color: i == 0 ? AppColors.primaryDeep : AppColors.ink)),
                    Text('${m.year}', style: AppTypography.caption),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    ),
  );
  if (month == null || !context.mounted) return;
  final title = 'Stock register — ${MaterialLocalizations.of(context).formatMonthYear(month)}';
  try {
    final repo = ref.read(inventoryRepositoryProvider);
    // Month boundaries in IST.
    final from = DateTime.utc(month.year, month.month).subtract(Ist.offset);
    final to = DateTime.utc(month.year, month.month + 1).subtract(Ist.offset);
    final entries = await repo.ledgerForPeriod(from, to);
    final materials = {for (final m in await repo.catalog()) m.id: m};
    final stores = {for (final s in await repo.stores()) s.id: s};
    final bytes = buildStockRegisterXlsx(entries: entries, materials: materials, stores: stores, title: title);
    if (!context.mounted) return;
    await exportFile(context,
        bytes: bytes, baseName: 'stock_register_${month.year}_${month.month.toString().padLeft(2, '0')}', kind: ExportKind.xlsx);
  } catch (e) {
    if (context.mounted) showSnack(context, failureMessage(l10n, e));
  }
}
