import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulaki/app/providers.dart';
import 'package:hulaki/data/local/database.dart';
import 'package:hulaki/features/groups/group_member_view.dart';
import 'package:hulaki/features/zones/domain/zone.dart';
import 'package:hulaki/features/zones/presentation/zone_coverage_screen.dart';
import 'package:hulaki/l10n/app_localizations.dart';

List<List<double>> _ring() => const [
  [85.30, 27.70],
  [85.31, 27.70],
  [85.31, 27.71],
  [85.30, 27.71],
  [85.30, 27.70],
];

void main() {
  testWidgets('coverage lists zones, names the mapper, flags the empty one', (
    tester,
  ) async {
    final zones = [
      Zone(
        id: 'a',
        name: 'Riverside',
        colorValue: 0xFF3C7A4E,
        pieces: [_ring()],
      ),
      Zone(id: 'b', name: 'Market', colorValue: 0xFF3466A0, pieces: [_ring()]),
    ];
    final members = [
      GroupMemberView(
        profileId: 'u1',
        role: 'member',
        joinedAt: DateTime(2026),
        displayName: 'Anita',
        assignedZoneId: 'a',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          zonesProvider('g').overrideWith((ref) => Stream.value(zones)),
          groupMembersProvider(
            'g',
          ).overrideWith((ref) => Stream.value(members)),
          messagesProvider(
            'g',
          ).overrideWith((ref) => Stream.value(const <Message>[])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ZoneCoverageScreen(groupId: 'g'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Riverside'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Anita'), findsOneWidget);
    expect(find.text('Needs a mapper'), findsOneWidget);
  });
}
