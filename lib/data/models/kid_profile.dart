class KidProfile {
  final String id;
  String nickname;
  int grade; // 1 to 5
  int currentHearts; // 0 to 5
  final int maxHearts;
  int energyStars;
  int screenTimeLimitMinutes;
  int usedScreenTimeMinutes;
  final String avatarId;
  int streakCount;
  int shieldCount;
  String? badgeTitle;

  KidProfile({
    required this.id,
    required this.nickname,
    required this.grade,
    this.currentHearts = 5,
    this.maxHearts = 5,
    this.energyStars = 120,
    this.screenTimeLimitMinutes = 30,
    this.usedScreenTimeMinutes = 12,
    this.avatarId = 'owl_detective',
    this.streakCount = 7,
    this.shieldCount = 1,
    this.badgeTitle,
  });

  bool get hasHearts => currentHearts > 0;

  String get activeBadge {
    if (badgeTitle != null) return badgeTitle!;
    if (energyStars >= 500) return 'Nhà Bác Học Nhí';
    if (energyStars >= 200) return 'Thám Tử Toán Học';
    if (energyStars >= 100) return 'Nhà Khám Phá';
    return 'Tân Binh Toán Học';
  }

  void loseHeart() {
    if (currentHearts > 0) currentHearts--;
  }

  void restoreHearts([int count = 1]) {
    currentHearts = (currentHearts + count).clamp(0, maxHearts);
  }

  void addStars(int stars) {
    energyStars += stars;
  }

  /// Parse từ Supabase response JSON
  factory KidProfile.fromJson(Map<String, dynamic> json) {
    return KidProfile(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      grade: json['grade'] as int,
      currentHearts: json['current_hearts'] as int? ?? 5,
      maxHearts: json['max_hearts'] as int? ?? 5,
      energyStars: json['energy_stars'] as int? ?? 0,
      screenTimeLimitMinutes: json['screen_time_limit_minutes'] as int? ?? 30,
      usedScreenTimeMinutes: 0, // Calculated locally
      avatarId: json['avatar_id'] as String? ?? 'owl_detective',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'grade': grade,
      'current_hearts': currentHearts,
      'max_hearts': maxHearts,
      'energy_stars': energyStars,
      'screen_time_limit_minutes': screenTimeLimitMinutes,
      'avatar_id': avatarId,
    };
  }
}
