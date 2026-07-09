import 'dart:async';

import 'package:fieldchat/design/app_colors.dart';
import 'package:fieldchat/design/app_spacing.dart';
import 'package:flutter/material.dart';

/// The quality tier a live accuracy reading falls into. Thresholds in metres:
/// excellent <= 5, good <= 10, weak <= 15, poor above that.
enum _GpsTier { acquiring, poor, weak, good, excellent }

/// A compact live GPS readout: a pulsing dot that beats on each new fix, four
/// signal bars whose filled count and colour track accuracy, a label, and the
/// accuracy in metres.
class GpsStrip extends StatefulWidget {
  const GpsStrip({
    required this.accuracyMeters,
    this.onTap,
    this.pulseKey,
    super.key,
  });

  final double? accuracyMeters;
  final VoidCallback? onTap;

  /// Changes whenever a fresh fix arrives, which triggers one dot beat.
  final Object? pulseKey;

  @override
  State<GpsStrip> createState() => _GpsStripState();
}

class _GpsStripState extends State<GpsStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  late final Animation<double> _beat = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.5,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.5,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 65,
    ),
  ]).animate(_pulse);

  late final Animation<double> _dotFlash = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.4,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 0.4,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 65,
    ),
  ]).animate(_pulse);

  _GpsTier get _tier {
    final m = widget.accuracyMeters;
    if (m == null) return _GpsTier.acquiring;
    if (m <= 5) return _GpsTier.excellent;
    if (m <= 10) return _GpsTier.good;
    if (m <= 15) return _GpsTier.weak;
    return _GpsTier.poor;
  }

  @override
  void didUpdateWidget(GpsStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tier != _GpsTier.acquiring && widget.pulseKey != oldWidget.pulseKey) {
      unawaited(_pulse.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tier;
    final Color tone;
    final String label;
    final int level;
    switch (tier) {
      case _GpsTier.acquiring:
        tone = AppColors.textMuted;
        label = 'Locating GPS…';
        level = 0;
      case _GpsTier.excellent:
        tone = AppColors.gpsStrong;
        label = 'Excellent';
        level = 4;
      case _GpsTier.good:
        tone = AppColors.gpsGood;
        label = 'Good';
        level = 3;
      case _GpsTier.weak:
        tone = AppColors.amber;
        label = 'Weak';
        level = 2;
      case _GpsTier.poor:
        tone = AppColors.danger;
        label = 'Poor';
        level = 1;
    }
    final acquiring = tier == _GpsTier.acquiring;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 10,
              child: Center(
                child: _LiveDot(
                  color: tone,
                  acquiring: acquiring,
                  beat: _beat,
                  flash: _dotFlash,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _QualityBars(level: level, color: tone),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tone,
              ),
            ),
            const Spacer(),
            if (!acquiring)
              Text(
                '±${widget.accuracyMeters!.round()} m',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tone,
                ),
              ),
            if (widget.onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 15, color: tone),
            ],
          ],
        ),
      ),
    );
  }
}

/// The pulsing fix indicator. It beats on each new fix; while acquiring it sits
/// dim and still.
class _LiveDot extends StatelessWidget {
  const _LiveDot({
    required this.color,
    required this.acquiring,
    required this.beat,
    required this.flash,
  });

  final Color color;
  final bool acquiring;
  final Animation<double> beat;
  final Animation<double> flash;

  @override
  Widget build(BuildContext context) {
    if (acquiring) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.textFaint.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
      );
    }
    return ScaleTransition(
      scale: beat,
      child: FadeTransition(
        opacity: flash,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Four ascending bars; the first [level] are filled with [color] and the rest
/// sit faint, so the count and colour together read as signal quality.
class _QualityBars extends StatelessWidget {
  const _QualityBars({required this.level, required this.color});

  final int level;
  final Color color;

  static const _heights = <double>[5, 7.5, 10, 12.5];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < _heights.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == _heights.length - 1 ? 0 : 2),
            child: Container(
              width: 3,
              height: _heights[i],
              decoration: BoxDecoration(
                color: i < level
                    ? color
                    : AppColors.ink.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
      ],
    );
  }
}
