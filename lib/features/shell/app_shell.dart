import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design.dart';
import '../../core/l10n/l10n.dart';
import '../../core/media/photo_strip.dart';
import '../../core/ui/dialogs.dart';

/// Signed-in chrome: bottom navigation on phones, a navigation rail from
/// 600dp (DESIGN.md › Layout), plus the offline banner.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Tapping a tab always lands on that tab's main screen (e.g. More → the
  /// menu, not the Inventory page left open there earlier).
  void _go(int index) {
    if (index != navigationShell.currentIndex) HapticFeedback.selectionClick();
    navigationShell.goBranch(index, initialLocation: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // A photo taken while Android had killed the app is attached on return.
    ref.listen(photoRecoveryProvider, (_, next) {
      if ((next.value ?? 0) > 0) showSnack(context, l10n.photoRecovered);
    });
    final destinations = [
      (Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      (Icons.fingerprint_rounded, Icons.fingerprint_rounded, l10n.navAttendance),
      (Icons.handyman_outlined, Icons.handyman_rounded, l10n.navWork),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, l10n.navMore),
    ];

    final body = navigationShell;

    return LayoutBuilder(builder: (context, constraints) {
      // The rail is for genuinely large screens. A phone in landscape is wide
      // but only ~360dp tall, so it keeps the bottom bar (height is scarce).
      final useRail = constraints.maxWidth >= 600 && constraints.maxHeight >= 480;
      if (useRail) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                right: false,
                child: LayoutBuilder(
                  // Scrolls instead of overflowing when the window is short.
                  builder: (context, rail) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: rail.maxHeight),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          selectedIndex: navigationShell.currentIndex,
                          onDestinationSelected: _go,
                          labelType: NavigationRailLabelType.all,
                          groupAlignment: -0.85,
                          leading: const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: BrandMark(size: 40),
                          ),
                          destinations: [
                            for (final (icon, selected, label) in destinations)
                              NavigationRailDestination(
                                icon: Icon(icon),
                                selectedIcon: Icon(selected),
                                label: Text(label),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: SafeArea(left: false, top: false, bottom: false, child: body)),
            ],
          ),
        );
      }
      return Scaffold(
        // Keeps content clear of a landscape camera cutout.
        body: SafeArea(top: false, bottom: false, child: body),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _go,
            animationDuration: AppMotion.base,
            // Shorter bar in landscape, where vertical space is precious.
            height: constraints.maxHeight < 480 ? 60 : null,
            labelBehavior: constraints.maxHeight < 480
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : null,
            destinations: [
              for (final (icon, selected, label) in destinations)
                NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
            ],
          ),
        ),
      );
    });
  }
}
