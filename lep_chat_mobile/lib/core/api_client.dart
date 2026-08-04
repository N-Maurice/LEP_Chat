import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'env.dart';

/// Thrown for any non-2xx response; carries the HTTP status so callers can
/// branch on it (e.g. 404 -> "no profile yet" during the signup flow).
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin wrapper around the LEP Chat FastAPI backend. Attaches the current
/// Firebase ID token to every request — the backend is the only thing that
/// talks to Firestore, so every read/write from the app goes through here.
///
/// [getIdToken] defaults to reading FirebaseAuth.instance, but is injectable
/// so this class can be unit tested without a real Firebase app.
class ApiClient {
  ApiClient({http.Client? httpClient, Future<String?> Function()? getIdToken})
      : _http = httpClient ?? http.Client(),
        _getIdToken = getIdToken ?? _defaultGetIdToken;

  final http.Client _http;
  final Future<String?> Function() _getIdToken;

  static Future<String?> _defaultGetIdToken() =>
      FirebaseAuth.instance.currentUser?.getIdToken() ?? Future.value(null);

  Uri _uri(String path) => Uri.parse('${Env.instance.apiBaseUrl}$path');

  Future<Map<String, String>> _headers() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await _getIdToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {
      // Response body wasn't JSON — fall back to the raw text above.
    }
    throw ApiException(response.statusCode, message);
  }

  Future<dynamic> get(String path) async {
    final response = await _http.get(_uri(path), headers: await _headers());
    return _decode(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _http.post(
      _uri(path),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await _http.patch(
      _uri(path),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  Future<void> delete(String path) async {
    final response = await _http.delete(_uri(path), headers: await _headers());
    _decode(response);
  }

  /// Multipart upload for evidence files (Cases / Report a Violation). [bytes] is the
  /// raw file content and [filename] is sent as-is — the backend infers content type
  /// from [contentType] if the caller has it, otherwise lets the server guess.
  Future<dynamic> postMultipart(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    final token = await _getIdToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: filename,
      contentType: contentType != null ? MediaType.parse(contentType) : null,
    ));
    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }
}
