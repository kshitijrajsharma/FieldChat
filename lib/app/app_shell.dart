import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulaki/app/connectivity.dart';
import 'package:hulaki/design/app_colors.dart';
import 'package:hulaki/features/chats/chats_home_screen.dart';
import 'package:hulaki/features/discovery/communities_screen.dart';
import 'package:hulaki/features/map/map_tab_screen.dart';
import 'package:hulaki/features/me/me_screen.dart';
import 'package:hulaki/l10n/app_localizations.dart';

/// The four top-level destinations: Chats, Map, Communities and Me. Kept as a
/// single shell so the network and local state live above the tabs.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _communitiesIndex = 2;

  int _index = 0;
  final Set<int> _visited = {0};

  /// Builds a tab only once it has been opened, then keeps it alive in the
  /// stack. Defers the map's GL surface until the Map tab is first selected.
  Widget _tabAt(int index) {
    if (!_visited.contains(index)) return const SizedBox.shrink();
    return switch (index) {
      0 => const ChatsHomeScreen(),
      1 => const MapTabScreen(),
      2 => const CommunitiesScreen(),
      _ => const MeScreen(),
    };
  }

  void _onTap(int value, String offlineMessage) {
    final online = ref.read(onlineProvider);
    if (value == _communitiesIndex && !online) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(offlineMessage)));
      return;
    }
    setState(() {
      _index = value;
      _visited.add(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(onlineProvider);
    final communitiesColor = online ? null : AppColors.textFaint;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [for (var i = 0; i < 4; i++) _tabAt(i)],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => _onTap(value, l10n.navCommunitiesNeedsConnection),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: l10n.navChats,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            activeIcon: const Icon(Icons.map),
            label: l10n.navMap,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined, color: communitiesColor),
            activeIcon: const Icon(Icons.explore),
            label: l10n.navCommunities,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.navMe,
          ),
        ],
      ),
    );
  }
}
