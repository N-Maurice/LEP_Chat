import '../core/api_client.dart';
import '../models/api_models.dart';

/// Wraps the /education endpoints, matching api_lep_chat/app/routers/education.py.
/// Courses are generated (embedding + vector search + Gemini) and cached server-side —
/// this client just reads whatever the backend returns.
class EducationApiService {
  EducationApiService(this._client);

  final ApiClient _client;

  Future<List<EducationTrack>> listTracks() async {
    final data = await _client.get('/education/tracks') as List<dynamic>;
    return data.map((e) => EducationTrack.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EducationCourse> getCourse(String track, {bool regenerate = false}) async {
    final path = '/education/courses/$track${regenerate ? '?regenerate=true' : ''}';
    final data = await _client.get(path);
    return EducationCourse.fromJson(data as Map<String, dynamic>);
  }
}
