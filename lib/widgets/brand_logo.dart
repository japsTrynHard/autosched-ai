import 'package:flutter/material.dart';

import '../branding/auto_sched_brand_assets.dart';

class AutoSchedMark extends StatelessWidget {
  const AutoSchedMark({
    super.key,
    this.size = 42,
    this.borderRadius = 14,
    this.showBorder = true,
  });

  final double size;
  final double borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder ? Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.45)) : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.memory(
        AutoSchedBrandAssets.iconLogoBytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}

class AutoSchedFullLogo extends StatelessWidget {
  const AutoSchedFullLogo({
    super.key,
    this.height = 96,
    this.fit = BoxFit.contain,
  });

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      AutoSchedBrandAssets.fullLogoBytes,
      height: height,
      fit: fit,
      gaplessPlayback: true,
    );
  }
}
