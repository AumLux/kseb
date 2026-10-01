import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// Persistent banner shown while the device has no connectivity
/// (DESIGN.md › Offline & sync).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.message = "You're offline. Changes will sync when you're back online.",
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: AppColors.warningBg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: AppSizes.iconMd, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.label.copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "N pending" badge for items waiting in the offline outbox.
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.pending, this.onTap});

  final int pending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (pending <= 0) return const SizedBox.shrink();
    return Semantics(
      button: onTap != null,
      label: '$pending items waiting to sync',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
          decoration: const BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: AppRadius.pillAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sync_rounded,
                  size: AppSizes.iconSm, color: AppColors.info),
              const SizedBox(width: AppSpacing.xs),
              Text('$pending pending',
                  style: AppTypography.label.copyWith(color: AppColors.info)),
            ],
          ),
        ),
      ),
    );
  }
}
