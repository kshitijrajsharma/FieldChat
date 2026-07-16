import 'dart:math';

import 'package:clipper2/clipper2.dart';
import 'package:hulaki/features/export/geojson.dart';
import 'package:hulaki/features/zones/domain/zone.dart';

/// Splits the area into [n] roughly even grid tiles, each clipped to it. Fewer
/// than [n] when tiles miss the area; empty when it has no polygon or [n] < 2.
List<Zone> gridSplit(
  String aoiGeoJson,
  int n, {
  required List<int> palette,
}) {
  if (n < 2) return const [];
  final bounds = aoiBounds(aoiGeoJson);
  if (bounds == null) return const [];
  final proj = _Projection.forBounds(bounds);
  final subject = _project(aoiGeoJson, proj);
  if (subject.isEmpty) return const [];

  final width = (bounds[2] - bounds[0]) * proj.mPerDegLng;
  final height = (bounds[3] - bounds[1]) * proj.mPerDegLat;
  final rows = max(1, sqrt(n).round());
  final cols = (n / rows).ceil();
  final cellW = width / cols;
  final cellH = height / rows;

  final zones = <Zone>[];
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final tile = _rect(
        c * cellW,
        r * cellH,
        (c + 1) * cellW,
        (r + 1) * cellH,
      );
      final clipped = Clipper.intersectD(
        subject: subject,
        clip: [tile],
        fillRule: FillRule.nonZero,
      );
      final pieces = _piecesFrom(clipped, proj);
      if (pieces.isEmpty) continue;
      final index = zones.length;
      zones.add(
        Zone(
          id: 'z$index',
          name: 'Area ${index + 1}',
          colorValue: palette[index % palette.length],
          pieces: pieces,
        ),
      );
    }
  }
  return zones;
}

/// Splits the area by nearest seed (each cell is the area minus the far side of
/// every bisector), giving a gap-free partition. Empty when the area has no
/// polygon or fewer than two seeds; skips seeds a closer one fully shadows.
List<Zone> seedSplit(
  String aoiGeoJson,
  List<List<double>> seedsLngLat, {
  required List<int> palette,
}) {
  if (seedsLngLat.length < 2) return const [];
  final bounds = aoiBounds(aoiGeoJson);
  if (bounds == null) return const [];
  final proj = _Projection.forBounds(bounds);
  final subject = _project(aoiGeoJson, proj);
  if (subject.isEmpty) return const [];

  final seeds = [
    for (final s in seedsLngLat) proj.project(s[0], s[1]),
  ];
  final width = (bounds[2] - bounds[0]) * proj.mPerDegLng;
  final height = (bounds[3] - bounds[1]) * proj.mPerDegLat;
  final reach = 10 * sqrt(width * width + height * height);

  final zones = <Zone>[];
  for (var i = 0; i < seeds.length; i++) {
    var cell = subject;
    for (var j = 0; j < seeds.length && cell.isNotEmpty; j++) {
      if (i == j) continue;
      final half = _bisectorHalfPlane(seeds[i], seeds[j], reach);
      if (half == null) continue;
      cell = Clipper.intersectD(
        subject: cell,
        clip: [half],
        fillRule: FillRule.nonZero,
      );
    }
    final pieces = _piecesFrom(cell, proj);
    if (pieces.isEmpty) continue;
    final index = zones.length;
    zones.add(
      Zone(
        id: 'z$index',
        name: 'Area ${index + 1}',
        colorValue: palette[index % palette.length],
        pieces: pieces,
      ),
    );
  }
  return zones;
}

/// The half-plane of points closer to [a] than to [b], as a large rectangle
/// with one edge on the bisector. Null when the seeds coincide.
PathD? _bisectorHalfPlane(PointD a, PointD b, double reach) {
  final nx = a.x - b.x;
  final ny = a.y - b.y;
  final len = sqrt(nx * nx + ny * ny);
  if (len < 1e-6) return null;
  final ux = nx / len;
  final uy = ny / len;
  final mx = (a.x + b.x) / 2;
  final my = (a.y + b.y) / 2;
  final dx = -uy;
  final dy = ux;
  return [
    PointD(mx + dx * reach, my + dy * reach),
    PointD(mx - dx * reach, my - dy * reach),
    PointD(mx - dx * reach + ux * reach, my - dy * reach + uy * reach),
    PointD(mx + dx * reach + ux * reach, my + dy * reach + uy * reach),
  ];
}

PathD _rect(double minX, double minY, double maxX, double maxY) => [
  PointD(minX, minY),
  PointD(maxX, minY),
  PointD(maxX, maxY),
  PointD(minX, maxY),
];

PathsD _project(String aoiGeoJson, _Projection proj) => [
  for (final ring in polygonRings(aoiGeoJson))
    if (ring.length >= 3) [for (final p in ring) proj.project(p[0], p[1])],
];

List<List<List<double>>> _piecesFrom(PathsD paths, _Projection proj) {
  final pieces = <List<List<double>>>[];
  for (final path in paths) {
    if (path.length < 3) continue;
    final ring = [for (final p in path) proj.unproject(p.x, p.y)];
    final first = ring.first;
    final last = ring.last;
    if (first[0] != last[0] || first[1] != last[1]) ring.add(first);
    pieces.add(ring);
  }
  return pieces;
}

/// Equirectangular projection to local metres, keeping clipper2's integer
/// scaling in a safe range and making "nearest seed" nearest on the ground.
class _Projection {
  _Projection(this.lng0, this.lat0, this.mPerDegLng, this.mPerDegLat);

  factory _Projection.forBounds(List<double> bounds) {
    final midLat = (bounds[1] + bounds[3]) / 2;
    return _Projection(
      bounds[0],
      bounds[1],
      111320.0 * cos(midLat * pi / 180),
      111320,
    );
  }

  final double lng0;
  final double lat0;
  final double mPerDegLng;
  final double mPerDegLat;

  PointD project(double lng, double lat) =>
      PointD((lng - lng0) * mPerDegLng, (lat - lat0) * mPerDegLat);

  List<double> unproject(double x, double y) => [
    lng0 + x / mPerDegLng,
    lat0 + y / mPerDegLat,
  ];
}
