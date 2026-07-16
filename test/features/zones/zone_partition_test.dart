import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hulaki/features/zones/domain/zone_bucketing.dart';
import 'package:hulaki/features/zones/domain/zone_partition.dart';

const _palette = [0xFF111111, 0xFF222222, 0xFF333333, 0xFF444444];

// A square mapping area around Kathmandu, ~2.2km on a side.
String _squareAoi() => jsonEncode({
  'type': 'Feature',
  'geometry': {
    'type': 'Polygon',
    'coordinates': [
      [
        [85.30, 27.70],
        [85.32, 27.70],
        [85.32, 27.72],
        [85.30, 27.72],
        [85.30, 27.70],
      ],
    ],
  },
});

Iterable<({double lat, double lng})> _sampleGrid() sync* {
  for (var i = 1; i < 10; i++) {
    for (var j = 1; j < 10; j++) {
      yield (lat: 27.70 + 0.02 * i / 10, lng: 85.30 + 0.02 * j / 10);
    }
  }
}

void main() {
  group('gridSplit', () {
    test('splits a square into four covering zones', () {
      final zones = gridSplit(_squareAoi(), 4, palette: _palette);
      expect(zones.length, 4);
      // Every interior sample point lands in exactly one zone.
      for (final point in _sampleGrid()) {
        final hits = zones
            .where((z) => zoneForPoint([z], point.lat, point.lng) != null)
            .toList();
        expect(hits.length, 1, reason: 'point $point in ${hits.length} zones');
      }
    });

    test('returns empty below two', () {
      expect(gridSplit(_squareAoi(), 1, palette: _palette), isEmpty);
    });

    test('returns empty when the area has no polygon', () {
      final noPolygon = jsonEncode({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [85.30, 27.70],
            [85.32, 27.72],
          ],
        },
      });
      expect(gridSplit(noPolygon, 4, palette: _palette), isEmpty);
    });
  });

  group('seedSplit', () {
    test('two seeds partition the area and separate their sides', () {
      final zones = seedSplit(
        _squareAoi(),
        [
          [85.305, 27.71],
          [85.315, 27.71],
        ],
        palette: _palette,
      );
      expect(zones.length, 2);

      final nearA = zoneForPoint(zones, 27.71, 85.302);
      final nearB = zoneForPoint(zones, 27.71, 85.318);
      expect(nearA, isNotNull);
      expect(nearB, isNotNull);
      expect(nearA!.id, isNot(nearB!.id));

      for (final point in _sampleGrid()) {
        expect(zoneForPoint(zones, point.lat, point.lng), isNotNull);
      }
    });

    test('returns empty with fewer than two seeds', () {
      expect(
        seedSplit(_squareAoi(), [
          [85.31, 27.71],
        ], palette: _palette),
        isEmpty,
      );
    });

    test('ignores coincident seeds without crashing', () {
      final zones = seedSplit(
        _squareAoi(),
        [
          [85.305, 27.71],
          [85.305, 27.71],
          [85.315, 27.71],
        ],
        palette: _palette,
      );
      expect(zones, isNotEmpty);
    });
  });
}
