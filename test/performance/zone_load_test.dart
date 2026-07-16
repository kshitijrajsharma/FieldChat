import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hulaki/features/zones/domain/zone_bucketing.dart';
import 'package:hulaki/features/zones/domain/zone_partition.dart';

const _palette = [
  0xFF111111,
  0xFF222222,
  0xFF333333,
  0xFF444444,
  0xFF555555,
  0xFF666666,
  0xFF777777,
  0xFF888888,
  0xFF999999,
];

String _aoi() => jsonEncode({
  'type': 'Feature',
  'geometry': {
    'type': 'Polygon',
    'coordinates': [
      [
        [85.30, 27.70],
        [85.40, 27.70],
        [85.40, 27.80],
        [85.30, 27.80],
        [85.30, 27.70],
      ],
    ],
  },
});

void main() {
  test(
    're-buckets many points across many zones within time',
    () {
      final zones = gridSplit(_aoi(), 9, palette: _palette);
      expect(zones.length, greaterThanOrEqualTo(6));

      const count = 20000;
      final points = <({double lat, double lng})>[
        for (var i = 0; i < count; i++)
          (
            lat: 27.70 + (i % 100) * 0.001,
            lng: 85.30 + (i ~/ 100 % 100) * 0.001,
          ),
      ];

      final watch = Stopwatch()..start();
      final counts = countsByZone(zones, points);
      watch.stop();

      final total = counts.values.fold(0, (a, b) => a + b);
      // Almost every point lands in some zone (the grid tiles the area).
      expect(total, greaterThan((count * 0.95).round()));
      expect(
        watch.elapsedMilliseconds,
        lessThan(3000),
        reason: 'bucketing $count points took ${watch.elapsedMilliseconds} ms',
      );
      // Surfacing the timing is the point of a load check.
      // ignore: avoid_print
      print(
        'Zones: bucketed $count points across ${zones.length} zones in '
        '${watch.elapsedMilliseconds} ms',
      );
    },
    tags: 'load',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
