import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hulaki/design/app_colors.dart';
import 'package:hulaki/features/export/geojson.dart';
import 'package:hulaki/features/zones/domain/zone.dart';
import 'package:hulaki/features/zones/domain/zone_partition.dart';
import 'package:hulaki/features/zones/presentation/zone_manage_screen.dart';
import 'package:hulaki/l10n/app_localizations.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Drop a seed where each team starts; the area partitions to the nearest seed.
/// Returns the resulting zones, or null if backed out. Live-previews the split
/// as seeds are added.
class ZoneSeedScreen extends StatefulWidget {
  const ZoneSeedScreen({required this.aoiGeoJson, super.key});

  final String aoiGeoJson;

  static const _styleUrl =
      'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';

  @override
  State<ZoneSeedScreen> createState() => _ZoneSeedScreenState();
}

class _ZoneSeedScreenState extends State<ZoneSeedScreen> {
  MapLibreMapController? _controller;
  final List<LatLng> _seeds = [];
  final List<Circle> _seedCircles = [];

  List<Zone> _split() => _seeds.length < 2
      ? const []
      : seedSplit(
          widget.aoiGeoJson,
          [
            for (final s in _seeds) [s.longitude, s.latitude],
          ],
          palette: zoneColorPalette(),
        );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.zoneSeedTitle),
        actions: [
          if (_seeds.isNotEmpty)
            TextButton(
              onPressed: () => unawaited(_undo()),
              child: Text(l10n.groupUndo),
            ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: ZoneSeedScreen._styleUrl,
            initialCameraPosition: const CameraPosition(
              target: LatLng(27.7051, 85.3051),
              zoom: 13,
            ),
            onMapCreated: (controller) => _controller = controller,
            onStyleLoadedCallback: () => unawaited(_onStyleLoaded()),
            onMapClick: _onTap,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 6),
                    ],
                  ),
                  child: Text(
                    _seeds.length < 2
                        ? l10n.zoneSeedHint
                        : l10n.zoneSeedCount(_seeds.length),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _seeds.length >= 2 ? _use : null,
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

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.addGeoJsonSource(
      'aoi',
      jsonDecode(widget.aoiGeoJson) as Map<String, dynamic>,
    );
    await controller.addLineLayer(
      'aoi',
      'aoi-line',
      const LineLayerProperties(lineColor: '#E0922A', lineWidth: 1.5),
    );
    await controller.addGeoJsonSource('zones-preview', _empty());
    await controller.addLineLayer(
      'zones-preview',
      'zones-preview-line',
      const LineLayerProperties(
        lineColor: [Expressions.get, 'lineColor'],
        lineWidth: 2,
      ),
    );
    controller.onFeatureDrag.add(_onSeedDrag);

    final bounds = aoiBounds(widget.aoiGeoJson);
    if (bounds != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(bounds[1], bounds[0]),
            northeast: LatLng(bounds[3], bounds[2]),
          ),
          left: 40,
          right: 40,
          top: 80,
          bottom: 160,
        ),
      );
    }
  }

  Future<void> _onTap(Point<double> point, LatLng latLng) async {
    final controller = _controller;
    if (controller == null) return;
    final circle = await controller.addCircle(
      CircleOptions(
        geometry: latLng,
        circleColor: '#15181B',
        circleStrokeColor: '#ffffff',
        circleStrokeWidth: 2,
        circleRadius: 8,
        draggable: true,
      ),
    );
    setState(() {
      _seeds.add(latLng);
      _seedCircles.add(circle);
    });
    await _redrawPreview();
  }

  /// Follows a seed as it is dragged, re-flowing the split live so a boundary
  /// can be nudged off a feature it would otherwise cut.
  void _onSeedDrag(
    Point<double> point,
    LatLng origin,
    LatLng current,
    LatLng delta,
    String id,
    Annotation? annotation,
    DragEventType eventType,
  ) {
    final index = _seedCircles.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _seeds[index] = current;
    unawaited(_redrawPreview());
  }

  Future<void> _undo() async {
    if (_seeds.isEmpty) return;
    final circle = _seedCircles.removeLast();
    await _controller?.removeCircle(circle);
    setState(_seeds.removeLast);
    await _redrawPreview();
  }

  Future<void> _redrawPreview() async {
    await _controller?.setGeoJsonSource('zones-preview', _previewFeatures());
  }

  void _use() => Navigator.of(context).pop(_split());

  Map<String, dynamic> _previewFeatures() => {
    'type': 'FeatureCollection',
    'features': [
      for (final zone in _split())
        {
          'type': 'Feature',
          'properties': {'lineColor': _hex(zone.colorValue)},
          'geometry': {
            'type': 'MultiPolygon',
            'coordinates': [
              for (final ring in zone.pieces) [ring],
            ],
          },
        },
    ],
  };

  Map<String, dynamic> _empty() => {
    'type': 'FeatureCollection',
    'features': <dynamic>[],
  };

  String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
