import 'package:flutter/material.dart';

class AppResponsiveBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxContentWidth;
  final bool safeArea;

  const AppResponsiveBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.maxContentWidth = 1400,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (safeArea) {
      content = SafeArea(child: content);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 1200
            ? 32.0
            : constraints.maxWidth >= 600
            ? 24.0
            : 16.0;
        final vertical = constraints.maxWidth >= 900 ? 24.0 : 12.0;
        final effectivePadding = padding is EdgeInsets
            ? EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical)
            : padding;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(padding: effectivePadding, child: content),
          ),
        );
      },
    );
  }
}
