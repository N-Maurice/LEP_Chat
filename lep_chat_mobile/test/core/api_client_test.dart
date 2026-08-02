import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lep_app/core/api_client.dart';
import 'package:lep_app/core/env.dart';

void main() {
  setUpAll(() {
    // ApiClient reads Env.instance.apiBaseUrl to build request URIs.
    Env.debugSetInstance(apiBaseUrl: 'https://api.test/api/v1');
  });

  ApiClient buildClient(http.Client mock, {String? token}) {
    return ApiClient(httpClient: mock, getIdToken: () async => token);
  }

  test('get() decodes a JSON object response', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, endsWith('/sessions'));
      return http.Response(jsonEncode({'id': 'session-1'}), 200);
    });

    final result = await buildClient(mock).get('/sessions');
    expect(result, {'id': 'session-1'});
  });

  test('attaches Authorization header when a token is available', () async {
    String? seenAuthHeader;
    final mock = MockClient((request) async {
      seenAuthHeader = request.headers['Authorization'];
      return http.Response('{}', 200);
    });

    await buildClient(mock, token: 'abc123').get('/users/me');
    expect(seenAuthHeader, 'Bearer abc123');
  });

  test('omits Authorization header when there is no token', () async {
    String? seenAuthHeader;
    final mock = MockClient((request) async {
      seenAuthHeader = request.headers['Authorization'];
      return http.Response('{}', 200);
    });

    await buildClient(mock, token: null).get('/health');
    expect(seenAuthHeader, isNull);
  });

  test('post() sends a JSON-encoded body', () async {
    Map<String, dynamic>? seenBody;
    final mock = MockClient((request) async {
      seenBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'ok': true}), 201);
    });

    await buildClient(mock).post('/sessions', body: {'title': 'New conversation'});
    expect(seenBody, {'title': 'New conversation'});
  });

  test('delete() returns normally on a 204 with an empty body', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'DELETE');
      return http.Response('', 204);
    });

    await buildClient(mock).delete('/sessions/session-1');
  });

  test('throws ApiException with the backend detail message on error responses', () async {
    final mock = MockClient((request) async {
      return http.Response(jsonEncode({'detail': 'Session not found'}), 404);
    });

    await expectLater(
      buildClient(mock).get('/sessions/does-not-exist'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'Session not found'),
      ),
    );
  });

  test('falls back to the raw body when the error response is not JSON', () async {
    final mock = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    await expectLater(
      buildClient(mock).get('/sessions'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', 'Internal Server Error'),
      ),
    );
  });
}
