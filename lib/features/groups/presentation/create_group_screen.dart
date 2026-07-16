import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulaki/app/providers.dart';
import 'package:hulaki/core/image_thumbnail.dart';
import 'package:hulaki/design/app_colors.dart';
import 'package:hulaki/design/app_spacing.dart';
import 'package:hulaki/design/widgets/hot_key_chip.dart';
import 'package:hulaki/design/widgets/primary_button.dart';
import 'package:hulaki/features/groups/group_service.dart';
import 'package:hulaki/features/groups/hot_key_icons.dart';
import 'package:hulaki/features/groups/presentation/area_draw_screen.dart';
import 'package:hulaki/features/groups/presentation/group_avatar.dart';
import 'package:hulaki/features/groups/presentation/hot_key_editor_screen.dart';
import 'package:hulaki/features/messaging/presentation/chat_thread_screen.dart';
import 'package:hulaki/features/zones/domain/zone.dart';
import 'package:hulaki/features/zones/presentation/zone_split_picker.dart';
import 'package:hulaki/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

/// Start a group and set the hot-keys everyone will tap while mapping.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _controller = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  bool _busy = false;
  String? _aoiGeoJson;
  List<Zone> _zones = const [];
  Uint8List? _photo;
  List<EditableHotKey>? _hotKeysOrNull;

  /// The starting tags are data the group keeps, so they are seeded once in the
  /// reader's language rather than rebuilt whenever the locale changes.
  List<EditableHotKey> get _hotKeys => _hotKeysOrNull!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    _hotKeysOrNull ??= [
      EditableHotKey(
        label: l10n.groupDefaultTagTrash,
        colorValue: 0xFF15181B,
        iconName: 'delete',
      ),
      EditableHotKey(
        label: l10n.groupDefaultTagCrossings,
        colorValue: 0xFFE0922A,
        iconName: 'crossing',
      ),
      EditableHotKey(
        label: l10n.groupDefaultTagStreetlight,
        colorValue: 0xFF7B6FC4,
        iconName: 'streetlight',
      ),
      EditableHotKey(
        label: l10n.groupDefaultTagPole,
        colorValue: 0xFFC4615E,
        iconName: 'bolt',
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _editHotKeys() async {
    final result = await Navigator.of(context).push<List<EditableHotKey>>(
      MaterialPageRoute<List<EditableHotKey>>(
        builder: (_) => HotKeyEditorScreen(initial: _hotKeys),
      ),
    );
    if (result != null) {
      setState(() {
        _hotKeys
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 75,
    );
    if (file == null) return;
    final bytes = squareJpegThumbnail(await file.readAsBytes());
    if (mounted) setState(() => _photo = bytes);
  }

  Future<void> _drawArea() async {
    final aoi = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const AreaDrawScreen()),
    );
    if (aoi != null) {
      setState(() {
        _aoiGeoJson = aoi;
        _zones = const [];
      });
    }
  }

  Future<void> _splitZones() async {
    final aoi = _aoiGeoJson;
    if (aoi == null) return;
    final zones = await pickZoneSplit(context, aoi);
    if (zones != null && mounted) setState(() => _zones = zones);
  }

  Future<void> _create() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final identity = await ref.read(deviceIdentityProvider.future);
      final group = await ref
          .read(groupServiceProvider)
          .createGroup(
            name: name,
            identity: identity,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            hotKeys: [
              for (final h in _hotKeys)
                HotKeySpec(
                  label: h.label,
                  colorValue: h.colorValue,
                  iconName: h.iconName,
                ),
            ],
            aoiGeoJson: _aoiGeoJson,
            photo: _photo,
          );
      if (_zones.isNotEmpty) {
        await ref.read(groupServiceProvider).setZones(group.id, _zones);
      }
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              ChatThreadScreen(groupId: group.id, groupName: group.name),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupCreateTitle)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                GroupAvatar(
                                  photo: _photo,
                                  size: 72,
                                  radius: 22,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.ink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.groupCoverPhotoPrompt,
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.groupNameLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.groupNameHint,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.field),
                          borderSide: const BorderSide(color: AppColors.mist),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.field),
                          borderSide: const BorderSide(
                            color: AppColors.ink,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _create(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.groupDescriptionLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: l10n.groupDescriptionHint,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.field),
                          borderSide: const BorderSide(color: AppColors.mist),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.field),
                          borderSide: const BorderSide(
                            color: AppColors.ink,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.groupQuickTagsHeading,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                        TextButton(
                          onPressed: _editHotKeys,
                          child: Text(l10n.groupEdit),
                        ),
                      ],
                    ),
                    Text(
                      l10n.groupQuickTagsExplainer,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final hotKey in _hotKeys)
                          HotKeyChip(
                            label: hotKey.label,
                            color: Color(hotKey.colorValue),
                            icon: hotKeyIcon(hotKey.iconName),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    OutlinedButton.icon(
                      onPressed: _drawArea,
                      icon: Icon(
                        _aoiGeoJson == null ? Icons.draw_outlined : Icons.check,
                        size: 18,
                      ),
                      label: Text(
                        _aoiGeoJson == null
                            ? l10n.groupSetMappingAreaOptional
                            : l10n.groupMappingAreaSet,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.mist),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    if (_aoiGeoJson != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _splitZones,
                        icon: Icon(
                          _zones.isEmpty
                              ? Icons.grid_view_outlined
                              : Icons.check,
                          size: 18,
                        ),
                        label: Text(
                          _zones.isEmpty
                              ? l10n.groupSplitZonesOptional
                              : l10n.groupZonesSet,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.mist),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: PrimaryButton(
                label: _busy ? l10n.groupCreating : l10n.groupCreateAction,
                loading: _busy,
                onPressed: (_busy || _controller.text.trim().isEmpty)
                    ? null
                    : _create,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
