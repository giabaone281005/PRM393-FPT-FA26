/// Stable curriculum identities are independent of completion and XP.
class SkillSpec {
  const SkillSpec(this.id, this.title, {this.prerequisiteIds = const []});
  final String id, title;
  final List<String> prerequisiteIds;
}

class ChapterSpec {
  const ChapterSpec(this.id, this.topicId, this.title, this.lessonIds);
  final String id, topicId, title;
  final List<String> lessonIds;
}

class LessonSpec {
  const LessonSpec(
    this.id,
    this.chapterId,
    this.title,
    this.objective,
    this.activities, {
    this.contentVersion = 1,
  });
  final String id, chapterId, title, objective;
  final int contentVersion;
  final List<ActivitySpec> activities;
}

class ActivitySpec {
  const ActivitySpec(
    this.experimentId,
    this.skillIds, {
    this.checkpoint = false,
  });
  final String experimentId;
  final List<String> skillIds;
  final bool checkpoint;
}

const fractionSkills = [
  SkillSpec('fractions.equal-parts', 'Nhận biết các phần bằng nhau'),
  SkillSpec(
    'fractions.part-whole',
    'Biểu diễn phần của toàn thể',
    prerequisiteIds: ['fractions.equal-parts'],
  ),
];

const fractionChapter = ChapterSpec(
  'math.equal-parts',
  'math',
  'Từ phần đến toàn thể',
  ['math.fraction-foundations'],
);

const fractionLesson = LessonSpec(
  'math.fraction-foundations',
  'math.equal-parts',
  'Phân số bằng đôi tay',
  'Tô một phần của chiếc bánh và tạo các phần bằng nhau bằng cách gấp, chia.',
  [
    ActivitySpec('math-paint', ['fractions.part-whole']),
    ActivitySpec('math-fold', ['fractions.equal-parts']),
    ActivitySpec('math-share', ['fractions.equal-parts']),
  ],
);
