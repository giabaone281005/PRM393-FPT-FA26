import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/data/models/authored_lesson.dart';
import 'package:brilliant_mobile/data/providers/admin_dashboard_controller.dart';
import 'package:brilliant_mobile/experiments/reasoning_workspace.dart';
import 'package:brilliant_mobile/features/admin/admin_lesson_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_content_test.dart' show CmsAdminRepository, lessonPayload;
import 'admin_dashboard_test.dart' show TestAdminAuth;

void main() {
  testWidgets(
    'render the generated draft in admin and mobile with real fonts',
    (tester) async {
      final font = FontLoader('CofoBrilliant')
        ..addFont(rootBundle.load('assets/fonts/CofoBrilliant-Regular.ttf'));
      final fallback = FontLoader('NotoSans')
        ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await font.load();
      await fallback.load();
      await icons.load();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final file = File('build/admin-gemini-live.json');
      final data = file.existsSync()
          ? (jsonDecode(file.readAsStringSync()) as Map)['draft'] as Map
          : lessonPayload();
      final row = <String, dynamic>{
        ...lessonPayload(),
        ...Map<String, dynamic>.from(data),
        'id': 'cms-lesson',
        'activity_id': 'cms-lesson',
        'evaluator_version': 3,
        'mechanism': 'reasonedChoice',
        'content_version': 1,
        'editor_status': 'active',
        'hint_levels': [data['hint']],
      };
      final auth = TestAdminAuth(), repo = CmsAdminRepository();
      final controller = AdminDashboardController(auth: auth, repository: repo);
      final boundary = GlobalKey();
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          image.dispose();
          await File('build/$name.png')
              .writeAsBytes(bytes.buffer.asUint8List());
        });
      }

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: Scaffold(
              body: AdminLessonEditor(
                controller: controller,
                topicId: 'cms-topic',
                lesson: row,
                onSaved: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );
      await capture('admin-content-editor');
      final spec = decodeAuthoredLesson(row)!;
      expect(
        spec.isCorrect({
          'answer': spec.config['answer'],
          'reason': spec.config['reason'],
        }),
        true,
      );
      tester.view.physicalSize = const Size(390, 1100);
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: Scaffold(
              appBar: AppBar(title: const Text('Xem thử bài học')),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(spec.prompt),
                    const SizedBox(height: 24),
                    ReasoningWorkspace(
                      spec: spec,
                      data: spec.initialData(),
                      locked: false,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await capture('admin-content-mobile');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await auth.events.close();
      await repo.events.close();
      await repo.catalogEvents.close();
    },
  );
}
