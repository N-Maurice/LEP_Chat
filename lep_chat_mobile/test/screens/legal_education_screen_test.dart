import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lep_app/core/api_client.dart';
import 'package:lep_app/core/env.dart';
import 'package:lep_app/screens/legal_education_screen.dart';
import 'package:lep_app/services/education_api_service.dart';

const _tracksJson = [
  {'slug': 'labour-law-101', 'label': 'Labour Law 101'},
  {'slug': 'business-compliance', 'label': 'Business Compliance'},
  {'slug': 'family-law', 'label': 'Family Law'},
  {'slug': 'land-rights', 'label': 'Land Rights'},
];

Map<String, dynamic> _courseJson(String track, {List<Map<String, dynamic>>? modules}) => {
      'track': track,
      'title': 'Generated course for $track',
      'description': 'A grounded description for $track.',
      'modules': modules ??
          List.generate(
            5,
            (i) => {
              'title': 'Module ${i + 1}',
              'summary': 'Summary for module ${i + 1}',
              'citations': [
                {'source': 'law_$track.pdf', 'quote': 'An excerpt.', 'domain': 'Test'},
              ],
            },
          ),
    };

/// Builds an EducationApiService backed by a MockClient, so these tests never touch
/// a real network. [respondToCourse] receives the requested track slug.
EducationApiService _serviceWith({
  required List<Map<String, dynamic>> tracks,
  required Map<String, dynamic> Function(String track) respondToCourse,
  List<String>? requestedPaths,
}) {
  final mockClient = MockClient((request) async {
    requestedPaths?.add(request.url.path);
    if (request.url.path.endsWith('/education/tracks')) {
      return http.Response(jsonEncode(tracks), 200);
    }
    final track = request.url.path.split('/').last;
    return http.Response(jsonEncode(respondToCourse(track)), 200);
  });
  Env.debugSetInstance(apiBaseUrl: 'https://api.test/api/v1');
  return EducationApiService(ApiClient(httpClient: mockClient, getIdToken: () async => null));
}

void main() {
  testWidgets('loads tracks and shows the active course with its modules', (tester) async {
    final service = _serviceWith(tracks: _tracksJson, respondToCourse: (track) => _courseJson(track));

    await tester.pumpWidget(MaterialApp(home: LegalEducationScreen(educationApi: service)));
    await tester.pumpAndSettle();

    expect(find.text('Labour Law 101'), findsOneWidget);
    expect(find.text('Business Compliance'), findsOneWidget);
    expect(find.text('Generated course for labour-law-101'), findsOneWidget);
    expect(find.text('Module 1'), findsOneWidget);
    expect(find.text('5 modules'), findsOneWidget);
  });

  testWidgets('tapping a module opens it on its own page with Previous/Next navigation', (tester) async {
    final service = _serviceWith(tracks: _tracksJson, respondToCourse: (track) => _courseJson(track));

    await tester.pumpWidget(MaterialApp(home: LegalEducationScreen(educationApi: service)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Module 1'));
    await tester.pumpAndSettle();

    // Landed on the module's own page (back button now present, list of tracks is gone).
    expect(find.text('Module 1 of 5'), findsOneWidget);
    expect(find.text('Business Compliance'), findsNothing);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Previous'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Module 2 of 5'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);

    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    expect(find.text('Module 1 of 5'), findsOneWidget);
  });

  testWidgets('switching tracks fetches and displays the new course', (tester) async {
    final requestedPaths = <String>[];
    final service = _serviceWith(
      tracks: _tracksJson,
      respondToCourse: (track) => _courseJson(track),
      requestedPaths: requestedPaths,
    );

    await tester.pumpWidget(MaterialApp(home: LegalEducationScreen(educationApi: service)));
    await tester.pumpAndSettle();

    expect(find.text('Generated course for labour-law-101'), findsOneWidget);

    await tester.tap(find.text('Family Law'));
    await tester.pumpAndSettle();

    expect(find.text('Generated course for family-law'), findsOneWidget);
    expect(requestedPaths.any((p) => p.endsWith('/education/courses/family-law')), isTrue);
  });

  testWidgets('shows a message when a track has no ingested content yet', (tester) async {
    final service = _serviceWith(
      tracks: _tracksJson,
      respondToCourse: (track) => _courseJson(track, modules: []),
    );

    await tester.pumpWidget(MaterialApp(home: LegalEducationScreen(educationApi: service)));
    await tester.pumpAndSettle();

    expect(find.textContaining('No ingested legal content'), findsOneWidget);
  });

  testWidgets('shows an error banner when loading tracks fails', (tester) async {
    Env.debugSetInstance(apiBaseUrl: 'https://api.test/api/v1');
    final mockClient = MockClient((request) async {
      return http.Response(jsonEncode({'detail': 'Server exploded'}), 500);
    });
    final service = EducationApiService(ApiClient(httpClient: mockClient, getIdToken: () async => null));

    await tester.pumpWidget(MaterialApp(home: LegalEducationScreen(educationApi: service)));
    await tester.pumpAndSettle();

    expect(find.text('Server exploded'), findsOneWidget);
  });
}
