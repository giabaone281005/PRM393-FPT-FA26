import 'package:flutter/material.dart';

const lessonIcons = <String, IconData>{
  'book': Icons.menu_book_rounded,
  'calculator': Icons.calculate_outlined,
  'coins': Icons.savings_outlined,
  'shapes': Icons.category_outlined,
  'cube': Icons.view_in_ar_outlined,
  'chart': Icons.bar_chart_rounded,
  'fraction': Icons.pie_chart_outline,
  'ruler': Icons.straighten,
  'compass': Icons.architecture,
  'puzzle': Icons.extension_outlined,
  'headphones': Icons.headphones_outlined,
  'microphone': Icons.mic_none,
  'alphabet': Icons.translate,
  'pen': Icons.edit_outlined,
  'globe': Icons.public,
  'chat': Icons.chat_bubble_outline,
  'robot': Icons.smart_toy_outlined,
  'code': Icons.code,
  'loop': Icons.repeat,
  'route': Icons.route_outlined,
  'terminal': Icons.terminal,
  'bug': Icons.bug_report_outlined,
  'lightbulb': Icons.lightbulb_outline,
  'trophy': Icons.emoji_events_outlined,
};
const _engineIcons = <String, String>{
  'resourceBudget': 'coins',
  'numberLine': 'calculator',
  'numberInput': 'calculator',
  'fractionBoard': 'fraction',
  'fractionCompare': 'fraction',
  'polygonVertices': 'shapes',
  'shapeMatch': 'shapes',
  'symmetryMirror': 'shapes',
  'solid3D': 'cube',
  'graph': 'chart',
  'quadraticGraph': 'chart',
  'barChart': 'chart',
  'listeningChoice': 'headphones',
  'speechPractice': 'microphone',
  'textEntry': 'pen',
  'clozeBank': 'alphabet',
  'robotRoute': 'robot',
  'loopBuilder': 'loop',
  'categorySort': 'code',
  'vennDiagram': 'code',
};
String lessonIconKey(Map config) {
  final key = config['lesson_icon'];
  if (key is String && lessonIcons.containsKey(key)) return key;
  final slides = config['slides'];
  if (slides is List) {
    for (final slide in slides) {
      if (slide is Map && slide['engine'] != 'story') {
        return _engineIcons[slide['engine']] ?? 'book';
      }
    }
  }
  return 'book';
}

IconData lessonIcon(Map config) => lessonIcons[lessonIconKey(config)]!;
