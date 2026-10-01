import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../core/l10n/l10n.dart';

enum ComingSoonTitle { attendance, work }

/// Temporary tab body while a module is rebuilt in its own phase. Only
/// lives on the revamp integration branch; it never ships to `releases`.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.titleKey});

  final ComingSoonTitle titleKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (titleKey) {
      ComingSoonTitle.attendance => l10n.navAttendance,
      ComingSoonTitle.work => l10n.navWork,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        icon: Icons.construction_rounded,
        title: l10n.commonComingSoonTitle,
        message: l10n.commonComingSoonBody,
      ),
    );
  }
}
