import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:hulaki/features/messaging/domain/message_payload.dart';
import 'package:hulaki/features/sync/blob_store.dart';
import 'package:hulaki/features/sync/in_memory_transport.dart';
import 'package:hulaki/features/zones/domain/zone.dart';
import 'package:hulaki/features/zones/domain/zone_partition.dart';

import 'admin_handshake_test.dart';

const _palette = [0xFF111111, 0xFF222222, 0xFF333333];

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

  test('a non-admin member cannot split the area', () async {
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
    await creator.groups.setMappingArea(group.id, _aoi());
    await member.groups.joinViaLink(
      creator.groups.inviteLinkFor(group),
      member.identity,
    );
    await waitFor(
      () async => (await member.db.groupById(group.id))?.aoiGeoJson != null,
    );

    await member.groups.setZones(
      group.id,
      gridSplit(_aoi(), 3, palette: _palette),
    );
    await member.sync.sendText(groupId: group.id, text: 'marker');
    await waitFor(() async {
      final rows = await creator.db.messagesFor(group.id);
      return rows.any((m) => m.body == 'marker');
    });

    final group0 = await creator.db.groupById(group.id);
    expect(zonesFromGeoJson(group0?.zonesGeoJson), isEmpty);
  });

  test('a member cannot assign another member to a zone', () async {
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
      () async => (await creator.db.profileById('member'))?.signingKey != null,
    );

    await member.sync.publishControl(
      groupId: group.id,
      kind: MessageKind.zoneAssign,
      body: {'profileId': 'creator', 'zoneId': 'forged-zone'},
    );
    await member.sync.sendText(groupId: group.id, text: 'marker');
    await waitFor(() async {
      final rows = await creator.db.messagesFor(group.id);
      return rows.any((m) => m.body == 'marker');
    });

    final members = await creator.db.watchMembersFor(group.id).first;
    expect(
      members.every((m) => m.assignedZoneId != 'forged-zone'),
      isTrue,
    );
  });
}
