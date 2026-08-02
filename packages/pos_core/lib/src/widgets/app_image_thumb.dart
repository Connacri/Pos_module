import 'package:flutter/material.dart';

/// Renders a rounded network-image thumbnail with a themed icon fallback when
/// no URL is set or the image fails to load. Used across inventory, POS and
/// billing so product photos appear consistently everywhere.
class AppImageThumb extends StatelessWidget {
  final String? url;
  final double size;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final Color? fallbackBackground;

  const AppImageThumb({
    super.key,
    this.url,
    this.size = 44,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackColor,
    this.fallbackBackground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = fallbackColor ?? theme.colorScheme.onSurfaceVariant;
    final background =
        fallbackBackground ?? theme.colorScheme.surfaceContainerHighest;

    final Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
      ),
      child: Icon(fallbackIcon, size: size * 0.5, color: color),
    );

    if (url == null || url!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => fallback,
      ),
    );
  }
}