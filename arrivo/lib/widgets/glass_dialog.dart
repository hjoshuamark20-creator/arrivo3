import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'glass_button.dart';
import 'glass_card.dart';
import 'primary_button.dart';

/// Glass confirmation dialog. Returns true when the user confirms.
Future<bool> showGlassConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x66000000),
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: GlassCard(
          radius: 32,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: text.titleLarge),
              const SizedBox(height: 10),
              Text(message, style: text.bodyMedium),
              const SizedBox(height: 22),
              if (destructive)
                GlassButton(
                  label: confirmLabel,
                  color: Theme.of(ctx).colorScheme.error,
                  onPressed: () => Navigator.of(ctx).pop(true),
                )
              else
                PrimaryButton(
                  label: confirmLabel,
                  color: AppColors.teal,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              const SizedBox(height: 10),
              GlassButton(label: cancelLabel, onPressed: () => Navigator.of(ctx).pop(false)),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
