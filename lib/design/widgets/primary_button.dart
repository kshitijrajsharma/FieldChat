import 'package:fieldchat/design/app_colors.dart';
import 'package:fieldchat/design/app_spacing.dart';
import 'package:flutter/material.dart';

/// The ink call-to-action used for the one primary action on a screen:
/// Continue, Create group, Export. Full width by default.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.trailingIcon,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;

  /// Shows a spinner and blocks taps while an action is in flight, so a slow
  /// create, join or export reads as working rather than stuck.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    // While loading the button keeps its active ink look so the spinner reads.
    final disabled = onPressed == null && !loading;
    final foreground = disabled ? AppColors.textFaint : AppColors.white;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: disabled ? AppColors.mist : AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadii.field),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                if (trailingIcon != null && !loading) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: 18, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
