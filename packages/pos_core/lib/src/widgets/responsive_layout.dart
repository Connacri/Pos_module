import 'package:flutter/material.dart';

class ResponsiveLayout {
  ResponsiveLayout._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, bool, bool, bool) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < ResponsiveLayout.mobileBreakpoint;
        final isTablet = constraints.maxWidth >= ResponsiveLayout.mobileBreakpoint &&
            constraints.maxWidth < ResponsiveLayout.tabletBreakpoint;
        final isDesktop = constraints.maxWidth >= ResponsiveLayout.tabletBreakpoint;
        return builder(context, isMobile, isTablet, isDesktop);
      },
    );
  }
}
