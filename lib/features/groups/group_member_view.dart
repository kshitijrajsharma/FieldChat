/// A group member joined with their profile, for display in the group roster.
class GroupMemberView {
  const GroupMemberView({
    required this.profileId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.phone,
    this.assignedZoneId,
  });

  final String profileId;
  final String role;
  final DateTime joinedAt;
  final String? displayName;
  final String? phone;
  final String? assignedZoneId;

  bool get isAdmin => role == 'admin';

  /// The best human label: chosen name, else phone, else the raw id.
  String get name {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (phone != null && phone!.isNotEmpty) return phone!;
    return profileId;
  }
}
