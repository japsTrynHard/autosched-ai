import 'package:flutter/material.dart';

import 'brand_logo.dart';

class AutoTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AutoTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppBar(
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: automaticallyImplyLeading ? null : 16,
      title: Row(
        children: [
          const AutoSchedMark(size: 42, borderRadius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
