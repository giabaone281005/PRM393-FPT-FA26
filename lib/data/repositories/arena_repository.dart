import '../../core/supabase/supabase_service.dart';

class ArenaRepository {
  /// Lấy bảng xếp hạng giải đấu tuần hiện tại theo khối lớp
  static Future<List<Map<String, dynamic>>> fetchLeaderboard(int grade) async {
    if (!SupabaseService.isInitialized) return _mockLeaderboard(grade);
    try {
      final weekCode =
          '${DateTime.now().year}-W${_isoWeek(DateTime.now()).toString().padLeft(2, '0')}';

      final tourney = await SupabaseService.client!
          .from('tournaments')
          .select()
          .eq('grade', grade)
          .eq('week_code', weekCode)
          .maybeSingle();

      if (tourney == null) return _mockLeaderboard(grade);

      final members = await SupabaseService.client!
          .from('tournament_members')
          .select('*, kid_profiles(nickname)')
          .eq('tournament_id', tourney['id'])
          .order('weekly_xp', ascending: false)
          .limit(30);

      return (members as List).asMap().entries.map((e) {
        final m = e.value as Map<String, dynamic>;
        return {
          'rank': e.key + 1,
          'name': m['kid_profiles']?['nickname'] ?? 'Bé Ẩn Danh',
          'xp': m['weekly_xp'] ?? 0,
          'kidId': m['kid_id'],
        };
      }).toList();
    } catch (_) {
      return _mockLeaderboard(grade);
    }
  }

  static List<Map<String, dynamic>> _mockLeaderboard(int grade) {
    return [
      {'rank': 1, 'name': 'Minh Khang', 'xp': 450, 'badge': 'Nhà Bác Học Nhí'},
      {'rank': 2, 'name': 'Thảo Linh', 'xp': 420, 'badge': 'Thám Tử Toán Học'},
      {'rank': 3, 'name': 'Hoàng Nam', 'xp': 390, 'badge': 'Siêu Trí Tuệ'},
      {'rank': 4, 'name': 'Gia Bảo', 'xp': 340, 'badge': 'Thợ Săn Phép Tính'},
      {'rank': 5, 'name': 'Khánh An', 'xp': 310, 'badge': 'Nhà Khám Phá'},
      {'rank': 6, 'name': 'Ngọc Mai', 'xp': 285, 'badge': 'Tân Binh Xuất Sắc'},
    ];
  }

  static int _isoWeek(DateTime date) {
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Nộp điểm thi đấu tuần lên BXH giải đấu (BR-02 Gamification)
  static Future<bool> submitWeeklyScore({
    required String kidId,
    required int grade,
    required int xpEarned,
  }) async {
    if (!SupabaseService.isInitialized) return true;
    try {
      final weekCode =
          '${DateTime.now().year}-W${_isoWeek(DateTime.now()).toString().padLeft(2, '0')}';

      // 1. Tìm hoặc tạo tournament cho tuần
      var tourney = await SupabaseService.client!
          .from('tournaments')
          .select()
          .eq('grade', grade)
          .eq('week_code', weekCode)
          .maybeSingle();

      tourney ??= await SupabaseService.client!.from('tournaments').insert({
        'grade': grade,
        'week_code': weekCode,
      }).select().single();

      final tourneyId = tourney['id'];

      // 2. Tìm member hiện tại
      final member = await SupabaseService.client!
          .from('tournament_members')
          .select()
          .eq('tournament_id', tourneyId)
          .eq('kid_id', kidId)
          .maybeSingle();

      final currentXp = (member?['weekly_xp'] as int?) ?? 0;
      final newXp = currentXp + xpEarned;

      await SupabaseService.client!.from('tournament_members').upsert({
        'tournament_id': tourneyId,
        'kid_id': kidId,
        'weekly_xp': newXp,
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}
