import 'dart:convert';

import 'package:flutter/material.dart';

import '../../learning_catalog.dart';

const _topicIcons = <String, IconData>{
  'balance': Icons.balance,
  'casino_outlined': Icons.casino_outlined,
  'change_history': Icons.change_history,
  'chat_bubble_outline': Icons.chat_bubble_outline,
  'eco_outlined': Icons.eco_outlined,
  'hub_outlined': Icons.hub_outlined,
  'lightbulb_outline': Icons.lightbulb_outline,
  'menu_book_outlined': Icons.menu_book_outlined,
  'nightlight_round': Icons.nightlight_round,
  'palette_outlined': Icons.palette_outlined,
  'pie_chart_outline': Icons.pie_chart_outline,
  'public': Icons.public,
  'record_voice_over_outlined': Icons.record_voice_over_outlined,
  'rocket_launch_outlined': Icons.rocket_launch_outlined,
  'route_outlined': Icons.route_outlined,
  'savings_outlined': Icons.savings_outlined,
  'science_outlined': Icons.science_outlined,
  'stacked_bar_chart': Icons.stacked_bar_chart,
  'terminal': Icons.terminal,
  'verified_user_outlined': Icons.verified_user_outlined,
};

String _canonical(dynamic value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return jsonEncode({for (final key in keys) key: _canonical(value[key])});
  }
  if (value is List) return jsonEncode(value.map(_canonical).toList());
  // PostgreSQL JSONB may serialize 1.0 as 1; these are the same scene value.
  if (value is double && value.isFinite && value == value.toInt()) {
    return jsonEncode(value.toInt());
  }
  return jsonEncode(value);
}

/// JSONB and Dart scene numbers may differ in integer/double representation.
bool equivalentCatalogValue(dynamic first, dynamic second) =>
    _canonical(first) == _canonical(second);

/// Only published scenes supported by this app may enter its discovery catalog.
/// Metadata and visibility come from the server; validators stay shipped code.
List<LearningTopic> decodeMobileCatalog(Map<String, dynamic> catalog) {
  if (catalog['topics'] is! List || catalog['activities'] is! List) {
    throw const FormatException('Invalid learning catalog');
  }
  final activities = (catalog['activities'] as List).cast<Map>();
  final result = <LearningTopic>[];
  for (final row in (catalog['topics'] as List).cast<Map>()) {
    if (row['status'] != 'active') continue;
    final local = topics.where((t) => t.id == row['id']).firstOrNull;
    if (local == null) continue;
    final scenes = activities.where((a) => a['topic_id'] == local.id).toList()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    if (scenes.isEmpty || scenes.length != local.experiments.length) continue;
    if (scenes.indexed.any((entry) {
      final spec = local.experiments[entry.$1];
      final remote = entry.$2;
      return remote['activity_id'] != spec.id ||
          remote['content_version'] != spec.contentVersion ||
          remote['mechanism'] != spec.mechanism ||
          !equivalentCatalogValue(remote['config'], spec.config) ||
          !equivalentCatalogValue(remote['initial_state'], spec.initial);
    })) {
      continue;
    }
    result.add(
      LearningTopic(
        local.id,
        row['title'] as String,
        row['subtitle'] as String,
        row['subject'] as String,
        _topicIcons[row['icon_key']] ?? Icons.menu_book_outlined,
        local.color,
        row['action_label'] as String,
      ),
    );
  }
  return List.unmodifiable(result);
}
