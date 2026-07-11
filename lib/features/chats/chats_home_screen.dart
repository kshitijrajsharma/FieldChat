import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulaki/app/providers.dart';
import 'package:hulaki/data/local/database.dart';
import 'package:hulaki/design/app_colors.dart';
import 'package:hulaki/design/app_spacing.dart';
import 'package:hulaki/design/brand/hulaki_logo.dart';
import 'package:hulaki/design/widgets/primary_button.dart';
import 'package:hulaki/features/groups/presentation/create_group_screen.dart';
import 'package:hulaki/features/groups/presentation/group_avatar.dart';
import 'package:hulaki/features/groups/presentation/join_group_screen.dart';
import 'package:hulaki/features/messaging/presentation/chat_thread_screen.dart';
import 'package:hulaki/features/sync/presentation/pending_upload_banner.dart';
import 'package:hulaki/l10n/app_localizations.dart';

/// The home list of mapping groups, live from the local store. Tap a group to
/// open its thread; the + button starts a new one.
class ChatsHomeScreen extends ConsumerWidget {
  const ChatsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(activeGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: const HulakiWordmark(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.ink),
            onPressed: () => showSearch<Group?>(
              context: context,
              delegate: _GroupSearchDelegate(groups.value ?? const []),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          const PendingUploadBanner(),
          Expanded(
            child: groups.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    l10n.chatsLoadFailed,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(indent: 74),
                      itemBuilder: (context, i) => _GroupTile(items[i]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: (groups.asData?.value.isEmpty ?? true)
          ? null
          : FloatingActionButton(
              onPressed: () => _showStartOptions(context, l10n),
              child: const Icon(Icons.add),
            ),
    );
  }
}

void _showStartOptions(BuildContext context, AppLocalizations l10n) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: Text(l10n.chatsStartNewGroup),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreateGroupScreen(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.chatsJoinWithLink),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const JoinGroupScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Filters the group list by name and opens the picked group's thread.
class _GroupSearchDelegate extends SearchDelegate<Group?> {
  _GroupSearchDelegate(this.groups);

  final List<Group> groups;

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final matches = groups
        .where((g) => g.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (matches.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).chatsNoMatches));
    }
    return ListView(
      children: [
        for (final group in matches)
          ListTile(
            leading: GroupAvatar(photo: group.photo, size: 40),
            title: Text(group.name),
            onTap: () {
              close(context, group);
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatThreadScreen(
                      groupId: group.id,
                      groupName: group.name,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HulakiMark(height: 40, color: AppColors.textFaint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.chatsNoGroupsYet,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.chatsEmptyStateBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.chatsStartNewGroup,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreateGroupScreen(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const JoinGroupScreen(),
                  ),
                ),
                icon: const Icon(Icons.link, size: 18),
                label: Text(l10n.chatsJoinWithLink),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.mist),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _previewFor(AppLocalizations l10n, Message? message) {
  if (message == null) return l10n.chatsNoMessagesYet;
  final body = message.body;
  if (body != null && body.isNotEmpty) return body;
  return switch (message.kind) {
    'photo' => l10n.chatsPreviewPhoto,
    'video' => l10n.chatsPreviewVideo,
    'voice' => l10n.chatsPreviewVoiceNote,
    _ => l10n.chatsPreviewPoint,
  };
}

class _GroupTile extends ConsumerWidget {
  const _GroupTile(this.group);

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: GroupAvatar(photo: group.photo),
      title: Text(
        group.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          _previewFor(
            l10n,
            ref.watch(latestMessageProvider(group.id)).asData?.value,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ChatThreadScreen(groupId: group.id, groupName: group.name),
        ),
      ),
    );
  }
}
