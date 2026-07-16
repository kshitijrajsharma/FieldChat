import 'dart:convert';

/// A named, coloured subdivision of a mapping area. [pieces] are exterior rings
/// of `[lng, lat]`; more than one only where clipping a concave area splits it.
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.pieces,
  });

  final String id;
  final String name;
  final int colorValue;
  final List<List<List<double>>> pieces;

  Zone copyWith({String? name, int? colorValue}) => Zone(
    id: id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    pieces: pieces,
  );

  /// A GeoJSON Feature carrying the zone id, name and colour, its geometry a
  /// MultiPolygon of the zone's pieces (each piece one outer ring, no holes).
  Map<String, dynamic> toFeature() => {
    'type': 'Feature',
    'properties': {'id': id, 'name': name, 'colorValue': colorValue},
    'geometry': {
      'type': 'MultiPolygon',
      'coordinates': [
        for (final ring in pieces) [ring],
      ],
    },
  };
}

/// Decodes `zonesGeoJson` into zones. Null, empty or malformed all yield an
/// empty list, so an unreadable split reads the same as no split.
List<Zone> zonesFromGeoJson(String? geoJson) {
  if (geoJson == null || geoJson.isEmpty) return const [];
  final Object? decoded;
  try {
    decoded = jsonDecode(geoJson);
  } on FormatException {
    return const [];
  }
  if (decoded is! Map || decoded['features'] is! List) return const [];
  final zones = <Zone>[];
  for (final feature in decoded['features'] as List) {
    if (feature is! Map) continue;
    final props = feature['properties'];
    final geometry = feature['geometry'];
    if (props is! Map || geometry is! Map) continue;
    final id = props['id'];
    final name = props['name'];
    final colorValue = props['colorValue'];
    if (id is! String || name is! String || colorValue is! num) continue;
    final pieces = _piecesOf(geometry);
    if (pieces.isEmpty) continue;
    zones.add(
      Zone(
        id: id,
        name: name,
        colorValue: colorValue.toInt(),
        pieces: pieces,
      ),
    );
  }
  return zones;
}

/// Encodes zones back into a FeatureCollection string for `zonesGeoJson`.
String zonesToGeoJson(List<Zone> zones) => jsonEncode({
  'type': 'FeatureCollection',
  'features': [for (final zone in zones) zone.toFeature()],
});

/// Zones from imported GeoJSON: one per feature, or per polygon of a bare
/// MultiPolygon. Empty when there is no polygon, so callers can reject it.
List<Zone> zonesFromImport(String geoJson, {required List<int> palette}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(geoJson);
  } on FormatException {
    return const [];
  }
  final zones = <Zone>[];
  void add(List<List<List<double>>> pieces, String? name) {
    final valid = [
      for (final ring in pieces)
        if (ring.length >= 3) ring,
    ];
    if (valid.isEmpty) return;
    final index = zones.length;
    zones.add(
      Zone(
        id: 'z$index',
        name: (name != null && name.isNotEmpty) ? name : 'Area ${index + 1}',
        colorValue: palette[index % palette.length],
        pieces: valid,
      ),
    );
  }

  if (decoded is Map && decoded['type'] == 'FeatureCollection') {
    final features = decoded['features'];
    if (features is List) {
      for (final feature in features) {
        if (feature is! Map) continue;
        final geometry = feature['geometry'];
        final props = feature['properties'];
        final name = props is Map ? props['name'] as String? : null;
        if (geometry is Map) add(_piecesOf(geometry), name);
      }
    }
  } else if (decoded is Map && decoded['type'] == 'Feature') {
    final geometry = decoded['geometry'];
    if (geometry is Map) add(_piecesOf(geometry), null);
  } else if (decoded is Map && decoded['type'] == 'MultiPolygon') {
    for (final piece in _piecesOf(decoded)) {
      add([piece], null);
    }
  } else if (decoded is Map && decoded['type'] == 'Polygon') {
    add(_piecesOf(decoded), null);
  }
  return zones;
}

List<List<List<double>>> _piecesOf(Map<Object?, Object?> geometry) {
  final type = geometry['type'];
  final coords = geometry['coordinates'];
  if (type == 'Polygon' && coords is List && coords.isNotEmpty) {
    return [_ringOf(coords.first)];
  }
  if (type == 'MultiPolygon' && coords is List) {
    return [
      for (final polygon in coords)
        if (polygon is List && polygon.isNotEmpty) _ringOf(polygon.first),
    ]..removeWhere((ring) => ring.length < 3);
  }
  return const [];
}

List<List<double>> _ringOf(Object? ring) => [
  if (ring is List)
    for (final point in ring)
      if (point is List &&
          point.length >= 2 &&
          point[0] is num &&
          point[1] is num)
        [(point[0] as num).toDouble(), (point[1] as num).toDouble()],
];
