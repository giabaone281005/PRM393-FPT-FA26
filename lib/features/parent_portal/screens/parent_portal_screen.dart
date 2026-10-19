import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/app_state_provider.dart';
import '../../../core/services/app_route_observer.dart';
import '../../kid_profile/popups/add_kid_dialog.dart';
import '../../kid_profile/popups/edit_kid_dialog.dart';
import '../../../data/models/kid_profile.dart';
import '../../../data/repositories/study_repository.dart';
import '../../subscriptions/learning_packages_screen.dart';
import '../../auth/account_screen.dart';
import '../parent_area.dart';
import 'parent_dashboard_view.dart';
import '../../../core/supabase/supabase_service.dart';
import '../popups/change_pin_dialog.dart';
import 'notifications_screen.dart';
import 'support_screen.dart';

class ParentPortalScreen extends StatefulWidget {
  const ParentPortalScreen({super.key});
  @override
  State<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends State<ParentPortalScreen>
    with WidgetsBindingObserver, RouteAware {
  Timer? _timer;
  AppStateProvider? _state;
  ModalRoute<dynamic>? _route;
  bool _foreground = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = context.read<AppStateProvider>();
    final route = ModalRoute.of(context);
    if (_route != route && route != null) {
      appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
        _refresh();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    scheduleMicrotask(() => _state?.lockParentPortal());
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted ||
        !_foreground ||
        _route?.isCurrent == false ||
        _state?.isParentUnlocked != true) {
      return;
    }
    await _state?.refreshFamilyReport();
  }

  @override
  void didPopNext() => _refresh();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refresh();
  }

  Future<void> _action(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa thực hiện được. Kiểm tra kết nối hoặc mở lại cổng phụ huynh.',
            ),
          ),
        );
      }
    }
  }

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    if (!state.isParentUnlocked) {
      return ParentAreaLocked(
        onUnlocked: () {
          if (mounted) {
            setState(() {});
            _refresh();
          }
        },
      );
    }
    return ParentDashboardView(
      report: state.familyReport,
      limits: {
        for (final kid in state.kidProfiles) kid.id: kid.screenTimeLimitMinutes,
      },
      plus: state.isPlusActive,
      maxKids: state.maxAllowedKids,
      loading: state.isLoadingFromCloud || state.isLoadingFamilyReport,
      error: state.familyReportError ?? state.syncError,
      syncedAt: state.familyReportSyncedAt,
      email: SupabaseService.currentUser?.email ?? '',
      sound: state.soundEnabled,
      dark: state.isDarkMode,
      onRefresh: state.refreshFamilyReport,
      onNotifications: () => _open(const NotificationsScreen()),
      onExit: () {
        state.lockParentPortal();
        Navigator.pop(context);
      },
      onAdd: () => showDialog(
        context: context,
        builder: (_) => AddKidDialog(state: state),
      ),
      onEdit: (kid) => showDialog(
        context: context,
        builder: (_) => EditKidDialog(
          kid: KidProfile(
            id: kid['id'] as String,
            nickname: kid['nickname'] as String,
            grade: kid['grade'] as int,
          ),
          state: state,
        ),
      ),
      onRestore: (kid) => _action(() async {
        if (!await state.archiveKid(kid['id'] as String, false)) {
          throw StateError('Không khôi phục được');
        }
      }),
      onChoose: (kid) =>
          _action(() => state.chooseBasicKid(kid['id'] as String)),
      onLimit: (kid) => _limit(kid, state),
      onPlans: () => _open(const LearningPackagesScreen()),
      onAccount: () => _open(const AccountScreen()),
      onPin: () => showDialog(
        context: context,
        builder: (_) => ChangePinDialog(state: state),
      ),
      onSupport: () => _open(const SupportScreen()),
      onSound: state.toggleSound,
      onTheme: state.toggleTheme,
    );
  }

  Future<void> _limit(Map<String, dynamic> kid, AppStateProvider state) async {
    final profiles = state.kidProfiles.where(
      (profile) => profile.id == kid['id'],
    );
    var value = profiles.isEmpty
        ? 30.0
        : profiles.first.screenTimeLimitMinutes.clamp(15, 120).toDouble();
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text('Thời gian học của ${kid['nickname']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.round()} phút/ngày'),
              Slider(
                value: value,
                min: 15,
                max: 120,
                divisions: 21,
                onChanged: (v) => update(() => value = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, value.round()),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _action(() async {
      await StudyRepository.rpc('set_screen_limit', {
        'p_kid': kid['id'],
        'p_minutes': selected,
        'p_token': state.parentToken,
      });
      await state.refreshFromCloud();
    });
  }
}
