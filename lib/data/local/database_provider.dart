import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulaki/data/local/database.dart';

/// The app-wide local database. Closed when the provider is disposed.
final databaseProvider = Provider<LocalDatabase>((ref) {
  final database = LocalDatabase();
  ref.onDispose(database.close);
  return database;
});
