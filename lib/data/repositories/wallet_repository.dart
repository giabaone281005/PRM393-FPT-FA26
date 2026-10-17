import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';

class LinkedWallet {
  final String provider, hint;
  const LinkedWallet(this.provider, this.hint);
  String get label => '${provider == 'momo' ? 'MoMo' : 'VNPay'} $hint';
}

class PlanInfo {
  final String code, name, description;
  final List<String> features;
  final int trialDays;
  const PlanInfo({
    required this.code,
    required this.name,
    required this.description,
    required this.features,
    required this.trialDays,
  });
  factory PlanInfo.fromMap(Map<String, dynamic> m) => PlanInfo(
    code: m['code'] as String,
    name: m['name'] as String,
    description: m['description']?.toString() ?? '',
    features: ((m['features'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    trialDays: (m['trial_days'] as num?)?.toInt() ?? 0,
  );
}

class WalletRepository {
  static SupabaseClient get _c {
    final c = SupabaseService.client;
    if (c == null || c.auth.currentSession == null) {
      throw StateError('Vui lòng đăng nhập.');
    }
    return c;
  }

  static Future<List<PlanInfo>> fetchPlans() async {
    final rows = await _c
        .from('learning_plans')
        .select('code,name,description,features,trial_days')
        .eq('published', true)
        .order('sort_order');
    return rows.map(PlanInfo.fromMap).toList();
  }

  // Phải liệt kê cột: select() trần sẽ lỗi vì wallet_hash/provider_token bị ẩn
  static Future<LinkedWallet?> fetchLinked() async {
    final r = await _c
        .from('parent_wallets')
        .select('provider,wallet_hint')
        .eq('parent_id', _c.auth.currentUser!.id)
        .eq('status', 'linked')
        .maybeSingle();
    return r == null
        ? null
        : LinkedWallet(r['provider'] as String, r['wallet_hint'] as String);
  }

  static Future<bool> hasUsedTrial() async {
    final r = await _c
        .from('trial_grants')
        .select('parent_id')
        .eq('parent_id', _c.auth.currentUser!.id)
        .maybeSingle();
    return r != null;
  }

  static Future<void> link({
    required String provider,
    required String phone,
    required String parentToken,
  }) async {
    await _c.rpc('link_wallet', params: {
      'p_provider': provider,
      'p_phone': phone,
      'p_token': parentToken,
    });
  }

  static Future<void> startTrial(String parentToken) async {
    await _c.rpc('start_basic_trial', params: {'p_token': parentToken});
  }
}