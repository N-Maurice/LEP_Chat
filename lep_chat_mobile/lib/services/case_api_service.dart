import '../core/api_client.dart';
import '../models/api_models.dart';

/// Wraps /cases — case submission, evidence upload, and status tracking.
/// Report a Violation posts here too, with caseType: 'violation_report', so both
/// features share one backend and one tracking list (see api_lep_chat/app/routers/cases.py).
class CaseApiService {
  CaseApiService(this._client);

  final ApiClient _client;

  Future<List<ApiCase>> listCases() async {
    final data = await _client.get('/cases') as List<dynamic>;
    return data.map((e) => ApiCase.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ApiCase> getCase(String caseId) async {
    final data = await _client.get('/cases/$caseId');
    return ApiCase.fromJson(data as Map<String, dynamic>);
  }

  Future<ApiCase> createCase({
    required String title,
    required String category,
    required String description,
    String caseType = 'case',
    String? location,
  }) async {
    final data = await _client.post('/cases', body: {
      'case_type': caseType,
      'title': title,
      'category': category,
      'description': description,
      if (location != null) 'location': location,
    });
    return ApiCase.fromJson(data as Map<String, dynamic>);
  }

  Future<ApiCase> uploadEvidence(
    String caseId, {
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final data = await _client.postMultipart(
      '/cases/$caseId/evidence',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return ApiCase.fromJson(data as Map<String, dynamic>);
  }
}
