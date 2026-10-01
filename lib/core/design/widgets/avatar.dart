import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// Initials on a soft tint that is stable per person (same name → same
/// colour everywhere), for people lists and map pins.
class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.size = 40});

  final String name;
  final double size;

  static const _tints = [
    AppColors.primaryDeep,
    AppColors.brandOrangeInk,
    AppColors.success,
    AppColors.info,
    AppColors.ruby,
    AppColors.warning,
  ];

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  static Color tintFor(String name) => _tints[name.trim().toLowerCase().hashCode.abs() % _tints.length];

  @override
  Widget build(BuildContext context) {
    final tint = tintFor(name);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Text(
          initials(name),
          style: AppTypography.label.copyWith(color: tint, fontWeight: FontWeight.w700, fontSize: size * 0.36, height: 1),
        ),
      ),
    );
  }
}
