import '../../learning_catalog.dart';
import '../models/learning_modules.dart';

/// References the existing catalog; never duplicates or republishes its content.
List<CourseRoadmap> catalogRoadmaps() {
  final domains = <CourseDomain, Set<String>>{
    CourseDomain.math: {'math', 'geometry', 'probability', 'algebra'},
    CourseDomain.computerScienceAndAi: {'logic', 'coding', 'optimization'},
    CourseDomain.generalScience: {'science', 'circuits', 'geography'},
    CourseDomain.dataAnalysis: {'data'},
    CourseDomain.artsAndHumanities: {'painting', 'marxism'},
  };
  return [
    for (final domain in domains.entries)
      CourseRoadmap(
        id: domain.key.name,
        domain: domain.key,
        nodes: topics
            .where((topic) => domain.value.contains(topic.id))
            .map((topic) => CourseNode(topic.id))
            .toList(),
      ),
  ];
}
