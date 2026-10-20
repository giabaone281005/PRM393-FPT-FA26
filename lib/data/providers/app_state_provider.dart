import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/kid_profile.dart';
import '../models/lesson.dart';
import '../models/subscription_model.dart';
import '../models/learning_summary.dart';
import '../repositories/kid_repository.dart';
import '../repositories/mascot_repository.dart';
import '../repositories/lesson_repository.dart';
import '../repositories/learning_statistics_repository.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/study_repository.dart';
import '../repositories/family_report_repository.dart';
import '../repositories/account_live_sync.dart';

class AppStateProvider extends ChangeNotifier with WidgetsBindingObserver {
  final List<KidProfile> _kids = [];
  List<Lesson> _lessons = [];
  Map<String, LearningSummary> _summaries = {};
  Map<String, dynamic> _report = {};
  final Future<Map<String, dynamic>> Function() _familyReportLoader;
  Future<void>? _reportRefresh;
  bool _reportLoading = false, _disposed = false;
  String? _reportError;
  DateTime? _reportSyncedAt;
  SubscriptionModel _subscription = SubscriptionModel.defaultBasic(
    'signed_out',
  );
  StreamSubscription<dynamic>? _authListener;
  StreamSubscription<Set<String>>? _liveListener;
  int _revision = 0, _selected = 0, _nav = 0, _statsRevision = 0;
  int get statsRevision => _statsRevision;
  String? _account, _error, _parentToken;
  DateTime? _unlockUntil;
  String _hat = 'Mũ Thám Tử', _glasses = 'Kính Tri Thức';
  bool _loading = false,
      _hasPin = false,
      _admin = false,
      _staff = false,
      _sound = true;
  Future<void>? _cloudRefresh;
  bool _refreshAgain = false;
  ThemeMode _theme = ThemeMode.light;
  AppStateProvider({
    Future<Map<String, dynamic>> Function()? familyReportLoader,
  }) : _familyReportLoader =
           familyReportLoader ?? FamilyReportRepository.fetch {
    WidgetsBinding.instance.addObserver(this);
    _authListener = SupabaseService.client?.auth.onAuthStateChange.listen(
      (_) => refreshFromCloud(),
    );
    _liveListener = AccountLiveSync.watch(AccountLiveSync.familyTables, () {
      if (!_disposed && !_loading && accountId != null) refreshFromCloud();
    });
    refreshFromCloud();
  }
  @override
  void dispose() {
    _disposed = true;
    _revision++;
    WidgetsBinding.instance.removeObserver(this);
    _authListener?.cancel();
    _liveListener?.cancel();
    AccountLiveSync.bind(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AccountLiveSync.foreground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      lockParentPortal();
    }
  }

  bool get hasKids => _kids.isNotEmpty;
  List<KidProfile> get kidProfiles => List.unmodifiable(_kids);
  KidProfile get currentKid => _kids[_selected];
  List<Lesson> get currentLessons => List.unmodifiable(_lessons);
  int get selectedKidIndex => _selected;
  String? get syncError => _error;
  bool get isLoadingFromCloud => _loading;
  bool get hasParentPin => _hasPin;
  bool get isParentUnlocked =>
      _parentToken != null && (_unlockUntil?.isAfter(DateTime.now()) ?? false);
  String? get parentToken => isParentUnlocked ? _parentToken : null;
  bool get isAdmin => _admin;
  bool get isStaff => _staff;
  bool get isPlusActive => _subscription.isPlusActive;
  int get maxAllowedKids => _subscription.effectiveMaxKids;
  SubscriptionModel get subscription => _subscription;
  String get currentHat => _hat;
  String get currentGlasses => _glasses;
  int get currentNavIndex => _nav;
  ThemeMode get themeMode => _theme;
  bool get isDarkMode => _theme == ThemeMode.dark;
  bool get soundEnabled => _sound;
  Map<String, dynamic> get familyReport => _report;
  String? get accountId => SupabaseService.currentUser?.id;
  bool get isLoadingFamilyReport => _reportLoading;
  String? get familyReportError => _reportError;
  DateTime? get familyReportSyncedAt => _reportSyncedAt;
  LearningSummary summaryFor(String id) =>
      _summaries[id] ?? const LearningSummary();
  void setNavIndex(int index) {
    _nav = index.clamp(0, 3);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _theme = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('pref:${_account ?? "guest"}:dark', isDarkMode);
  }

