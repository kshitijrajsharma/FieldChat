/// Shows the app's own local notifications. The default is a no-op; the real
/// platform-backed implementation is wired in from main.
abstract interface class LocalNotifications {
  Future<void> init();

  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

class NoopLocalNotifications implements LocalNotifications {
  const NoopLocalNotifications();

  @override
  Future<void> init() async {}

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {}
}
