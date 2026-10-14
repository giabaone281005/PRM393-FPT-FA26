import 'package:flutter/material.dart';
import '../models/kid_profile.dart';
import '../models/lesson.dart';
import '../datasources/sample_curriculum.dart';
import '../repositories/kid_repository.dart';
import '../repositories/arena_repository.dart';
import '../repositories/mascot_repository.dart';

class AppStateProvider extends ChangeNotifier {
  // Dual Account: Parent & Kids (Max 3 – BR-04)
  final List<KidProfile> _kidProfiles = [
    KidProfile(
      id: 'kid-1',
      nickname: 'Bé Bo',
      grade: 5,
      currentHearts: 5,
      energyStars: 180,
      streakCount: 7,
      screenTimeLimitMinutes: 30,
      usedScreenTimeMinutes: 14,
    ),
    KidProfile(
      id: 'kid-2',
      nickname: 'Bé Bắp',
      grade: 2,
      currentHearts: 4,
      energyStars: 95,
      streakCount: 4,
      screenTimeLimitMinutes: 20,
      usedScreenTimeMinutes: 8,
    ),
  ];

  int _selectedKidIndex = 0;
  String _parentPin = '1234'; // BR-01
  bool _isParentUnlocked = false;

  // Mascot Customization
  String _currentHat = 'Mũ Thám Tử';
  String _currentGlasses = 'Kính Tri Thức';

  bool _isLoadingFromCloud = false;

  late List<Lesson> _currentLessons;

  AppStateProvider() {
    _loadLessonsForCurrentKid();
    _syncFromSupabase();
  }

  int _currentNavIndex = 0;
  ThemeMode _themeMode = ThemeMode.light;

  List<KidProfile> get kidProfiles => _kidProfiles;
  KidProfile get currentKid => _kidProfiles[_selectedKidIndex];
  int get selectedKidIndex => _selectedKidIndex;
  List<Lesson> get currentLessons => _currentLessons;
  bool get isParentUnlocked => _isParentUnlocked;
  String get currentHat => _currentHat;
  String get currentGlasses => _currentGlasses;
  bool get isLoadingFromCloud => _isLoadingFromCloud;
  String get parentPin => _parentPin;
  int get currentNavIndex => _currentNavIndex;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  void unlockLesson(String lessonId) {
    final idx = _currentLessons.indexWhere((l) => l.id == lessonId);
    if (idx != -1) {
      _currentLessons[idx].status = LessonStatus.available;
      notifyListeners();
    }
  }

  void unlockAllLessons() {
    for (var l in _currentLessons) {
      if (l.status == LessonStatus.locked) {
        l.status = LessonStatus.available;
      }
    }
    notifyListeners();
  }

  void _loadLessonsForCurrentKid() {
    _currentLessons = SampleCurriculum.getLessonsForGrade(currentKid.grade);
  }

  /// Try to load real kid profiles from Supabase; fallback to local demo data
  Future<void> _syncFromSupabase() async {
    _isLoadingFromCloud = true;
    notifyListeners();

    try {
      final cloudKids = await KidRepository.fetchKids();
      if (cloudKids.isNotEmpty) {
        _kidProfiles.clear();
        _kidProfiles.addAll(cloudKids);
        _selectedKidIndex = 0;
        _loadLessonsForCurrentKid();
      }

      // Load mascot gear
      final gear = await MascotRepository.fetchMascotGear(currentKid.id);
      _currentHat = gear.hat;
      _currentGlasses = gear.glasses;
    } catch (_) {
      // Keep local demo data
    }

    _isLoadingFromCloud = false;
    notifyListeners();
  }

  /// Refresh from cloud on demand
  Future<void> refreshFromCloud() => _syncFromSupabase();

  void switchKid(int index) {
    if (index >= 0 && index < _kidProfiles.length) {
      _selectedKidIndex = index;
      _loadLessonsForCurrentKid();
      MascotRepository.fetchMascotGear(currentKid.id).then((gear) {
        _currentHat = gear.hat;
        _currentGlasses = gear.glasses;
        notifyListeners();
      });
      notifyListeners();
    }
  }

  // BR-04: Maximum 3 kid profiles
  Future<bool> addKidProfile(String nickname, int grade) async {
    if (_kidProfiles.length >= 3) return false;

    // Try cloud-first
    final cloudKid = await KidRepository.createKid(nickname: nickname, grade: grade);
    final kid = cloudKid ??
        KidProfile(
          id: 'kid-${DateTime.now().millisecondsSinceEpoch}',
          nickname: nickname,
          grade: grade,
          currentHearts: 5,
          energyStars: 0,
          streakCount: 1,
        );

    _kidProfiles.add(kid);
    notifyListeners();
    return true;
  }

