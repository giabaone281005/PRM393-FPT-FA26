import 'app_layout.dart';

import 'dart:async';

import 'topic_illustration.dart';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'app_preferences.dart';
import 'home_chat_box.dart';
import 'settings_menu.dart';
import 'learning_guidance.dart';
import 'learning_activity.dart';
import 'app_motion.dart';
import 'discovery_paths.dart';
import 'experiments/contextual_guidance.dart';
import 'entry_flow.dart';
import 'learning_store.dart';
import 'learning_catalog.dart';
import 'experiments/experiment_model.dart';
import 'experiments/diverse_workspace.dart';
import 'experiments/space_workspace.dart';
import 'experiments/space_guidance.dart';
import 'experiments/lesson_guidance.dart';
import 'experiments/math_experiments.dart';
import 'experiments/discovery_experiments.dart';

class LearnApp extends StatefulWidget {
  const LearnApp({super.key, required this.store, this.chatResponder});
  final LearningStore store;
  final ChatResponder? chatResponder;
  @override
  State<LearnApp> createState() => _LearnAppState();
}

class _LearnAppState extends State<LearnApp> with WidgetsBindingObserver {
  late final AppPreferences appearance = AppPreferences(
    widget.store.preferences,
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(widget.store.flush());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appearance,
    builder: (context, _) => AppearanceScope(
      preferences: appearance,
      child: MaterialApp(
        title: 'Matlingo • Học bằng khám phá',
        debugShowCheckedModeBanner: false,
        theme: appearance.theme,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                media.textScaler.scale(14) / 14 * appearance.textSize,
              ),
              disableAnimations:
                  media.disableAnimations || appearance.reduceMotion,
            ),
            child: child!,
          );
        },
        home: ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) {
            if (!widget.store.hasSession) {
              return MotionEntrance(
                replayKey: 'entry',
                child: EntryPage(store: widget.store),
              );
            }
            if (!widget.store.profile!.onboarded) {
              return MotionEntrance(
                replayKey: 'onboarding',
                child: OnboardingPage(store: widget.store),
              );
            }
            return MotionEntrance(
              replayKey: widget.store.profile!.id,
              child: HomeShell(
                key: ValueKey(widget.store.profile!.id),
                store: widget.store,
                chatResponder: widget.chatResponder,
              ),
            );
          },
        ),
      ),
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store, this.chatResponder});
  final LearningStore store;
  final ChatResponder? chatResponder;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageHeader(
      showBack: false,
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Matlingo',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 25),
            ),
            SizedBox(width: 4),
            Icon(Icons.auto_awesome, size: 18),
          ],
        ),
      ),
      trailing: SettingsMenuButton(store: widget.store),
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          if (widget.store.saveError != null)
            MaterialBanner(
              content: Text(widget.store.saveError!),
              actions: [
                TextButton(
                  onPressed: () => widget.store.flush(),
                  child: const Text('Thử lưu lại'),
                ),
              ],
            ),
          Expanded(
            child: MotionEntrance(
              replayKey: tab,
              child: IndexedStack(
                index: tab,
                children: [
                  TodayPage(
                    store: widget.store,
                    chatResponder: widget.chatResponder,
                    onExplore: () => setState(() => tab = 1),
                  ),
                  ExplorePage(store: widget.store),
                  ProfilePage(store: widget.store, embedded: true),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
          child: NavigationBar(
            height: 72,
            selectedIndex: tab,
            onDestinationSelected: (v) => setState(() => tab = v),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Chủ đề',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Hồ sơ',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void openTopic(
  BuildContext context,
  LearningTopic topic,
  LearningStore store,
) => Navigator.push(
  context,
  DiscoveryRoute<void>(
    builder: (_) => TopicPage(topic: topic, store: store),
  ),
);
void openLesson(
  BuildContext context,
  LearningTopic topic,
  LearningStore store,
) => Navigator.push(
  context,
  DiscoveryRoute<void>(
    builder: (_) => LessonPage(topic: topic, store: store),
  ),
);

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.store,
    required this.onExplore,
    this.chatResponder,
  });
  final LearningStore store;
  final VoidCallback onExplore;
  final ChatResponder? chatResponder;
  @override
  Widget build(BuildContext context) {
    final draftIds = store.inProgress
        .where((id) => topics.any((t) => t.id == id))
        .toList();
    final resume = draftIds.isEmpty ? null : recommendNext(store).topic;
    final step = resume == null
        ? 0
        : ((store.progress(resume.id)?['step'] as num?)?.toInt() ?? 0).clamp(
            0,
            resume.experiments.length - 1,
          );
    final checked =
        (resume == null ? null : store.progress(resume.id)?['checked'])
            as List? ??
        [];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
        child: ListView(
          key: const ValueKey('home-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: AppLayout.pagePadding,
          children: [
            Text(
              'Chào ${store.profile?.name ?? 'bạn'},',
              style: const TextStyle(color: BrilliantPalette.secondaryText),
            ),
            const SizedBox(height: 8),
            Text(
              resume == null
                  ? 'Một điều mới\nđang chờ bạn.'
                  : 'Tiếp nối\nsự tò mò.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            if (resume != null) ...[
              TopicArtwork(topic: resume, height: 144),
              const SizedBox(height: 14),
              Text(
                resume.title,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Bước ${step + 1} / ${resume.experiments.length}',
                textAlign: TextAlign.left,
                style: const TextStyle(color: BrilliantPalette.secondaryText),
              ),
              const SizedBox(height: 24),
              Text(
                resume.experiments[step].title,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value:
                    checked
                        .where(
                          (id) =>
                              resume.experiments.any((spec) => spec.id == id),
                        )
                        .toSet()
                        .length /
                    resume.experiments.length,
                minHeight: 5,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 24),
              PrimaryAction(
                expand: true,
                onPressed: () => openLesson(context, resume, store),
                child: const Text('Học tiếp'),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: onExplore, child: const Text('Đổi chủ đề')),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 164,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TopicArtwork(
                        topic: topicById('geometry'),
                        height: 132,
                      ),
                    ),
                    Expanded(
                      child: TopicArtwork(
                        topic: topicById('probability'),
                        height: 164,
                      ),
                    ),
                    Expanded(
                      child: TopicArtwork(
                        topic: topicById('coding'),
                        height: 132,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                store.completed.isEmpty
                    ? 'Chọn một chủ đề bạn thích.\nBắt đầu bằng một thí nghiệm nhỏ.'
                    : 'Bạn đã hoàn thành ${store.completed.length} chủ đề.\nChọn điều tiếp theo muốn khám phá.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.6,
                  color: BrilliantPalette.secondaryText,
                ),
              ),
              const SizedBox(height: 28),
              PrimaryAction(
                expand: true,
                key: const ValueKey('home-start'),
                onPressed: onExplore,
                child: const Text('Chọn chủ đề'),
              ),
            ],
            const SizedBox(height: 28),
            HomeChatBox(onSend: chatResponder),
          ],
        ),
      ),
    );
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key, required this.store});
  final LearningStore store;
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String query = '', filter = 'all';
  bool matches(LearningTopic t) =>
      '${t.title} ${t.subtitle} ${t.subject}'.toLowerCase().contains(
        query.toLowerCase(),
      ) &&
      (filter == 'all' ||
          filter == 'completed' && widget.store.completed.contains(t.id) ||
          filter == 'saved' && widget.store.progress(t.id) != null);
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
      child: ListView(
        key: const ValueKey('topics-scroll'),
        padding: AppLayout.pagePadding,
        children: [
          Text(
            'Chủ đề của bạn',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.store.completed.length}/${topics.length} hoàn thành • ${widget.store.points} XP',
            style: const TextStyle(color: BrilliantPalette.secondaryText),
          ),
          const SizedBox(height: 24),
          TextField(
            key: const ValueKey('topic-search'),
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              hintText: 'Tìm chủ đề…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in {
                'all': 'Tất cả',
                'saved': 'Đang học',
                'completed': 'Đã hoàn thành',
              }.entries)
                FilterChip(
                  key: ValueKey('topic-filter-${e.key}'),
                  label: Text(e.value),
                  selected: filter == e.key,
                  onSelected: (_) => setState(() => filter = e.key),
                ),
            ],
          ),
          const SizedBox(height: 26),
          if (!topics.any(matches))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Chưa có chủ đề phù hợp. Thử bộ lọc khác nhé.'),
            ),
          for (final group in discoveryPaths)
            if (group.topicIds.map(topicById).any(matches))
              _group(context, group),
          const SizedBox(height: 12),
          _achievements(context),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );

  Widget _group(BuildContext context, DiscoveryPath group) {
    final visible = group.topicIds.map(topicById).where(matches).toList();
    final completed = group.topicIds
        .where(widget.store.completed.contains)
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 58,
                height: 64,
                child: TopicArtwork(
                  topic: topicById(group.topicIds.first),
                  height: 64,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: Theme.of(context).textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: BrilliantPalette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label:
                    '$completed trên ${group.topicIds.length} chủ đề hoàn thành',
                child: Icon(
                  completed == group.topicIds.length
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: completed > 0
                      ? const Color(0xFFE4AE25)
                      : BrilliantPalette.border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: .035),
              borderRadius: BorderRadius.circular(AppLayout.cardRadius),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minimumWidth =
                    MediaQuery.textScalerOf(context).scale(1) > 1.2
                    ? 165.0
                    : 120.0;
                final columns =
                    ((constraints.maxWidth + 14) / (minimumWidth + 14))
                        .floor()
                        .clamp(1, 4);
                final width =
                    (constraints.maxWidth - 14 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 22,
                  children: [
                    for (final topic in visible)
                      SizedBox(width: width, child: _course(context, topic)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _course(BuildContext context, LearningTopic topic) {
    final done = widget.store.completed.contains(topic.id);
    final draft = widget.store.progress(topic.id);
    final checked = (draft?['checked'] as List? ?? [])
        .where((v) => topic.experiments.any((s) => s.id == v))
        .toSet()
        .length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('topic-${topic.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => openTopic(context, topic, widget.store),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 146,
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: done
                      ? Theme.of(context).colorScheme.primary
                      : BrilliantPalette.border,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), offset: Offset(0, 3)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 12, 5, 22),
                      child: TopicArtwork(topic: topic, height: 110),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      done ? Icons.verified_rounded : Icons.circle_outlined,
                      size: 17,
                      color: done
                          ? const Color(0xFFD9A512)
                          : BrilliantPalette.track,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: LinearProgressIndicator(
                      value: done ? 1 : checked / topic.experiments.length,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              topic.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              done
                  ? (topic.experiments.every(
                          (s) => widget.store
                              .completedExperimentIds(topic.id)
                              .contains(s.id),
                        )
                        ? 'Hoàn thành • 30 XP'
                        : 'Có bài mới • đã nhận 30 XP')
                  : draft != null
                  ? 'Đang học • $checked/${topic.experiments.length}'
                  : '${topic.experiments.length} thí nghiệm',
              style: TextStyle(
                fontSize: 11,
                color: done
                    ? BrilliantPalette.successInk
                    : BrilliantPalette.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _achievements(BuildContext context) => ExpansionTile(
    key: const ValueKey('topic-achievements'),
    tilePadding: EdgeInsets.zero,
    leading: const Icon(Icons.emoji_events_outlined),
    title: const Text('Thành tựu & lịch sử'),
    subtitle: Text(
      '${widget.store.completed.length} chủ đề • ${widget.store.history.length} phiên hoàn thành',
    ),
    children: [
      if (widget.store.completed.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Hoàn thành một chủ đề để nhận thành tựu đầu tiên.'),
        ),
      for (final id in widget.store.completed)
        ListTile(
          leading: const Icon(Icons.verified_rounded, color: Color(0xFFE4AE25)),
          title: Text(topicById(id).title),
          trailing: const Text('30 XP'),
          onTap: () => openTopic(context, topicById(id), widget.store),
        ),
      if (widget.store.history.isNotEmpty) ...[
        const Divider(),
        for (final record in widget.store.history)
          ListTile(
            key: ValueKey('history-${record['id'] ?? record['finishedAt']}'),
            leading: const Icon(Icons.history),
            title: Text(topicById(record['course'] as String).title),
            subtitle: Text(
              '${_date(record['finishedAt'])} • ${record['attempts']} lần thử • ${record['hints']} gợi ý',
            ),
            trailing: Text(record['xp'] == 0 ? 'Ôn tập' : '+30 XP'),
            onTap: () => openTopic(
              context,
              topicById(record['course'] as String),
              widget.store,
            ),
          ),
      ],
    ],
  );
  String _date(dynamic value) {
    final date = DateTime.tryParse(value is String ? value : '')?.toLocal();
    return date == null ? 'Đã lưu' : '${date.day}/${date.month}/${date.year}';
  }
}

class TopicPage extends StatelessWidget {
  const TopicPage({super.key, required this.topic, required this.store});
  final LearningTopic topic;
  final LearningStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageHeader(title: Text(topic.subject)),
    body: AppPageBody(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppLayout.panel(context),
            borderRadius: BorderRadius.circular(AppLayout.cardRadius),
          ),
          child: TopicArtwork(topic: topic, height: 170),
        ),
        const SizedBox(height: 24),
        Text(topic.title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(topic.subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        const Text(
          'BẠN SẼ TỰ TAY…',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < topic.experiments.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: i == 0 ? topic.color : BrilliantPalette.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${topic.experiments[i].stage} · ${topic.experiments[i].title}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.gesture,
                  size: 20,
                  color: BrilliantPalette.secondaryText,
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        PrimaryAction(
          expand: true,
          onPressed: () => openLesson(context, topic, store),
          child: Text(
            store.progress(topic.id) != null
                ? 'Tiếp tục phiên học'
                : store.completed.contains(topic.id)
                ? (topic.experiments.every(
                        (s) => store
                            .completedExperimentIds(topic.id)
                            .contains(s.id),
                      )
                      ? 'Khám phá lại'
                      : 'Khám phá bài mới')
                : 'Vào phòng thí nghiệm',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Chạm, thử, thay đổi. Ý tưởng xuất hiện trong lúc bạn làm.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: BrilliantPalette.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

class LessonPage extends StatefulWidget {
  const LessonPage({super.key, required this.topic, required this.store});
  final LearningTopic topic;
  final LearningStore store;
  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> with WidgetsBindingObserver {
  late Map<String, dynamic> draft;
  late final String ownerId;
  int revision = 0;
  bool finishing = false;
  bool hintVisible = false;
  String? error;
  final clock = Stopwatch();
  final scroll = ScrollController();
  Timer? autosave;
  int get step =>
      (draft['step'] as int).clamp(0, widget.topic.experiments.length - 1);
  ExperimentSpec get spec => widget.topic.experiments[step];
  Map<String, dynamic> get states =>
      Map<String, dynamic>.from(draft['states'] as Map);
  ExperimentData get data => {
    ...spec.initialData(),
    ...Map<String, dynamic>.from(states[spec.id] as Map? ?? {}),
  };
  List<String> list(String key) => List<String>.from(draft[key] as List? ?? []);
  bool get touched => list('touched').contains(spec.id);
  bool get checked => list('checked').contains(spec.id);
  bool get correct => checked && touched && spec.isCorrect(data);
  int get hintLevel {
    final levels = draft['hintLevels'];
    return savedHintLevel(
      levels is Map ? levels[spec.id] : null,
      previouslyUsed: list('hints').contains(spec.id),
    );
  }

  void revealHintLevel(int level) {
    final previous = draft['hintLevels'];
    draft['hintLevels'] = {
      if (previous is Map) ...previous,
      spec.id: level.clamp(1, 3),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ownerId = widget.store.profile?.id ?? '';
    final saved = widget.store.progress(widget.topic.id);
    draft = {
      'version': 3,
      'step': 0,
      'states': <String, dynamic>{},
      'touched': <String>[],
      'checked': <String>[],
      'hints': <String>[],
      'attempts': 0,
      'seconds': 0,
      'startedAt': DateTime.now().toUtc().toIso8601String(),
      if (saved?['version'] == 3) ...saved!,
    };
    final credited = widget.store.completedExperimentIds(widget.topic.id);
    final firstNew = widget.topic.experiments.indexWhere(
      (s) => !credited.contains(s.id),
    );
    if (saved == null && credited.isNotEmpty && firstNew > 0) {
      draft['step'] = firstNew;
      draft['checked'] = credited.toList();
    }
    draft['step'] = ((draft['step'] as num?)?.toInt() ?? 0).clamp(
      0,
      widget.topic.experiments.length - 1,
    );
    draft['elapsedMs'] ??= ((draft['seconds'] as num?)?.toInt() ?? 0) * 1000;
    clock.start();
    autosave = Timer.periodic(const Duration(seconds: 15), (_) => persist());
    // Persist an opened lesson too, so a zero-action session can be resumed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) persist();
    });
  }

  void _accountTime() {
    final milliseconds = clock.elapsedMilliseconds;
    final daily = Map<String, dynamic>.from(
      draft['activeMsByDay'] as Map? ?? {},
    );
    addActiveTime(daily, DateTime.now(), milliseconds);
    draft['activeMsByDay'] = daily;
    draft['elapsedMs'] =
        ((draft['elapsedMs'] as num?)?.toInt() ?? 0) + milliseconds;
    draft['seconds'] = (draft['elapsedMs'] as int) ~/ 1000;
    clock.reset();
  }

  Future<void> persist() async {
    if (finishing || widget.store.profile?.id != ownerId || ownerId.isEmpty) {
      return;
    }
    _accountTime();
    await widget.store.saveProgress(widget.topic.id, draft);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      clock.start();
    } else {
      clock.stop();
      unawaited(persist());
    }
  }

  @override
  void dispose() {
    autosave?.cancel();
    clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    // Route disposal locks the element tree. Save after unmount completes so
    // store listeners can rebuild the remaining screens safely.
    unawaited(Future<void>.microtask(persist));
    scroll.dispose();
    super.dispose();
  }

  void edit(ExperimentData next) {
    if (finishing || correct) return;
    setState(() {
      draft['states'] = {...states, spec.id: next};
      draft['touched'] = {...list('touched'), spec.id}.toList();
      draft['checked'] = list('checked')..remove(spec.id);
      error = null;
    });
    unawaited(persist());
  }

  void reset() {
    setState(() {
      draft['states'] = {...states, spec.id: spec.initialData()};
      draft['touched'] = list('touched')..remove(spec.id);
      draft['checked'] = list('checked')..remove(spec.id);
      hintVisible = false;
      error = null;
      revision++;
    });
    unawaited(persist());
  }

  void check() {
    setState(() {
      draft['attempts'] = (draft['attempts'] as int? ?? 0) + 1;
      draft['checked'] = {...list('checked'), spec.id}.toList();
    });
    unawaited(persist());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) {
        unawaited(
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  Future<void> next() async {
    if (!correct) return;
    if (widget.store.profile?.id != ownerId) {
      setState(
        () => error = 'Phiên học thuộc hồ sơ khác. Mở lại hồ sơ để tiếp tục.',
      );
      return;
    }
    if (step < widget.topic.experiments.length - 1) {
      setState(() {
        draft['step'] = step + 1;
        hintVisible = false;
        error = null;
        revision++;
      });
      await persist();
      if (mounted && scroll.hasClients) scroll.jumpTo(0);
    } else {
      _accountTime();
      setState(() => finishing = true);
      clock.stop();
      try {
        final receipt = await widget.store.finish(
          widget.topic.id,
          experiments: widget.topic.experiments,
          draft: draft,
          expectedProfileId: ownerId,
        );
        if (!mounted) return;
        if (widget.store.profile?.id != ownerId) {
          Navigator.popUntil(context, (route) => route.isFirst);
          return;
        }
        await Navigator.pushReplacement(
          context,
          DiscoveryRoute<void>(
            builder: (_) => CompletionPage(
              topic: widget.topic,
              store: widget.store,
              record: receipt.record,
              awarded: receipt.awarded,
            ),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        setState(() {
          finishing = false;
          error = 'Chưa thể hoàn thành. Kiểm tra lại các bước và thử lưu lại.';
        });
        clock.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AppContentFrame(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Lưu và thoát',
                    onPressed: finishing
                        ? null
                        : () async {
                            await persist();
                            if (context.mounted) Navigator.pop(context);
                          },
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LessonProgress(
                      step: step,
                      total: widget.topic.experiments.length,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${step + 1}/${widget.topic.experiments.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MotionEntrance(
                replayKey: spec.id,
                child: ListView(
                  key: ValueKey('lesson-scroll-$step'),
                  controller: scroll,
                  padding: AppLayout.pagePadding,
                  children: [
                    Text(
                      spec.stage.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      spec.title,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      spec.prompt,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: paper,
                        borderRadius: BorderRadius.circular(
                          AppLayout.cardRadius,
                        ),
                        border: Border.all(color: BrilliantPalette.track),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: RepaintBoundary(
                        child: ExperimentWorkspace(
                          key: ValueKey('${spec.id}:$revision'),
                          spec: spec,
                          data: data,
                          locked: correct || finishing,
                          onChanged: edit,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              hintVisible = !hintVisible;
                              if (hintVisible) {
                                revealHintLevel(hintLevel.clamp(1, 3));
                                draft['hints'] = {
                                  ...list('hints'),
                                  spec.id,
                                }.toList();
                              }
                            });
                            unawaited(persist());
                          },
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: Text(hintVisible ? 'Ẩn gợi ý' : 'Gợi ý nhỏ'),
                        ),
                        TextButton.icon(
                          key: const ValueKey('reset-experiment'),
                          onPressed: finishing ? null : reset,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Làm lại'),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: AppMotion.duration(context, 240),
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.topCenter,
                      child: hintVisible
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: BrilliantPalette.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supportsProgressiveGuidance(spec)
                                        ? progressiveLessonHint(
                                            spec,
                                            data,
                                            hintLevel,
                                          )
                                        : contextualHint(spec, data),
                                    style: const TextStyle(height: 1.5),
                                  ),
                                  if (supportsProgressiveGuidance(spec)) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Mức gợi ý ${hintLevel.clamp(1, 3)}/3',
                                    ),
                                    if (hintLevel < 3)
                                      TextButton(
                                        key: const ValueKey('reveal-next-hint'),
                                        onPressed: finishing
                                            ? null
                                            : () {
                                                setState(
                                                  () => revealHintLevel(
                                                    hintLevel + 1,
                                                  ),
                                                );
                                                unawaited(persist());
                                              },
                                        child: const Text('Gợi ý rõ hơn'),
                                      ),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    if (checked) ...[
                      const SizedBox(height: 12),
                      Container(
                        key: const ValueKey('lesson-feedback'),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: correct
                              ? BrilliantPalette.successSurface
                              : BrilliantPalette.errorSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  correct
                                      ? Icons.check_circle_outline
                                      : Icons.autorenew,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    correct
                                        ? 'Bạn đã tìm ra!'
                                        : 'Thử thêm một cách nhé',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              correct
                                  ? spec.explanation
                                  : supportsProgressiveGuidance(spec)
                                  ? lessonModelFeedback(spec, data)
                                  : contextualHint(spec, data),
                              style: const TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) => widget.store.saveError == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppLayout.gutter,
                      ),
                      child: TextButton(
                        onPressed: persist,
                        child: Text(widget.store.saveError!),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: PrimaryAction(
                expand: true,
                onPressed: finishing
                    ? null
                    : correct
                    ? next
                    : touched
                    ? check
                    : null,
                child: Text(
                  finishing
                      ? 'Đang lưu…'
                      : correct
                      ? (step == widget.topic.experiments.length - 1
                            ? 'Hoàn thành hành trình'
                            : 'Khám phá tiếp')
                      : checked
                      ? 'Kiểm tra lại'
                      : 'Kiểm tra',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ExperimentWorkspace extends StatelessWidget {
  const ExperimentWorkspace({
    super.key,
    required this.spec,
    required this.data,
    required this.locked,
    required this.onChanged,
  });
  final ExperimentSpec spec;
  final ExperimentData data;
  final bool locked;
  final ValueChanged<ExperimentData> onChanged;
  @override
  Widget build(BuildContext context) {
    if (supportsMathExperiment(spec.mechanism)) {
      return MathExperiment(
        spec: spec,
        data: data,
        locked: locked,
        onChanged: onChanged,
      );
    }
    if (supportsDiscoveryExperiment(spec.mechanism)) {
      return DiscoveryExperiment(
        spec: spec,
        data: data,
        locked: locked,
        onChanged: onChanged,
      );
    }
    if (supportsDiverseExperiment(spec.mechanism)) {
      return DiverseWorkspace(
        spec: spec,
        data: data,
        locked: locked,
        onChanged: onChanged,
      );
    }
    if (supportsSpaceExperiment(spec.mechanism)) {
      return SpaceWorkspace(
        spec: spec,
        data: data,
        locked: locked,
        onChanged: onChanged,
      );
    }
    return const Text('Thí nghiệm đang được chuẩn bị.');
  }
}

class CompletionPage extends StatelessWidget {
  const CompletionPage({
    super.key,
    required this.topic,
    required this.store,
    required this.record,
    required this.awarded,
  });
  final LearningTopic topic;
  final LearningStore store;
  final Map<String, dynamic> record;
  final bool awarded;
  @override
  Widget build(BuildContext context) {
    final next = topics.firstWhere(
      (t) => t.id != topic.id && !store.completed.contains(t.id),
      orElse: () => topics.firstWhere((t) => t.id != topic.id),
    );
    return Scaffold(
      appBar: const AppPageHeader(title: Text('Hoàn thành')),
      body: SafeArea(
        child: AppPageBody(
          children: [
            Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: BrilliantPalette.successSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 56,
                  color: BrilliantPalette.successInk,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Bạn vừa làm được\nmột điều mới.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Text(
              topic.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.bolt, size: 18),
                  label: Text(awarded ? '+30 XP' : 'Đã ôn tập'),
                ),
                Chip(label: Text('${topic.experiments.length} phát hiện mới')),
                Chip(label: Text('${record['attempts']} lần kiểm tra')),
              ],
            ),
            const SizedBox(height: 20),
            for (final spec in topic.experiments)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: BrilliantPalette.successInk,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        spec.title,
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            const Text(
              'Kết quả đã được lưu trong Chủ đề của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BrilliantPalette.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            PrimaryAction(
              expand: true,
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                openTopic(context, next, store);
              },
              child: const Text('Thử một chủ đề khác'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.store, this.embedded = false});
  final LearningStore store;
  final bool embedded;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  DateTime selected = DateTime.now();
  String _time(DailyLearningActivity activity) {
    final ms = activity.activeMs;
    if (ms == null) return activity.sessions == 0 ? '0 phút' : '—';
    if (ms > 0 && ms < 60000) return '<1 phút';
    return '${ms ~/ 60000} phút';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded ? null : const AppPageHeader(title: Text('Hồ sơ')),
    body: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final days = List.generate(
          7,
          (i) => DateTime(today.year, today.month, today.day - 6 + i),
        );
        final activity = widget.store.activityOn(selected);
        final activeDays = days
            .where((d) => widget.store.activityOn(d).hasActivity)
            .length;
        final color = Theme.of(context).colorScheme.primary;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
            child: ListView(
              key: const ValueKey('profile-summary'),
              padding: AppLayout.pagePadding,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: color.withValues(alpha: .1),
                      child: Text(
                        (widget.store.profile?.name ?? '?').characters.first,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.store.profile?.name ?? '',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.store.profile?.dailyMinutes ?? 10} phút mỗi ngày',
                            style: const TextStyle(
                              color: BrilliantPalette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  activityDay(selected) == activityDay(now)
                      ? 'Hôm nay'
                      : 'Ngày ${selected.day}/${selected.month}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final entry in {
                        _time(activity): 'Thời gian học',
                        '${activity.sessions} phiên': 'Hoàn thành',
                      }.entries)
                        SizedBox(
                          width:
                              constraints.maxWidth < 270 ||
                                  MediaQuery.textScalerOf(context).scale(1) >
                                      1.3
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 12) / 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: BrilliantPalette.track),
                              borderRadius: BorderRadius.circular(
                                AppLayout.tileRadius,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: BrilliantPalette.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .04),
                    borderRadius: BorderRadius.circular(AppLayout.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '7 ngày gần đây',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeDays ngày có học',
                        style: const TextStyle(
                          fontSize: 12,
                          color: BrilliantPalette.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final day in days)
                            Expanded(child: _day(context, day, color)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!activity.hasActivity) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Một thí nghiệm nhỏ cũng là một khởi đầu.',
                    style: TextStyle(
                      fontSize: 13,
                      color: BrilliantPalette.secondaryText,
                    ),
                  ),
                ],
                if (activity.activeMs == null && activity.sessions > 0) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Phiên cũ chưa có thời gian theo ngày.',
                    style: TextStyle(
                      fontSize: 12,
                      color: BrilliantPalette.secondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () async {
                    await widget.store.flush();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.store.saveError ?? 'Đã lưu phiên học.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Lưu ngay'),
                ),
                TextButton(
                  onPressed: () async {
                    await widget.store.signOut();
                    if (context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                  child: const Text('Đóng phiên & đổi hồ sơ'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  Widget _day(BuildContext context, DateTime day, Color color) {
    final data = widget.store.activityOn(day);
    final chosen = activityDay(day) == activityDay(selected);
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Semantics(
      selected: chosen,
      button: true,
      label: 'Ngày ${day.day}/${day.month}, ${data.sessions} phiên hoàn thành',
      child: InkWell(
        key: ValueKey('activity-${activityDay(day)}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => selected = day),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(
                data.hasActivity
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 22,
                color: data.hasActivity ? color : BrilliantPalette.border,
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  names[day.weekday - 1],
                  style: TextStyle(
                    fontSize: 11,
                    color: BrilliantPalette.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: chosen ? color : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 11,
                    color: chosen
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopicArtwork extends StatelessWidget {
  const TopicArtwork({super.key, required this.topic, required this.height});
  final LearningTopic topic;
  final double height;
  @override
  Widget build(BuildContext context) => TopicIllustration(
    topicId: topic.id,
    label: 'Minh họa ${topic.subject}',
    height: height,
  );
}
