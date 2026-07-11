import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulaki/data/local/database.dart';
import 'package:hulaki/features/capture/gps_gate.dart';
import 'package:hulaki/features/export/geojson.dart';
import 'package:hulaki/features/export/gpx.dart';
import 'package:hulaki/features/export/project_archive.dart';
import 'package:hulaki/features/groups/group_service.dart';
import 'package:hulaki/features/identity/identity_crypto.dart';
import 'package:hulaki/features/sync/blob_store.dart';
import 'package:hulaki/features/sync/in_memory_transport.dart';
import 'package:hulaki/features/sync/sync_service.dart';

/// Export builds the whole document in memory on the main isolate, so its cost
/// is bounded by point count and media size rather than by the network. These
/// run under the JIT test harness, which is a pessimistic upper bound on the
/// AOT cost a device pays.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const pointCount = 1300;
  const photoCount = 100;
  const photoBytes = 2 * 1024 * 1024;

  test(
    'exports $pointCount points and $photoCount photos',
    () async {
      final db = LocalDatabase(NativeDatabase.memory());
      final identity = await IdentityKeys.generate();
      final sync = SyncService(
        db: db,
        transport: InMemoryTransport(),
        blobStore: InMemoryBlobStore(),
        currentUserId: 'you',
        identity: () async => identity,
      );
      final groups = GroupService(db: db, sync: sync, currentUserId: 'you');
      addTearDown(() async {
        await sync.dispose();
        await db.close();
      });

      final group = await groups.createGroup(
        name: 'Load survey',
        identity: identity,
        hotKeys: const [
          HotKeySpec(label: 'Trash', colorValue: 0xFF15181B),
          HotKeySpec(label: 'Tree', colorValue: 0xFF2E7D32),
        ],
      );
      final hotKeys = await db.hotKeysFor(group.id);

      final seeded = Stopwatch()..start();
      for (var i = 0; i < pointCount; i++) {
        await sync.sendText(
          groupId: group.id,
          tagId: hotKeys[i % hotKeys.length].id,
          geo: GeoResult.fix(
            GpsFix(
              lat: 27.70 + (i % 100) * 0.0002,
              lng: 85.30 + (i ~/ 100) * 0.0002,
              accuracyM: 5,
            ),
          ),
        );
      }
      // Incompressible, so the zip cost matches real JPEG payloads rather
      // than a repeating pattern that deflate collapses to nothing.
      final random = Random(7);
      final photo = Uint8List.fromList(
        List.generate(photoBytes, (_) => random.nextInt(256)),
      );
      for (var i = 0; i < photoCount; i++) {
        await sync.sendPhoto(
          groupId: group.id,
          bytes: photo,
          caption: 'photo $i',
          tagId: hotKeys.first.id,
          geo: GeoResult.fix(
            GpsFix(lat: 27.71 + i * 0.0005, lng: 85.31, accuracyM: 6),
          ),
        );
      }
      seeded.stop();

      final messages = await db.messagesFor(group.id);
      expect(messages.length, pointCount + photoCount);
      const mediaMb = photoCount * photoBytes / 1024 / 1024;
      stdout.writeln(
        'seeded   ${messages.length} messages '
        'in ${seeded.elapsedMilliseconds}ms',
      );

      final geo = Stopwatch()..start();
      final geojson = featureCollectionToString(
        buildFeatureCollection(messages, hotKeys),
      );
      geo.stop();
      stdout.writeln(
        'geojson  ${geo.elapsedMilliseconds}ms  '
        '${(geojson.length / 1024).round()} KB',
      );

      final gpxWatch = Stopwatch()..start();
      final gpx = buildGpx(
        name: group.name,
        messages: messages,
        hotKeys: hotKeys,
      );
      gpxWatch.stop();
      stdout.writeln(
        'gpx      ${gpxWatch.elapsedMilliseconds}ms  '
        '${(gpx.length / 1024).round()} KB',
      );

      final dir = Directory.systemTemp.createTempSync('hulaki_load');
      addTearDown(() => dir.deleteSync(recursive: true));
      final zipPath = '${dir.path}/project.zip';

      final rssBefore = ProcessInfo.currentRss;
      final zipWatch = Stopwatch()..start();
      await buildProjectArchive(
        outputPath: zipPath,
        group: group,
        hotKeys: hotKeys,
        messages: messages,
        mediaResolver: db.mediaBytes,
        exportedAt: DateTime.utc(2026, 7, 11),
      );
      zipWatch.stop();
      final rssPeak = ProcessInfo.maxRss;
      final zip = File(zipPath).readAsBytesSync();
      stdout
        ..writeln(
          'zip      ${zipWatch.elapsedMilliseconds}ms  '
          '${(zip.length / 1024 / 1024).toStringAsFixed(1)} MB out '
          'from ${mediaMb.toStringAsFixed(1)} MB media',
        )
        ..writeln(
          'rss      ${(rssBefore / 1024 / 1024).round()} MB before zip, '
          'peak ${(rssPeak / 1024 / 1024).round()} MB',
        );

      expect(geojson, contains('FeatureCollection'));
      expect(gpx, contains('<wpt'));
      expect(zip.length, greaterThan(photoCount * 1024));

      // The zip streams to disk, so memory must not scale with the media
      // library. Holding it all at once peaked at 1.29 GB and a phone kills
      // the process well before that.
      const ceilingMb = 250;
      final growthMb = (rssPeak - rssBefore) / 1024 / 1024;
      expect(
        growthMb,
        lessThan(ceilingMb),
        reason:
            'zip grew RSS by ${growthMb.round()} MB for '
            '${mediaMb.toStringAsFixed(0)} MB of media',
      );
    },
    tags: 'load',
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