  // Delete Kid Profile (with cloud sync)
  Future<bool> deleteKidProfile(String id) async {
    if (_kidProfiles.length <= 1) return false; // Giữ ít nhất 1 bé

    final index = _kidProfiles.indexWhere((k) => k.id == id);
    if (index != -1) {
      await KidRepository.deleteKid(id);
      _kidProfiles.removeAt(index);
      if (_selectedKidIndex >= _kidProfiles.length) {
        _selectedKidIndex = 0;
      }
      _loadLessonsForCurrentKid();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Edit Kid Profile
  Future<void> updateKidProfile(String id, {String? nickname, int? grade}) async {
    final index = _kidProfiles.indexWhere((k) => k.id == id);
    if (index != -1) {
      final updated = _kidProfiles[index];
      if (nickname != null && nickname.isNotEmpty) {
        updated.nickname = nickname;
      }
      if (grade != null && grade >= 1 && grade <= 5) {
        updated.grade = grade;
      }
      await KidRepository.updateKidStats(id);
      _loadLessonsForCurrentKid();
      notifyListeners();
    }
  }

  // BR-01: Parent Portal PIN Verification
  bool verifyParentPin(String pin) {
    if (pin == _parentPin) {
      _isParentUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Update Parent PIN & Sync Cloud
  Future<bool> updateParentPinCode(String newPin) async {
    if (newPin.length == 4) {
      _parentPin = newPin;
      await KidRepository.updateParentPin(newPin);
      notifyListeners();
      return true;
    }
    return false;
  }

  // BR-01: Alternative 2-digit multiplication challenge
  bool verifyMultiplicationChallenge(int answer, int expected) {
    if (answer == expected) {
      _isParentUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockParentPortal() {
    _isParentUnlocked = false;
    notifyListeners();
  }

  void updateScreenTimeLimit(int minutes) {
    currentKid.screenTimeLimitMinutes = minutes;
    KidRepository.updateKidStats(currentKid.id, screenTimeLimitMinutes: minutes);
    notifyListeners();
  }

  // Heart Economy (BR-03)
  void loseHeart() {
    currentKid.loseHeart();
    KidRepository.updateKidStats(currentKid.id, hearts: currentKid.currentHearts);
    notifyListeners();
  }

  void restoreHeartsInGarden(int count) {
    currentKid.restoreHearts(count);
    KidRepository.updateKidStats(currentKid.id, hearts: currentKid.currentHearts);
    notifyListeners();
  }

  // Ghi nhận hoàn thành phiên luyện tập tại Vườn (BR-03)
  Future<void> recordPracticeSession(int drillsDone, int heartsRecovered) async {
    await KidRepository.logPracticeGarden(
      kidId: currentKid.id,
      heartsRestored: heartsRecovered,
      mathDrillsCompleted: drillsDone,
    );
  }

  // Lesson Progress & Streak (BR-02)
  void completeLesson(String lessonId, int stars, int xp) {
    final lessonIndex = _currentLessons.indexWhere((l) => l.id == lessonId);
    if (lessonIndex != -1) {
      _currentLessons[lessonIndex].status = LessonStatus.completed;
      _currentLessons[lessonIndex].starsEarned = stars;

      // Unlock next lesson
      if (lessonIndex + 1 < _currentLessons.length) {
        if (_currentLessons[lessonIndex + 1].status == LessonStatus.locked) {
          _currentLessons[lessonIndex + 1].status = LessonStatus.available;
        }
      }

      // Sync progress to Supabase
      KidRepository.saveProgress(
        kidId: currentKid.id,
        lessonId: lessonId,
        isCompleted: true,
        starsEarned: stars,
        accuracyPercent: 100,
      );
    }

    currentKid.addStars(stars);
    KidRepository.updateKidStats(currentKid.id, energyStars: currentKid.energyStars);

    // Update streak (BR-02: 21:00 cutoff)
    final now = DateTime.now();
    if (now.hour < 21) {
      currentKid.streakCount++;
      KidRepository.updateStreak(currentKid.id, currentKid.streakCount);
    }

    notifyListeners();
  }

  // Đấu Trường (Arena) - Ghi điểm thi đấu tuần
  Future<bool> submitArenaScore(int scoreGained) async {
    final success = await ArenaRepository.submitWeeklyScore(
      kidId: currentKid.id,
      grade: currentKid.grade,
      xpEarned: scoreGained,
    );

    currentKid.addStars(scoreGained ~/ 10);
    KidRepository.updateKidStats(currentKid.id, energyStars: currentKid.energyStars);
    notifyListeners();
    return success;
  }

  // Mascot Wardrobe Equipment & Buying with Stars
  Future<bool> buyAndEquipMascotItem({
    required String type, // 'hat' or 'glasses'
    required String name,
    required int costStars,
  }) async {
    if (currentKid.energyStars < costStars && costStars > 0) {
      return false;
    }

    if (costStars > 0) {
      currentKid.energyStars -= costStars;
      await KidRepository.updateKidStats(currentKid.id, energyStars: currentKid.energyStars);
    }

    if (type == 'hat') {
      _currentHat = name;
    } else {
      _currentGlasses = name;
    }

    await MascotRepository.saveMascotGear(
      kidId: currentKid.id,
      hat: _currentHat,
      glasses: _currentGlasses,
    );

    notifyListeners();
    return true;
  }

  void updateMascotGear({String? hat, String? glasses}) {
    if (hat != null) _currentHat = hat;
    if (glasses != null) _currentGlasses = glasses;
    MascotRepository.saveMascotGear(
      kidId: currentKid.id,
      hat: _currentHat,
      glasses: _currentGlasses,
    );
    notifyListeners();
  }
}
