import 'package:flutter_test/flutter_test.dart';
import 'package:hulaki/features/zones/domain/zone.dart';
import 'package:hulaki/features/zones/domain/zone_bucketing.dart';

// Two side-by-side square zones spanning lng 85.30..85.32 at lat 27.70..27.72.
List<Zone> _twoZones() => const [
  Zone(
    id: 'west',
    name: 'West',
    colorValue: 0xFF111111,
    pieces: [
      [
        [85.30, 27.70],
        [85.31, 27.70],
        [85.31, 27.72],
        [85.30, 27.72],
        [85.30, 27.70],
      ],
    ],
  ),
  Zone(
    id: 'east',
    name: 'East',
    colorValue: 0xFF222222,
    pieces: [
      [
        [85.31, 27.70],
        [85.32, 27.70],
        [85.32, 27.72],
        [85.31, 27.72],
        [85.31, 27.70],
      ],
    ],
  ),
];

void main() {
  test('zoneForPoint attributes points to the containing zone', () {
    final zones = _twoZones();
    expect(zoneForPoint(zones, 27.71, 85.305)!.id, 'west');
    expect(zoneForPoint(zones, 27.71, 85.315)!.id, 'east');
    expect(zoneForPoint(zones, 27.71, 85.40), isNull);
  });

  test('countsByZone tallies every zone, ignoring points outside', () {
    final zones = _twoZones();
    final counts = countsByZone(zones, const [
      (lat: 27.71, lng: 85.305),
      (lat: 27.715, lng: 85.302),
      (lat: 27.71, lng: 85.315),
      (lat: 27.71, lng: 85.90),
    ]);
    expect(counts['west'], 2);
    expect(counts['east'], 1);
  });
}
