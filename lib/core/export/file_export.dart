import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../design/design.dart';
import '../l10n/l10n.dart';
import '../ui/dialogs.dart';
import 'file_opener_stub.dart' if (dart.library.io) 'file_opener_io.dart';

enum ExportKind {
  pdf('application/pdf', 'pdf', 'PDF'),
  xlsx('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx', 'Excel');

  const ExportKind(this.mimeType, this.extension, this.label);

  final String mimeType;
  final String extension;
  final String label;
}

/// Delivers a generated file: on phones, offer Open / Share (WhatsApp, mail,
/// Drive); on web and desktop, a save dialog / browser download.
Future<bool> exportFile(
  BuildContext context, {
  required Uint8List bytes,
  required String baseName,
  required ExportKind kind,
}) async {
  final l10n = context.l10n;
  final fileName = '${baseName.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_')}.${kind.extension}';
  final isPhone = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  if (!isPhone) {
    final location = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [XTypeGroup(label: kind.label, extensions: [kind.extension])],
    );
    if (location == null) {
      if (context.mounted) showSnack(context, l10n.exportCancelled);
      return false;
    }
    await XFile.fromData(bytes, name: fileName, mimeType: kind.mimeType).saveTo(location.path);
    return true;
  }

  final path = await writeGeneratedFileForOpen(bytes: bytes, fileName: fileName);
  if (!context.mounted) return false;
  final action = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.exportTitle, style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.xs),
            Text(fileName, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.exportShare,
              icon: Icons.share_rounded,
              expand: true,
              onPressed: () => Navigator.pop(context, 'share'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(
              label: l10n.exportOpen,
              icon: Icons.open_in_new_rounded,
              expand: true,
              onPressed: () => Navigator.pop(context, 'open'),
            ),
          ],
        ),
      ),
    ),
  );
  if (action == 'open') {
    final opened = await openGeneratedFile(path: path, mimeType: kind.mimeType);
    if (!opened && context.mounted) showSnack(context, l10n.exportNoApp);
    return opened;
  }
  if (action == 'share') {
    await SharePlus.instance.share(ShareParams(
      title: fileName,
      files: [XFile(path, mimeType: kind.mimeType, name: fileName)],
    ));
    return true;
  }
  return false;
}
