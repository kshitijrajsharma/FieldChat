import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulaki/data/local/database.dart';
import 'package:hulaki/features/groups/group_service.dart';
import 'package:hulaki/features/identity/identity_crypto.dart';
import 'package:hulaki/features/sync/blob_store.dart';
import 'package:hulaki/features/sync/in_memory_transport.dart';
import 'package:hulaki/features/sync/message_transport.dart';
import 'package:hulaki/features/sync/sync_service.dart';
import 'package:hulaki/features/zones/domain/zone.dart';
import 'package:hulaki/features/zones/domain/zone_partition.dart';

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

/// Fails every publish while [down], standing in for a dropped network.
class _FlakyTransport implements MessageTransport {
  _FlakyTransport(this._inner);

  final InMemoryTransport _inner;
  bool down = false;

  @override
  Future<int> publish(Envelope envelope) {
    if (down) throw Exception('transport down');
    return _inner.publish(envelope);
  }

  @override
  Stream<Envelope> subscribe(String groupId) => _inner.subscribe(groupId);

  @override
  Future<List<Envelope>> fetchSince(String groupId, int afterSeq) =>
      _inner.fetchSince(groupId, afterSeq);

  @override
  Future<void> purgeGroup(String groupId) => _inner.purgeGroup(groupId);
}

/// One device wired to a shared transport, with a short retry so a reconnect
/// flushes quickly in-test.
class _Device {
  _Device(this.userId, MessageTransport transport, InMemoryBlobStore blobs)
    : db = LocalDatabase(NativeDatabase.memory()) {
    sync = SyncService(
      db: db,
      transport: transport,
      blobStore: blobs,
      currentUserId: userId,
      identity: () async => identity,
      minRetry: const Duration(milliseconds: 20),
    );
    groups = GroupService(db: db, sync: sync, currentUserId: userId);
  }

  final String userId;
  final LocalDatabase db;
  late final SyncService sync;
  late final GroupService groups;
  late final IdentityKeys identity;

  Future<void> init() async {
    identity = await IdentityKeys.generate();
    await db.upsertProfile(ProfilesCompanion.insert(id: userId, phone: ''));
  }

  Future<void> dispose() async {
    await sync.dispose();
    await db.close();
  }
}

Future<void> _waitFor(
  Future<bool> Function() condition, {
  int tries = 600,
}) async {
  for (var i = 0; i < tries; i++) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('condition was not met in time');
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
    'an offline self-assign is local at once and syncs on reconnect',
    () async {
      final flaky = _FlakyTransport(InMemoryTransport());
      final blobs = InMemoryBlobStore();
      final creator = _Device('creator', flaky, blobs);
      final member = _Device('member', flaky, blobs);
      await creator.init();
      await member.init();
      addTearDown(() async {
        await creator.dispose();
        await member.dispose();
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
      await _waitFor(
        () async =>
            (await creator.db.profileById('member'))?.signingKey != null,
      );
      await creator.groups.setMappingArea(group.id, _aoi());
      final zones = gridSplit(_aoi(), 4, palette: _palette);
      await creator.groups.setZones(group.id, zones);
      await _waitFor(() async {
        final group0 = await member.db.groupById(group.id);
        return zonesFromGeoJson(group0?.zonesGeoJson).length == zones.length;
      });
      final zoneId = zones.first.id;

      flaky.down = true;
      await member.groups.assignMyZone(group.id, zoneId);

      final localMembers = await member.db.watchMembersFor(group.id).first;
      expect(
        localMembers.firstWhere((m) => m.profileId == 'member').assignedZoneId,
        zoneId,
      );

      await Future<void>.delayed(const Duration(milliseconds: 60));
      final beforeReconnect = await creator.db.watchMembersFor(group.id).first;
      final onAdmin = beforeReconnect.where((m) => m.profileId == 'member');
      expect(
        onAdmin.isEmpty || onAdmin.first.assignedZoneId == null,
        isTrue,
      );

      flaky.down = false;
      await _waitFor(() async {
        final members = await creator.db.watchMembersFor(group.id).first;
        final mine = members.where((m) => m.profileId == 'member');
        return mine.isNotEmpty && mine.first.assignedZoneId == zoneId;
      });
    },
  );
}
