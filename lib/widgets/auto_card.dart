import 'package:flutter/material.dart';

class AutoCard extends StatelessWidget {
  const AutoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
