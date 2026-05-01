import 'package:flutter/material.dart';

Future<bool?> showConfirmationBottomSheet({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String confirmLabel,
  required IconData confirmIcon,
  String cancelLabel = 'Cancelar',
  IconData cancelIcon = Icons.close,
  Color? iconColor,
  Color? confirmBackgroundColor,
  Color? confirmForegroundColor,
  String? headline,
  String? supportingText,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final effectiveIconColor = iconColor ?? scheme.error;
      final effectiveConfirmBackground = confirmBackgroundColor ?? scheme.error;
      final effectiveConfirmForeground =
          confirmForegroundColor ?? scheme.onError;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: effectiveIconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              if (headline != null) ...[
                const SizedBox(height: 10),
                Text(
                  headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
              if (supportingText != null) ...[
                const SizedBox(height: 6),
                Text(
                  supportingText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: Icon(cancelIcon),
                      label: Text(cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: effectiveConfirmBackground,
                        foregroundColor: effectiveConfirmForeground,
                      ),
                      icon: Icon(confirmIcon),
                      label: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
