import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulaki/app/providers.dart';
import 'package:hulaki/design/app_colors.dart';
import 'package:hulaki/features/zones/domain/zone_bucketing.dart';
import 'package:hulaki/l10n/app_localizations.dart';

/// Admin-only coverage: each zone with its members and point count. Names show
/// only here (like the hidden roster); anonymous points count but stay unnamed.
class ZoneCoverageScreen extends ConsumerWidget {
  const ZoneCoverageScreen({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final zones = ref.watch(zonesProvider(groupId)).asData?.value ?? const [];
    final members =
        ref.watch(groupMembersProvider(groupId)).asData?.value ?? const [];
    final messages =
        ref.watch(messagesProvider(groupId)).asData?.value ?? const [];

    final counts = countsByZone(zones, [
      for (final m in messages)
        if (m.lat != null && m.lng != null) (lat: m.lat!, lng: m.lng!),
    ]);
    final total = counts.values.fold(0, (a, b) => a + b);

    final ordered = [...zones]
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.zoneCoverageTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.zoneCoverageSummary(total, zones.length),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          for (final zone in ordered)
            _CoverageRow(
              name: zone.name,
              colorValue: zone.colorValue,
              points: counts[zone.id] ?? 0,
              mappers: [
                for (final m in members)
                  if (m.assignedZoneId == zone.id) m.name,
              ],
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
  });

  final String name;
  final int colorValue;
  final int points;
  final List<String> mappers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context).textTheme;
    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Color(colorValue),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(name, style: theme.titleMedium),
      subtitle: Text(
        mappers.isEmpty ? l10n.zoneNeedsMapper : mappers.join(', '),
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
