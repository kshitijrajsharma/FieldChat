import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulaki/app/connectivity.dart';
import 'package:hulaki/app/providers.dart';
import 'package:hulaki/design/app_colors.dart';
import 'package:hulaki/design/app_spacing.dart';

/// A calm banner shown while some captures have not uploaded yet, so a user
/// returning from the field sees upload progress and knows nothing is lost:
/// points are saved on the device first and upload when there is signal.
class PendingUploadBanner extends ConsumerWidget {
  const PendingUploadBanner({this.groupId, super.key});

  /// Counts only this group when set, otherwise the whole device.
  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = groupId;
    final count = id == null
        ? (ref.watch(pendingUploadCountProvider).asData?.value ?? 0)
        : (ref.watch(pendingUploadForProvider(id)).asData?.value ?? 0);
    if (count == 0) return const SizedBox.shrink();

    final online = ref.watch(onlineProvider);
    final points = count == 1 ? '1 point' : '$count points';
    return Container(
      width: double.infinity,
      color: AppColors.field,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      child: Row(
        children: [
          if (online)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.cloud_off_outlined,
              size: 16,
              color: AppColors.textMuted,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              online
                  ? 'Uploading… $points left'
                  : '$points saved here, waiting to upload',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
