import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:hulaki/features/capture/gps_gate.dart';
import 'package:hulaki/features/sync/blob_store.dart';
import 'package:hulaki/features/sync/in_memory_transport.dart';
import 'package:hulaki/features/zones/domain/zone.dart';
import 'package:hulaki/features/zones/domain/zone_bucketing.dart';
import 'package:hulaki/features/zones/domain/zone_partition.dart';

import 'admin_handshake_test.dart';

const _palette = [0xFF111111, 0xFF222222, 0xFF333333, 0xFF444444];

String _aoi() => jsonEncode({
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

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
    'admin splits, member sees zones and self-assigns, admin sees it',
    () async {
      final transport = InMemoryTransport();
      final blobs = InMemoryBlobStore();
      final creator = Device('creator', transport, blobs);
      final member = Device('member', transport, blobs);
      await creator.init();
      await member.init();
      addTearDown(() async {
        await creator.dispose();
        await member.dispose();
        await transport.dispose();
      });

      final group = await creator.groups.createGroup(
        name: 'Ward 7',
        identity: creator.identity,
        hotKeys: const [],
      );
      await member.groups.joinViaLink(
        creator.groups.inviteLinkFor(group),
        member.identity,
      );
      await waitFor(
        () async =>
            (await creator.db.profileById('member'))?.signingKey != null,
      );

      await creator.groups.setMappingArea(group.id, _aoi());
      final zones = gridSplit(_aoi(), 4, palette: _palette);
      expect(zones, isNotEmpty);
      await creator.groups.setZones(group.id, zones);

      await waitFor(() async {
        final group0 = await member.db.groupById(group.id);
        return zonesFromGeoJson(group0?.zonesGeoJson).length == zones.length;
      });

      final seen = zonesFromGeoJson(
        (await member.db.groupById(group.id))!.zonesGeoJson,
      );
      await member.groups.assignMyZone(group.id, seen.first.id);

      await waitFor(() async {
        final members = await creator.db.watchMembersFor(group.id).first;
        final mine = members.where((m) => m.profileId == 'member');
        return mine.isNotEmpty && mine.first.assignedZoneId == seen.first.id;
      });
    },
  );

  test(
    'a point added on one device counts toward its zone on the admin',
    () async {
      final transport = InMemoryTransport();
      final blobs = InMemoryBlobStore();
      final creator = Device('creator', transport, blobs);
      final member = Device('member', transport, blobs);
      await creator.init();
      await member.init();
      addTearDown(() async {
        await creator.dispose();
        await member.dispose();
        await transport.dispose();
      });

      final group = await creator.groups.createGroup(
        name: 'Ward 7',
        identity: creator.identity,
        hotKeys: const [],
      );
      await member.groups.joinViaLink(
        creator.groups.inviteLinkFor(group),
        member.identity,
      );
      await waitFor(
        () async =>
            (await creator.db.profileById('member'))?.signingKey != null,
      );
      await creator.groups.setMappingArea(group.id, _aoi());
      final zones = gridSplit(_aoi(), 4, palette: _palette);
      await creator.groups.setZones(group.id, zones);
      await waitFor(() async {
        final group0 = await member.db.groupById(group.id);
        return zonesFromGeoJson(group0?.zonesGeoJson).length == zones.length;
      });

      const lat = 27.705;
      const lng = 85.305;
      await member.sync.sendText(
        groupId: group.id,
        text: 'in-zone point',
        geo: GeoResult.fix(const GpsFix(lat: lat, lng: lng, accuracyM: 5)),
      );

      await waitFor(() async {
        final rows = await creator.db.messagesFor(group.id);
        return rows.any((m) => m.body == 'in-zone point');
      });
      final creatorZones = zonesFromGeoJson(
        (await creator.db.groupById(group.id))!.zonesGeoJson,
      );
      final located = [
        for (final m in await creator.db.messagesFor(group.id))
          if (m.lat != null && m.lng != null) (lat: m.lat!, lng: m.lng!),
      ];
      final target = zoneForPoint(creatorZones, lat, lng);
      expect(target, isNotNull);
      expect(countsByZone(creatorZones, located)[target!.id], greaterThan(0));
    },
  );
}
