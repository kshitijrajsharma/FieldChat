import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:hulaki/features/zones/domain/zone.dart';
import 'package:hulaki/features/zones/presentation/zone_manage_screen.dart';
import 'package:hulaki/features/zones/presentation/zone_preview_screen.dart';
import 'package:hulaki/features/zones/presentation/zone_seed_screen.dart';
import 'package:hulaki/l10n/app_localizations.dart';

enum _SplitMethod { grid, seeds, import }

/// Offers the three split methods and returns the chosen zones, or null when
/// dismissed. Each method stages a live preview before returning. Shared by
/// group creation and any other entry point that needs a split for an area.
Future<List<Zone>?> pickZoneSplit(
  BuildContext context,
  String aoiGeoJson,
) async {
  final method = await showModalBottomSheet<_SplitMethod>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.grid_view_outlined),
              title: Text(l10n.zoneSplitEvenly),
              subtitle: Text(l10n.zoneSplitEvenlyDetail),
              onTap: () => Navigator.of(sheetContext).pop(_SplitMethod.grid),
            ),
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(l10n.zoneSplitSeeds),
              subtitle: Text(l10n.zoneSplitSeedsDetail),
              onTap: () => Navigator.of(sheetContext).pop(_SplitMethod.seeds),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: Text(l10n.zoneImport),
              subtitle: Text(l10n.zoneImportDetail),
              onTap: () => Navigator.of(sheetContext).pop(_SplitMethod.import),
            ),
          ],
        ),
      );
    },
  );
  if (method == null || !context.mounted) return null;
  switch (method) {
    case _SplitMethod.grid:
      return Navigator.of(context).push<List<Zone>>(
        MaterialPageRoute<List<Zone>>(
          builder: (_) => ZonePreviewScreen.grid(aoiGeoJson: aoiGeoJson),
        ),
      );
    case _SplitMethod.seeds:
      return Navigator.of(context).push<List<Zone>>(
        MaterialPageRoute<List<Zone>>(
          builder: (_) => ZoneSeedScreen(aoiGeoJson: aoiGeoJson),
        ),
      );
    case _SplitMethod.import:
      final file = await openFile();
      if (file == null || !context.mounted) return null;
      final text = utf8.decode(await file.readAsBytes());
      final zones = zonesFromImport(text, palette: zoneColorPalette());
      if (zones.isEmpty || !context.mounted) return null;
      return Navigator.of(context).push<List<Zone>>(
        MaterialPageRoute<List<Zone>>(
          builder: (_) =>
              ZonePreviewScreen.imported(aoiGeoJson: aoiGeoJson, zones: zones),
        ),
      );
  }
}
