import 'package:flutter/material.dart';

import '../design/design.dart';
import '../l10n/l10n.dart';
import 'sheets.dart';

/// Confirmation for consequential actions, as a bottom sheet (thumb-reach
/// buttons, like the rest of the app's prompts). The title states the
/// consequence; [destructive] colours the confirm action as danger.
Future<bool> confirmAction(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  String? title,
  bool destructive = false,
  IconData? icon,
}) async {
  final l10n = context.l10n;
  final tone = destructive ? AppColors.danger : AppColors.primary;
  final ok = await showAppSheet<bool>(
    context,
    builder: (context) => SheetScaffold(
      title: title ?? message,
      primaryLabel: confirmLabel,
      primaryDestructive: destructive,
      onPrimary: () => Navigator.pop(context, true),
      secondaryLabel: l10n.commonCancel,
      onSecondary: () => Navigator.pop(context, false),
      leading: IconTile(icon ?? (destructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded), color: tone),
      children: [
        if (title != null) Text(message, style: AppTypography.body.copyWith(color: AppColors.inkSecondary)),
      ],
    ),
  );
  return ok ?? false;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