  Future<void> toggleSound() async {
    _sound = !_sound;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('pref:${_account ?? "guest"}:sound', _sound);
  }

  void _reset() {
    _kids.clear();
    _lessons = [];
    _selected = 0;
    _nav = 0;
    _summaries = {};
    _report = {};
    _reportError = null;
    _reportSyncedAt = null;
    _parentToken = null;
    _unlockUntil = null;
    _hasPin = false;
    _admin = false;
    _staff = false;
    _subscription = SubscriptionModel.defaultBasic('signed_out');
    _hat = 'Mũ Thám Tử';
    _glasses = 'Kính Tri Thức';
  }

  Future<void> refreshFromCloud() {
    if (_disposed) return Future.value();
    final uid = SupabaseService.currentUser?.id;
    if (_account != uid) {
      // Clear the old family immediately, even while its request is in flight.
      _revision++;
      _reset();
      _account = uid;
      notifyListeners();
    }
    if (_cloudRefresh != null) {
      _refreshAgain = true;
      return _cloudRefresh!;
    }
    late final Future<void> task;
    task = _refreshCloudQueue().whenComplete(() {
      if (identical(_cloudRefresh, task)) _cloudRefresh = null;
    });
    _cloudRefresh = task;
    return task;
  }

  Future<void> _refreshCloudQueue() async {
    do {
      _refreshAgain = false;
      await _refreshCloudOnce();
    } while (_refreshAgain && !_disposed);
  }

