import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulaki/data/local/database.dart';
import 'package:hulaki/features/discovery/public_directory.dart';
import 'package:hulaki/features/notifications/join_request_poller.dart';
import 'package:shared_preferences/shared_preferences.dart';

JoinRequest _request(String id, String groupId) => JoinRequest(
  id: id,
  groupId: groupId,
  requesterId: 'req-$id',
  requesterName: 'Requester $id',
  signingKey: 'sign',
  agreementKey: 'agree',
);

Future<void> _adminGroup(
  LocalDatabase db,
  String id, {
  required bool publicApproval,
}) async {
  await db
      .into(db.groups)
      .insert(
        GroupsCompanion.insert(
          id: id,
          name: 'Group $id',
          createdBy: 'me',
          encKey: 'k',
          isPublic: Value(publicApproval),
          joinApproval: Value(publicApproval),
        ),
      );
  await db
      .into(db.groupMembers)
      .insert(
        GroupMembersCompanion.insert(
          groupId: id,
          profileId: 'me',
          role: const Value('admin'),
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDatabase db;
  late SeenRequestStore seen;
  final pending = <String, List<JoinRequest>>{};

  setUp(() async {
    db = LocalDatabase(NativeDatabase.memory());
    pending.clear();
    SharedPreferences.setMockInitialValues({});
    seen = SeenRequestStore(await SharedPreferences.getInstance());
  });
  tearDown(() => db.close());

  JoinRequestPoller poller() => JoinRequestPoller(
    adminGroups: () => db.adminApprovalGroups('me'),
    pending: (groupId) async => pending[groupId] ?? const [],
    seen: seen,
  );

  test('a new request notifies once, then is remembered', () async {
    await _adminGroup(db, 'g1', publicApproval: true);
    pending['g1'] = [_request('a', 'g1')];

    final first = await poller().poll();
    expect(first.map((e) => e.$2.id), ['a']);

    final second = await poller().poll();
    expect(second, isEmpty);
  });

  test('only the newly-arrived request notifies', () async {
    await _adminGroup(db, 'g1', publicApproval: true);
    pending['g1'] = [_request('a', 'g1')];
    await poller().poll();

    pending['g1'] = [_request('a', 'g1'), _request('b', 'g1')];
    final fresh = await poller().poll();
    expect(fresh.map((e) => e.$2.id), ['b']);
  });

  test('a resolved request is pruned so a re-request notifies again', () async {
    await _adminGroup(db, 'g1', publicApproval: true);
    pending['g1'] = [_request('a', 'g1')];
    await poller().poll();

    pending['g1'] = const [];
    expect(await poller().poll(), isEmpty);

    pending['g1'] = [_request('a', 'g1')];
    final again = await poller().poll();
    expect(again.map((e) => e.$2.id), ['a']);
  });

  test('groups without public approval are not polled', () async {
    await _adminGroup(db, 'private', publicApproval: false);
    pending['private'] = [_request('a', 'private')];
    expect(await poller().poll(), isEmpty);
  });
}
