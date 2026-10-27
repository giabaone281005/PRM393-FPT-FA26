import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_activity.dart';
import 'package:brilliant_mobile/learning_catalog.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Clock implements Stopwatch {
  int milliseconds = 0;
  bool running = false;
  void advance(int seconds) {
    if (running) milliseconds += seconds * 1000;
  }

  @override
  bool get isRunning => running;
  @override
  Duration get elapsed => Duration(milliseconds: milliseconds);
  @override
  int get elapsedMilliseconds => milliseconds;
  @override
  int get elapsedMicroseconds => milliseconds * 1000;
  @override
  int get elapsedTicks => elapsedMicroseconds;
  @override
  int get frequency => 1000000;
  @override
  void start() => running = true;
  @override
  void stop() => running = false;
  @override
  void reset() => milliseconds = 0;
}

void main() {
  late LearningStore store;
  late SharedPreferences preferences;
  var writes = 0;
  setUp(() async {
    writes = 0;
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    store = LearningStore(
      preferences,
      writeSnapshot: (key, value) async {
        writes++;
        return preferences.setString(key, value);
      },
    );
    await store.createDeviceProfile('An');
  });
  tearDown(() => store.dispose());

  Widget lesson(_Clock clock) => MaterialApp(
    theme: buildAppTheme(),
    home: LessonPage(topic: topicById('logic'), store: store, stopwatch: clock),
  );

  test(
    'time labels expose seconds and cross minute/hour boundaries exactly',
    () {
      expect(studyClockLabel(0), '00:00');
      expect(studyClockLabel(59000), '00:59');
      expect(studyClockLabel(60000), '01:00');
      expect(studyClockLabel(62000), '01:02');
      expect(studyTimeLabel(-1), '0 giây');
      expect(studyTimeLabel(12000), '12 giây');
      expect(studyTimeLabel(59999), '59 giây');
      expect(studyTimeLabel(60000), '1 phút');
      expect(studyTimeLabel(90000), '1 phút 30 giây');
      expect(studyTimeLabel(3600000), '1 giờ');
      expect(studyTimeLabel(3662000), '1 giờ 1 phút 2 giây');
    },
  );

  testWidgets('lesson ticks every second without writing every second', (
    tester,
  ) async {
    final clock = _Clock();
    await tester.pumpWidget(lesson(clock));
    await tester.pumpAndSettle();
    final initialWrites = writes;
    clock.advance(12);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Phiên này · 00:12'), findsOneWidget);
    expect(writes, initialWrites);
    clock.advance(50);
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(find.text('Phiên này · 01:02'), findsOneWidget);
    expect(store.activityOn(DateTime.now()).activeMs, 62000);
    expect(writes, initialWrites + 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(store.activityOn(DateTime.now()).activeMs, 62000);
  });

  testWidgets(
    'time resumes from saved seconds and survives reopening without duplication',
    (tester) async {
      await store.saveProgress('logic', {
        'version': 3,
        'step': 0,
        'seconds': 45,
        'activeMsByDay': {activityDay(DateTime.now()): 45000},
      });
      final clock = _Clock();
      await tester.pumpWidget(lesson(clock));
      await tester.pumpAndSettle();
      expect(find.text('Phiên này · 00:45'), findsOneWidget);
      clock.advance(10);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      final nextClock = _Clock();
      await tester.pumpWidget(lesson(nextClock));
      await tester.pumpAndSettle();
      expect(find.text('Phiên này · 00:55'), findsOneWidget);
      nextClock.advance(5);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Phiên này · 01:00'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      final reopened = LearningStore(preferences);
      expect(reopened.activityOn(DateTime.now()).activeMs, 60000);
      reopened.dispose();
    },
  );

  testWidgets(
    'covered routes and background time are paused and not added to study totals',
    (tester) async {
      final clock = _Clock();
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await tester.pumpWidget(lesson(clock));
      await tester.pumpAndSettle();
      clock.advance(8);
      final navigator = Navigator.of(tester.element(find.byType(LessonPage)));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Another page')),
        ),
      );
      await tester.pumpAndSettle();
      expect(clock.isRunning, false);
      clock.advance(120);
      await tester.pump(const Duration(minutes: 2));
      navigator.pop();
      await tester.pumpAndSettle();
      expect(clock.isRunning, true);
      clock.advance(4);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(clock.isRunning, false);
      clock.advance(60);
      await tester.pump(const Duration(minutes: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      clock.advance(3);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(store.activityOn(DateTime.now()).activeMs, 15000);
      expect(store.progress('logic')!['seconds'], 15);
    },
  );

  testWidgets(
    'profile shows exact short durations instead of less-than-one-minute',
    (tester) async {
      await store.saveProgress('logic', {
        'activeMsByDay': {activityDay(DateTime.now()): 12000},
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: ProfilePage(store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('12 giây'), findsOneWidget);
      expect(find.text('<1 phút'), findsNothing);
      await store.saveProgress('logic', {
        'activeMsByDay': {activityDay(DateTime.now()): 62000},
      });
      await tester.pumpAndSettle();
      expect(find.text('1 phút 2 giây'), findsOneWidget);
    },
  );
}