  Future<void> _refreshCloudOnce() async {
    final version = ++_revision, uid = SupabaseService.currentUser?.id;
    if (_account != uid) {
      _reset();
      _account = uid;
    }
    AccountLiveSync.bind(uid);
    if (uid == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await StudyRepository.rpc('ensure_family');
      final household = await KidRepository.fetchKids();
      final subscription =
          await SubscriptionRepository.fetchCurrentSubscription();
      final report = await _familyReportLoader();
      final entitlements = Map<String, dynamic>.from(
        report['entitlements'] as Map? ?? {},
      );
      final admin = await SubscriptionRepository.checkIfAdmin();
      final staff = await StudyRepository.rpc('is_staff') == true;
      final hasPin = await StudyRepository.rpc('has_parent_pin') == true;
      final prefs = await SharedPreferences.getInstance();
      if (version != _revision) return;
      var expires = DateTime.now().add(const Duration(minutes: 15));
      if (subscription.expiresAt != null &&
          subscription.expiresAt!.isBefore(expires)) {
        expires = subscription.expiresAt!;
      }
      await prefs.setString(
        'family:$uid',
        jsonEncode({
          'expires': expires.toIso8601String(),
          'kids': household.map((k) => k.toJson()).toList(),
          'subscription': subscription.toMap(),
          'report': report,
          'hasPin': hasPin,
        }),
      );
      if (version != _revision) return;
      final previous = hasKids
          ? currentKid.id
          : prefs.getString('pref:$uid:kid');
      _subscription = subscription;
      _admin = admin;
      _staff = staff;
      _hasPin = hasPin;
      _report = report;
      _reportSyncedAt = DateTime.now();
      _reportError = null;
      _statsRevision++;
      _theme = prefs.getBool('pref:$uid:dark') == true
          ? ThemeMode.dark
          : ThemeMode.light;
      _sound = prefs.getBool('pref:$uid:sound') ?? true;
      final allowed = household
          .where(
            (k) =>
                !k.archived &&
                (subscription.isPlusActive ||
                    k.id == entitlements['active_kid_id']),
          )
          .toList();
      _kids
        ..clear()
        ..addAll(allowed);
      _selected = _kids.indexWhere((k) => k.id == previous);
      if (_selected < 0) _selected = 0;
      _summaries = {};
      for (final raw in (report['kids'] as List? ?? [])) {
        final k = Map<String, dynamic>.from(raw as Map);
        final days = k['days'] as List? ?? [];
        _summaries[k['id'] as String] = LearningSummary(
          completedLessons: (k['completed'] as num).toInt(),
          todayMinutes: (k['today_seconds'] as num).toInt() ~/ 60,
          weekMinutes:
              days.fold<int>(
                0,
                (sum, d) => sum + (d['total_seconds'] as num).toInt(),
              ) ~/
              60,
        );
      }
      for (final kid in _kids) {
        kid.usedScreenTimeMinutes = summaryFor(kid.id).todayMinutes;
      }
      if (hasKids) {
        final id = currentKid.id;
        final lessons = await LessonRepository.fetchLessonsForGrade(
          currentKid.grade,
          kidId: id,
        );
        final gear = await MascotRepository.fetchMascotGear(id);
        if (version != _revision) return;
        _lessons = lessons;
        _hat = gear.hat;
        _glasses = gear.glasses;
        await prefs.setString('pref:$uid:kid', id);
      } else {
        _lessons = [];
      }
    } catch (e) {
      if (version == _revision) {
        _error = 'Không tải được dữ liệu. Kiểm tra kết nối hoặc thử lại.';
        if (StudyRepository.isTransient(e)) {
          final prefs = await SharedPreferences.getInstance();
          final raw = prefs.getString('family:$uid');
          if (raw != null && version == _revision) {
            try {
              final c = Map<String, dynamic>.from(jsonDecode(raw));
              if (DateTime.parse(c['expires']).isAfter(DateTime.now())) {
                _subscription = SubscriptionModel.fromMap(
                  Map<String, dynamic>.from(c['subscription']),
                );
                _report = Map<String, dynamic>.from(c['report']);
                _hasPin = c['hasPin'] == true;
                final ent = Map<String, dynamic>.from(_report['entitlements']);
                _kids
                  ..clear()
                  ..addAll(
                    (c['kids'] as List)
                        .map(
                          (k) =>
                              KidProfile.fromJson(Map<String, dynamic>.from(k)),
                        )
                        .where(
                          (k) =>
                              !k.archived &&
                              (_subscription.isPlusActive ||
                                  k.id == ent['active_kid_id']),
                        ),
                  );
                _selected = _selected.clamp(
                  0,
                  _kids.isEmpty ? 0 : _kids.length - 1,
                );
                if (hasKids) {
                  final cachedLessons =
                      await LessonRepository.fetchLessonsForGrade(
                        currentKid.grade,
                        kidId: currentKid.id,
                      );
                  if (version != _revision) return;
                  _lessons = cachedLessons;
                }
                _error = 'Đang ngoại tuyến. Dữ liệu gần nhất được giữ tối đa 15 phút; kết quả chờ xác nhận khi có mạng.';
              }
            } catch (_) {
              /* Invalid or expired cache never grants access. */
            }
          }
        }
      }
    } finally {
      if (version == _revision && !_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshSubscription() => refreshFromCloud();
  Future<void> refreshFamilyReport() {
    if (_disposed || _loading || !isParentUnlocked || accountId == null) {
      return Future.value();
    }
    return _reportRefresh ??= _loadFamilyReport().whenComplete(() {
      _reportRefresh = null;
    });
  }

  Future<void> _loadFamilyReport() async {
    final uid = accountId, version = _revision;
    _reportLoading = true;
    _reportError = null;
    notifyListeners();
    try {
      final report = await _familyReportLoader();
      if (_disposed ||
          uid != accountId ||
          version != _revision ||
          !isParentUnlocked) {
        return;
      }
      _report = report;
      _reportSyncedAt = DateTime.now();
      for (final raw in report['kids'] as List? ?? []) {
        final kid = Map<String, dynamic>.from(raw as Map);
        _summaries[kid['id'] as String] = LearningSummary(
          completedLessons: (kid['completed'] as num?)?.toInt() ?? 0,
          todayMinutes: ((kid['today_seconds'] as num?)?.toInt() ?? 0) ~/ 60,
          weekMinutes:
              (kid['days'] as List? ?? []).fold<int>(
                0,
                (sum, day) =>
                    sum + ((day['total_seconds'] as num?)?.toInt() ?? 0),
              ) ~/
              60,
        );
      }
      for (final kid in _kids) {
        kid.usedScreenTimeMinutes = summaryFor(kid.id).todayMinutes;
      }
    } catch (_) {
      if (!_disposed &&
          uid == accountId &&
          version == _revision &&
          isParentUnlocked) {
        _reportError = 'Chưa cập nhật được báo cáo. Dữ liệu đang hiển thị là lần đồng bộ trước.';
      }
    } finally {
      _reportLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void switchKid(int index) {
    if (index < 0 || index >= _kids.length) return;
    _selected = index;
    _lessons = [];
    refreshFromCloud();
  }

  Future<bool> addKidProfile(String name, int grade) async {
    try {
      await StudyRepository.rpc('manage_kid', {
        'p_id': null,
        'p_name': name,
        'p_grade': grade,
        'p_archive': false,
        'p_token': parentToken,
      });
      await refreshFromCloud();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateKidProfile(
    String id, {
    String? nickname,
    int? grade,
  }) async {
    final all = (_report['kids'] as List? ?? [])
        .where((k) => k['id'] == id)
        .toList();
    if (all.isEmpty) return false;
    try {
      await StudyRepository.rpc('manage_kid', {
        'p_id': id,
        'p_name': nickname ?? all.first['nickname'],
        'p_grade': grade ?? all.first['grade'],
        'p_archive': false,
        'p_token': parentToken,
      });
      await refreshFromCloud();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteKidProfile(String id) async => archiveKid(id, true);
  Future<bool> archiveKid(String id, bool archive) async {
    final all = (_report['kids'] as List? ?? [])
        .where((k) => k['id'] == id)
        .toList();
    if (all.isEmpty) return false;
    try {
      await StudyRepository.rpc('manage_kid', {
        'p_id': id,
        'p_name': all.first['nickname'],
        'p_grade': all.first['grade'],
        'p_archive': archive,
        'p_token': parentToken,
      });
      await refreshFromCloud();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> chooseBasicKid(String id) async {
    await StudyRepository.rpc('set_active_kid', {
      'p_kid': id,
      'p_token': parentToken,
    });
    await refreshFromCloud();
  }

  Future<bool> verifyParentPin(String pin) async {
    try {
      final token = await StudyRepository.rpc('unlock_parent', {'p_pin': pin});
      if (token is! String || token.isEmpty) return false;
      _parentToken = token;
      _unlockUntil = DateTime.now().add(const Duration(minutes: 14));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateParentPinCode(String pin, {String oldPin = ''}) async {
    try {
      if (await StudyRepository.rpc('set_parent_pin', {
            'p_old': oldPin,
            'p_new': pin,
          }) !=
          true) {
        return false;
      }
      _hasPin = true;
      return await verifyParentPin(pin);
    } catch (_) {
      return false;
    }
  }

  void lockParentPortal() {
    _parentToken = null;
    _unlockUntil = null;
    notifyListeners();
    if (SupabaseService.isLoggedIn) {
      StudyRepository.rpc('lock_parent').catchError((_) => null);
    }
  }

  Future<void> updateScreenTimeLimit(int minutes) async {
    await StudyRepository.rpc('set_screen_limit', {
      'p_kid': currentKid.id,
      'p_minutes': minutes,
      'p_token': parentToken,
    });
    await refreshFromCloud();
  }

  // Legacy minigames are recreational; ranked XP is awarded by verified study sessions only.
  Future<bool> submitArenaScore(int scoreGained) async => false;
  Future<bool> buyAndEquipMascotItem({
    required String type,
    required String name,
    required int costStars,
  }) async {
    try {
      final wardrobe = Map<String, dynamic>.from(
        await StudyRepository.rpc('get_wardrobe', {'p_kid': currentKid.id})
            as Map,
      );
      final item = (wardrobe['items'] as List).firstWhere(
        (i) => i['name'] == name && i['slot'] == type,
      );
      await StudyRepository.rpc('buy_equip_item', {
        'p_kid': currentKid.id,
        'p_item': item['id'],
        'p_buy': true,
      });
      await refreshFromCloud();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Records practice answer in learning statistics and updates kid streak.
  Future<void> recordPracticeAnswer({
    required bool isCorrect,
    String? kidId,
    String? eventId,
    DateTime? timestamp,
  }) async {
    final effectiveKidId = kidId ?? (hasKids ? currentKid.id : null);
    if (!SupabaseService.isLoggedIn) {
      await LearningStatisticsRepository.recordAnswer(
        isCorrect: isCorrect,
        kidId: effectiveKidId,
        eventId: eventId,
        timestamp: timestamp,
      );
    }
    if (effectiveKidId != null) {
      await refreshStreakForKid(effectiveKidId);
    }
    _statsRevision++;
    notifyListeners();
  }

  /// Uses server streaks when signed in; local practice cannot extend them.
  Future<void> refreshStreakForKid(String kidId) async {
    try {
      final streak = await LearningStatisticsRepository.getStreak(kidId: kidId);
      final idx = _kids.indexWhere((k) => k.id == kidId);
      if (idx != -1) {
        _kids[idx].streakCount = streak.currentStreak;
      }
    } catch (_) {}
  }

  /// Notifies listeners that learning statistics were updated.
  void notifyStatsChanged() {
    _statsRevision++;
    notifyListeners();
  }
}
