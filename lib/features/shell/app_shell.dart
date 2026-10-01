import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity/connectivity_provider.dart';
import '../../core/design/design.dart';
import '../../core/l10n/l10n.dart';

/// Signed-in chrome: bottom navigation on phones, a navigation rail from
/// 600dp (DESIGN.md › Layout), plus the offline banner.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final online = ref.watch(onlineProvider).value ?? true;
    final destinations = [
      (Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      (Icons.how_to_reg_outlined, Icons.how_to_reg_rounded, l10n.navAttendance),
      (Icons.assignment_outlined, Icons.assignment_rounded, l10n.navWork),
      (Icons.menu_rounded, Icons.menu_rounded, l10n.navMore),
    ];

    final body = Column(
      children: [
        if (!online) SafeArea(bottom: false, child: OfflineBanner(message: l10n.offlineBanner)),
        Expanded(child: navigationShell),
      ],
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 600) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _go,
                labelType: NavigationRailLabelType.all,
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
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      }
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _go,
          destinations: [
            for (final (icon, selected, label) in destinations)
              NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
          ],
        ),
      );
    });
  }
}
