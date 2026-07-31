import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outlined, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _getForegroundColor(theme),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(label),
            ],
          );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(onPressed: onPressed, child: child);
        break;
      case AppButtonVariant.secondary:
        button = FilledButton.tonal(onPressed: onPressed, child: child);
        break;
      case AppButtonVariant.outlined:
        button = OutlinedButton(onPressed: onPressed, child: child);
        break;
      case AppButtonVariant.text:
        button = TextButton(onPressed: onPressed, child: child);
        break;
      case AppButtonVariant.danger:
        button = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: child,
        );
        break;
    }

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color _getForegroundColor(ThemeData theme) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return theme.colorScheme.onPrimary;
      case AppButtonVariant.secondary:
        return theme.colorScheme.onSecondaryContainer;
      default:
        return theme.colorScheme.primary;
    }
  }
}
