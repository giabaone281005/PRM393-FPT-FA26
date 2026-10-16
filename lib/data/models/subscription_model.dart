enum SubscriptionTier {
  basic,
  plus;

  String get displayName {
    switch (this) {
      case SubscriptionTier.basic:
        return 'Gói Cơ Bản (Basic)';
      case SubscriptionTier.plus:
        return 'Gói Cao Cấp (Plus)';
    }
  }

  bool get isPlus => this == SubscriptionTier.plus;
}

enum SubscriptionStatus {
  active,
  expired,
  canceled;
}

class SubscriptionModel {
  final String id;
  final String parentId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final int maxKids;
  final DateTime startDate;
  final DateTime? expiresAt;
  final String? notes;

  const SubscriptionModel({
    required this.id,
    required this.parentId,
    required this.tier,
    this.status = SubscriptionStatus.active,
    this.maxKids = 1,
    required this.startDate,
    this.expiresAt,
    this.notes,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isPlusActive => tier == SubscriptionTier.plus && status == SubscriptionStatus.active && !isExpired;

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    final tierStr = (map['tier'] as String?)?.toLowerCase() ?? 'basic';
    final statusStr = (map['status'] as String?)?.toLowerCase() ?? 'active';

    return SubscriptionModel(
      id: map['id']?.toString() ?? '',
      parentId: map['parent_id']?.toString() ?? '',
      tier: tierStr == 'plus' ? SubscriptionTier.plus : SubscriptionTier.basic,
      status: statusStr == 'expired'
          ? SubscriptionStatus.expired
          : statusStr == 'canceled'
          ? SubscriptionStatus.canceled
          : SubscriptionStatus.active,
      maxKids: (map['max_kids'] as num?)?.toInt() ?? (tierStr == 'plus' ? 3 : 1),
      startDate: map['start_date'] != null
          ? DateTime.tryParse(map['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'].toString())
          : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'tier': tier.name,
      'status': status.name,
      'max_kids': maxKids,
      'start_date': startDate.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory SubscriptionModel.defaultBasic(String parentId) {
    return SubscriptionModel(
      id: 'default_basic_$parentId',
      parentId: parentId,
      tier: SubscriptionTier.basic,
      status: SubscriptionStatus.active,
      maxKids: 1,
      startDate: DateTime.now(),
      expiresAt: null,
    );
  }
}