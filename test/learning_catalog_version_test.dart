import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/data/repositories/learning_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'default_tutor_test.dart' show signedInClient, owner;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'catalog request uses the shipped version so new engines reach mobile',
    () async {
      final client = await signedInClient();
      addTearDown(client.dispose);
      final version = RegExp(
        r'^version: ([^+]+)',
        multiLine: true,
      ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);
      final repo = SupabaseLearningRepository(
        client: client,
        url: 'https://cloud.example',
        publishableKey: 'publishable-test',
        transport: MockClient((request) async {
          expect(request.url.path, '/functions/v1/learning-api/catalog');
          expect(request.url.queryParameters['app_version'], version);
          return http.Response(
            jsonEncode({'topics': [], 'activities': []}),
            200,
          );
        }),
      );
      expect(await repo.catalog(owner), {'topics': [], 'activities': []});
    },
  );
}
