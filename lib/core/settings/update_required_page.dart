import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/design.dart';
import '../l10n/l10n.dart';
import 'app_settings.dart';

/// Blocks an outdated Android build (server `min_app_build`). Data waiting
/// in the outbox stays on the phone and syncs after updating.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const BrandMark(size: 64),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.updateTitle, style: AppTypography.headline, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.updateBody, style: AppTypography.body, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: l10n.updateButton,
                icon: Icons.system_update_rounded,
                expand: true,
                onPressed: () => launchUrl(Uri.parse(latestApkUrl), mode: LaunchMode.externalApplication),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
