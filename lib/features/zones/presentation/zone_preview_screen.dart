import 'package:flutter/material.dart';
import 'package:hulaki/design/app_colors.dart';
import 'package:hulaki/features/zones/domain/zone.dart';
import 'package:hulaki/features/zones/domain/zone_partition.dart';
import 'package:hulaki/features/zones/presentation/zone_manage_screen.dart';
import 'package:hulaki/features/zones/presentation/zone_map.dart';
import 'package:hulaki/l10n/app_localizations.dart';

/// Stages a candidate split over the mapping area so an admin sees it before
/// saving. Grid mode adjusts the count live; import mode shows the file as is.
/// Returns the chosen zones, or null when backed out.
class ZonePreviewScreen extends StatefulWidget {
  const ZonePreviewScreen.grid({required this.aoiGeoJson, super.key})
    : imported = null;

  const ZonePreviewScreen.imported({
    required this.aoiGeoJson,
    required List<Zone> zones,
    super.key,
  }) : imported = zones;

  final String aoiGeoJson;
  final List<Zone>? imported;

  @override
  State<ZonePreviewScreen> createState() => _ZonePreviewScreenState();
}

class _ZonePreviewScreenState extends State<ZonePreviewScreen> {
  int _count = 4;

  List<Zone> _split() =>
      widget.imported ??
      gridSplit(widget.aoiGeoJson, _count, palette: zoneColorPalette());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isGrid = widget.imported == null;
    final zones = _split();
    return Scaffold(
      appBar: AppBar(
        title: Text(isGrid ? l10n.zoneSplitEvenly : l10n.zoneImport),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ZoneMap(zones: zones, aoiGeoJson: widget.aoiGeoJson),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGrid)
                  _CountCard(
                    count: _count,
                    onLess: _count > 2 ? () => setState(() => _count--) : null,
                    onMore: _count < 8 ? () => setState(() => _count++) : null,
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: zones.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(zones),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.zoneUseSplit),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.count,
    required this.onLess,
    required this.onMore,
  });

  final int count;
  final VoidCallback? onLess;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onLess,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$count', style: Theme.of(context).textTheme.headlineSmall),
          IconButton(
            onPressed: onMore,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
