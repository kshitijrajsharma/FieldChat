import 'package:hulaki/data/local/database.dart';
import 'package:hulaki/features/discovery/public_directory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which join requests have already been notified, so a repeated poll
/// does not fire the same notification twice. Resolved requests are pruned so a
/// later re-request from the same person notifies again.
class SeenRequestStore {
  SeenRequestStore(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'join_requests.seen';

  Set<String> load() => (_prefs.getStringList(_key) ?? const []).toSet();

  Future<void> save(Set<String> ids) =>
      _prefs.setStringList(_key, ids.toList());
}

/// One polling cycle over the groups this device administers, reporting pending
/// join requests not yet notified.
class JoinRequestPoller {
  JoinRequestPoller({
    required this.adminGroups,
    required this.pending,
    required this.seen,
  });

  final Future<List<Group>> Function() adminGroups;
  final Future<List<JoinRequest>> Function(String groupId) pending;
  final SeenRequestStore seen;

  Future<List<(Group, JoinRequest)>> poll() async {
    final groups = await adminGroups();
    final alreadySeen = seen.load();
    final stillPending = <String>{};
    final fresh = <(Group, JoinRequest)>[];
    for (final group in groups) {
      for (final request in await pending(group.id)) {
        stillPending.add(request.id);
        if (!alreadySeen.contains(request.id)) fresh.add((group, request));
      }
    }
    await seen.save(stillPending);
    return fresh;
  }
}
