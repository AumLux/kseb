import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../data/staff_repository.dart';

/// Shows a newly issued temporary password exactly once. Not dismissible by
/// tapping outside, so it isn't lost by accident.
Future<void> showCredentialsSheet(BuildContext context, String name, IssuedCredentials creds) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (context) {
      final l10n = context.l10n;
      Widget row(String label, String value) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppTypography.caption),
                        SelectableText(value, style: AppTypography.bodyTabular.copyWith(fontSize: 18)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.credentialsCopy,
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: value));
                      if (context.mounted) showSnack(context, l10n.credentialsCopied);
                    },
                  ),
                ],
              ),
            ),
          );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.credentialsTitle, style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.credentialsBody(name), style: AppTypography.body),
              const SizedBox(height: AppSpacing.xl),
              row(l10n.credentialsLoginId, creds.loginId),
              row(l10n.credentialsPassword, creds.tempPassword),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.credentialsDone,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
