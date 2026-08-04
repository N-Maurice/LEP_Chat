import '../core/api_client.dart';
import '../models/api_models.dart';

/// Wraps GET /research/search and /research/documents/url — real semantic
/// search over the ingested Firestore chunks, and signed GCS URLs so "Read
/// Original"/"Download" open the actual source PDF.
class ResearchApiService {
  ResearchApiService(this._client);

  final ApiClient _client;

  Future<List<ApiResearchResult>> search(String query) async {
    final path = '/research/search?q=${Uri.encodeQueryComponent(query)}';
    final data = await _client.get(path) as List<dynamic>;
    return data.map((e) => ApiResearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> getDocumentUrl(String gcsPath) async {
    final path = '/research/documents/url?gcs_path=${Uri.encodeQueryComponent(gcsPath)}';
    final data = await _client.get(path) as Map<String, dynamic>;
    return data['url'] as String;
  }
}
