import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

/// Loads .env.json (declared as a Flutter asset in pubspec.yaml) so the app can
/// point at localhost during development and the deployed backend in prod
/// without touching any Dart source — just edit the URL and rebuild.
class Env {
  Env._({required this.apiBaseUrl});

  final String apiBaseUrl;

  static Env? _instance;

  static Env get instance {
    final env = _instance;
    if (env == null) {
      throw StateError('Env.load() must be awaited before Env.instance is used.');
    }
    return env;
  }

  static Future<void> load() async {
    final raw = await rootBundle.loadString('.env.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _instance = Env._(apiBaseUrl: json['API_BASE_URL'] as String);
  }

  /// Test-only: sets [instance] directly, bypassing asset loading (which
  /// needs a fully initialized widget binding plain `test()` blocks don't set up).
  @visibleForTesting
  static void debugSetInstance({required String apiBaseUrl}) {
    _instance = Env._(apiBaseUrl: apiBaseUrl);
  }
}
