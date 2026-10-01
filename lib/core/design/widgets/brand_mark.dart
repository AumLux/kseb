import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// AumLux mark: navy bolt on the orange brand tile (navy-on-orange is AA).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AumLux',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(size * 0.22),
        ),
        child: Icon(Icons.bolt_rounded, color: AppColors.onPrimary, size: size * 0.6),
      ),
    );
  }
}
