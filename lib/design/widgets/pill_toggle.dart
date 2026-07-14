import 'package:flutter/material.dart';
import 'package:hulaki/design/app_colors.dart';

/// A two-option toggle: a white pill holding a sliding ink segment for the
/// selected side. Shared by the map and communities scope switches so they read
/// the same. [rightSelected] is false for [left], true for [right].
class PillToggle extends StatelessWidget {
  const PillToggle({
    required this.left,
    required this.right,
    required this.rightSelected,
    required this.onChanged,
    this.leftEnabled = true,
    this.rightEnabled = true,
    this.elevation = 0,
    super.key,
  });

  final String left;
  final String right;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;
  final bool leftEnabled;
  final bool rightEnabled;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: elevation,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(
              label: left,
              selected: !rightSelected,
              enabled: leftEnabled,
              onTap: () => onChanged(false),
            ),
            _Segment(
              label: right,
              selected: rightSelected,
              enabled: rightEnabled,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.textFaint
        : (selected ? AppColors.white : AppColors.ink);
    return Material(
      color: selected ? AppColors.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
