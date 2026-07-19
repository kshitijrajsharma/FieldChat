import 'package:flutter/material.dart';
import 'package:hulaki/design/app_colors.dart';

enum FeedbackKind { success, error, info }

/// A feedback snackbar in the light house style: a white surface with plain ink
/// text and no icon, plus a thin left edge in a soft accent as the only colour,
/// so a success and an error stay apart while reading black and white. Built as
/// a value so it can be shown through a captured [ScaffoldMessengerState] as
/// well as through [BuildContext].
SnackBar feedbackSnackBar(String message, FeedbackKind kind) {
  final edge = switch (kind) {
    FeedbackKind.success => AppColors.success,
    FeedbackKind.error => AppColors.dangerSoft,
    FeedbackKind.info => AppColors.mist,
  };
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    content: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mist),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: edge),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                  child: Text(
                    message,
                    style: const TextStyle(color: AppColors.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

extension AppSnackbar on BuildContext {
  void showSuccess(String message) => _show(message, FeedbackKind.success);
  void showError(String message) => _show(message, FeedbackKind.error);
  void showInfo(String message) => _show(message, FeedbackKind.info);

  void _show(String message, FeedbackKind kind) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(feedbackSnackBar(message, kind));
  }
}
