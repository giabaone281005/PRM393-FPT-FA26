import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';

/// Events invalidate cached views; authoritative data is still fetched via RLS/RPC.
/// A single channel follows the current account, never the previous user's token.
class AccountLiveSync {
  static const familyTables = {
    'kid_profiles',
    'subscriptions',
    'kid_progress',
    'study_sessions',
    'study_daily_usage',
    'kid_equipment',
    'lessons',
    'user_roles',
  };
  static const commerceTables = {
    'learning_orders',
    'plan_prices',
    'subscriptions',
    'demo_payment_transactions',
  };
  static final _events = StreamController<Set<String>>.broadcast();
  static RealtimeChannel? _channel;
  static String? _account;
  static Timer? _debounce, _fallback;
  static final _pending = <String>{};
  static bool _foreground = true;

  static StreamSubscription<Set<String>> watch(
    Set<String> tables,
    void Function() changed,
  ) => _events.stream.listen((events) {
    if (events.contains('*') || events.any(tables.contains)) changed();
  });

  static void bind(String? account) {
    final client = SupabaseService.client;
    if (_account == account && (_channel != null || client == null)) return;
    final old = _channel;
    _channel = null;
    _account = account;
    _debounce?.cancel();
    _debounce = null;
    _fallback?.cancel();
    _pending.clear();
    if (old != null && client != null) unawaited(client.removeChannel(old));
    if (account == null || client == null) return;
    _foreground =
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
    var channel = client.channel('account-sync:$account');
    for (final table in {
      ...familyTables,
      ...commerceTables,
      'notifications',
      'support_requests',
    }) {
      // Lessons expose selected columns only. Subscribing to a table without
      // full SELECT can reject the whole channel; curriculum uses fallback sync.
      if (table == 'lessons') continue;
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) {
          if (_account == account) _queue(table);
        },
      );
    }
    _channel = channel;
    channel.subscribe((status, error) {
      if (_account == account && status == RealtimeSubscribeStatus.subscribed) {
        _queue('*');
      }
    });
    _fallback = Timer.periodic(const Duration(seconds: 30), (_) => _queue('*'));
  }

  static void foreground(bool value) {
    _foreground = value;
    if (value && _account != null) _queue('*');
    if (!value) {
      _debounce?.cancel();
      _debounce = null;
      _pending.clear();
    }
  }

  static void _queue(String table) {
    if (!_foreground || _account == null) return;
    _pending.add(table);
    // Fixed batching window: continuous heartbeats cannot postpone sync forever.
    _debounce ??= Timer(const Duration(milliseconds: 700), () {
      _debounce = null;
      final changed = Set<String>.of(_pending);
      _pending.clear();
      if (_foreground && _account != null) _events.add(changed);
    });
  }
}
