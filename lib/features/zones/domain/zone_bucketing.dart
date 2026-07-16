import 'package:hulaki/features/export/geojson.dart';
import 'package:hulaki/features/zones/domain/zone.dart';

/// A located observation reduced to what zone bucketing needs.
typedef ZonePoint = ({double lat, double lng});

/// The zone a point falls in, or null. First match wins, so a point on a shared
/// border is attributed deterministically.
Zone? zoneForPoint(List<Zone> zones, double lat, double lng) {
  for (final zone in zones) {
    for (final piece in zone.pieces) {
      if (ringContainsPoint(piece, lng, lat)) return zone;
    }
  }
  return null;
}

/// Point count per zone id; every zone present, points outside all zones
/// uncounted. Aggregate only: the coverage screen never names anonymous points.
Map<String, int> countsByZone(List<Zone> zones, Iterable<ZonePoint> points) {
  final counts = {for (final zone in zones) zone.id: 0};
  for (final point in points) {
    final zone = zoneForPoint(zones, point.lat, point.lng);
    if (zone != null) counts[zone.id] = counts[zone.id]! + 1;
  }
  return counts;
}
