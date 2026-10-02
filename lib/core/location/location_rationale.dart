import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../l10n/l10n.dart';
import 'location_service.dart';

/// Explains *why* before Android's location prompt (shown once, only while
/// permission hasn't been decided yet). Returns false if the user backs out.
Future<bool> explainLocationIfNeeded(BuildContext context, WidgetRef ref) async {
  if (!await ref.read(locationServiceProvider).permissionUndecided()) return true;
  if (!context.mounted) return false;
  final l10n = context.l10n;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isDismissible: false,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.location_on_rounded, size: AppSizes.iconEmpty, color: AppColors.primaryInk),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.locRationaleTitle, style: AppTypography.subtitle, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.locRationaleBody, style: AppTypography.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: l10n.commonContinue, expand: true, onPressed: () => Navigator.pop(context, true)),
          const SizedBox(height: AppSpacing.sm),
          AppButton.tertiary(label: l10n.commonCancel, onPressed: () => Navigator.pop(context, false)),
        ]),
      ),
    ),
  );
  return ok ?? false;
}
