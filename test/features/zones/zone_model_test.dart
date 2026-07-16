import 'package:flutter_test/flutter_test.dart';
import 'package:hulaki/features/zones/domain/zone.dart';

void main() {
  test('zones round-trip through GeoJSON', () {
    final zones = [
      const Zone(
        id: 'z0',
        name: 'Riverside',
        colorValue: 0xFF3C7A4E,
        pieces: [
          [
            [85.30, 27.70],
            [85.31, 27.70],
            [85.31, 27.71],
            [85.30, 27.71],
            [85.30, 27.70],
          ],
        ],
      ),
      const Zone(
        id: 'z1',
        name: 'Market',
        colorValue: 0xFF3466A0,
        pieces: [
          [
            [85.31, 27.70],
            [85.32, 27.70],
            [85.32, 27.71],
            [85.31, 27.71],
            [85.31, 27.70],
          ],
        ],
      ),
    ];

    final restored = zonesFromGeoJson(zonesToGeoJson(zones));
    expect(restored.length, 2);
    expect(restored[0].id, 'z0');
    expect(restored[0].name, 'Riverside');
    expect(restored[0].colorValue, 0xFF3C7A4E);
    expect(restored[0].pieces.first.length, 5);
    expect(restored[1].id, 'z1');
  });

  test('null, empty and malformed decode to no zones', () {
    expect(zonesFromGeoJson(null), isEmpty);
    expect(zonesFromGeoJson(''), isEmpty);
    expect(zonesFromGeoJson('{"type":"FeatureCollection"}'), isEmpty);
    expect(zonesFromGeoJson('not json at all'), isEmpty);
  });
}
