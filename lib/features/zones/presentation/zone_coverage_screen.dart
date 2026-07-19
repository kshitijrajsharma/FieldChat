import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulaki/app/providers.dart';
import 'package:hulaki/design/app_colors.dart';
import 'package:hulaki/design/app_snackbar.dart';
import 'package:hulaki/features/zones/domain/zone_bucketing.dart';
import 'package:hulaki/features/zones/presentation/zone_map.dart';
import 'package:hulaki/l10n/app_localizations.dart';

/// Admin-only coverage: a map of the zones over the list, so which area is
/// which is clear. Tapping a zone expands its full mapper list and highlights
/// it on the map. Names show only here (like the hidden roster); anonymous
/// points count but stay unnamed.
class ZoneCoverageScreen extends ConsumerStatefulWidget {
  const ZoneCoverageScreen({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<ZoneCoverageScreen> createState() => _ZoneCoverageScreenState();
}

class _ZoneCoverageScreenState extends ConsumerState<ZoneCoverageScreen> {
  String? _selectedZoneId;

  Future<void> _rename(String zoneId, String currentName) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.zoneRenameTitle),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.threadCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.threadSave),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final all =
        ref.read(zonesProvider(widget.groupId)).asData?.value ?? const [];
    final updated = [
      for (final zone in all)
        if (zone.id == zoneId) zone.copyWith(name: name) else zone,
    ];
    await ref.read(groupServiceProvider).setZones(widget.groupId, updated);
    if (mounted) context.showSuccess(l10n.zoneRenamed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final zones =
        ref.watch(zonesProvider(widget.groupId)).asData?.value ?? const [];
    final members =
        ref.watch(groupMembersProvider(widget.groupId)).asData?.value ??
        const [];
    final messages =
        ref.watch(messagesProvider(widget.groupId)).asData?.value ?? const [];

    final counts = countsByZone(zones, [
      for (final m in messages)
        if (m.lat != null && m.lng != null) (lat: m.lat!, lng: m.lng!),
    ]);
    final total = counts.values.fold(0, (a, b) => a + b);

    final ordered = [...zones]
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(l10n.zoneCoverageTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (zones.isNotEmpty)
            SizedBox(
              height: 220,
              child: ZoneMap(zones: zones, selectedZoneId: _selectedZoneId),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.zoneCoverageSummary(total, zones.length),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.zoneCoverageExplain,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final zone in ordered)
                  _CoverageRow(
                    name: zone.name,
                    colorValue: zone.colorValue,
                    points: counts[zone.id] ?? 0,
                    mappers: [
                      for (final m in members)
                        if (m.assignedZoneId == zone.id) m.name,
                    ],
                    expanded: _selectedZoneId == zone.id,
                    onTap: () => setState(
                      () => _selectedZoneId = _selectedZoneId == zone.id
                          ? null
                          : zone.id,
                    ),
                    onRename: () => unawaited(_rename(zone.id, zone.name)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverageRow extends StatelessWidget {
  const _CoverageRow({
    required this.name,
    required this.colorValue,
    required this.points,
    required this.mappers,
    required this.expanded,
    required this.onTap,
    required this.onRename,
  });

  final String name;
  final int colorValue;
  final int points;
  final List<String> mappers;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onRename;

  /// Two names then a count when collapsed; the whole team when expanded.
  String _mappersLabel(AppLocalizations l10n) {
    if (mappers.isEmpty) return l10n.zoneNeedsMapper;
    if (expanded || mappers.length <= 2) return mappers.join(', ');
    return '${mappers.take(2).join(', ')} +${mappers.length - 2}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context).textTheme;
    return ListTile(
      onTap: onTap,
      selected: expanded,
      selectedTileColor: AppColors.mist,
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Color(colorValue),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(name, style: theme.titleMedium)),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRename,
            borderRadius: BorderRadius.circular(99),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        _mappersLabel(l10n),
        maxLines: expanded ? null : 1,
        overflow: expanded ? null : TextOverflow.ellipsis,
        style: theme.bodySmall?.copyWith(
          color: mappers.isEmpty
              ? AppColors.amberText
              : AppColors.textSecondary,
          fontWeight: mappers.isEmpty ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: Text('$points', style: theme.titleLarge),
    );
  }
}
