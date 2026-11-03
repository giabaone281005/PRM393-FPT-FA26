import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/experiments/activity_catalog.dart';
import 'package:brilliant_mobile/experiments/curriculum_engine.dart';

/// Export immutable scene data; Dart validators are not backend evaluators.
void main() {
  final source = File('lib/learning_catalog.dart').readAsStringSync();
  final pattern = RegExp(
    r"LearningTopic\(\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*Icons\.([\w]+),\s*BrilliantPalette\.successSurface,\s*'([^']*)',",
  );
  final topics = pattern
      .allMatches(source)
      .map(
        (m) => {
          'id': m[1],
          'title': m[2],
          'subtitle': m[3],
          'subject': m[4],
          'icon_key': m[5],
          'action_label': m[6],
        },
      )
      .toList();
  if (topics.length != 20) throw StateError('Unexpected topic metadata');
  final activities = [
    for (final topic in topics)
      for (final entry in experimentCatalog[topic['id']]!.indexed)
        {
          'id': entry.$2.id,
          'topic_id': topic['id'],
          'position': entry.$1,
          'content_version': entry.$2.contentVersion,
          'title': entry.$2.title,
          'stage': entry.$2.stage,
          'prompt': entry.$2.prompt,
          'hint_levels': [entry.$2.hint],
          'explanation': entry.$2.explanation,
          'mechanism': entry.$2.mechanism,
          'mechanism_version': entry.$2.mechanismVersion,
          'evaluator_version':
              entry.$2.contentVersion > 1 ||
                  entry.$2.mechanism == 'reasonedChoice' ||
                  supportsCurriculum(entry.$2.mechanism)
              ? 2
              : 1,
          'config': entry.$2.config,
          'initial_state': entry.$2.initialData(),
          'skill_ids': entry.$2.skillIds,
        },
  ];
  if (activities.length != 139 ||
      activities.map((a) => a['id']).toSet().length != 139) {
    throw StateError('Unexpected activity catalog');
  }
  final output = File('supabase/catalog.json');
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'topics': topics,
      'activities': activities,
      'verification': 'requires_evaluator_parity_and_release',
    }),
  );
  stdout.writeln(
    'Exported ${topics.length} topics / ${activities.length} activities.',
  );
}
