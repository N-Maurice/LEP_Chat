import '../core/api_client.dart';
import '../models/api_models.dart';

/// Wraps the /sessions and /sessions/{id}/messages endpoints — full CRUD for
/// chat threads and their messages, matching api_lep_chat/app/routers/sessions.py
/// and messages.py.
class ChatApiService {
  ChatApiService(this._client);

  final ApiClient _client;

  Future<List<ApiSession>> listSessions() async {
    final data = await _client.get('/sessions') as List<dynamic>;
    return data.map((e) => ApiSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ApiSession> createSession({String title = 'New conversation'}) async {
    final data = await _client.post('/sessions', body: {'title': title});
    return ApiSession.fromJson(data as Map<String, dynamic>);
  }

  Future<ApiSession> renameSession(String sessionId, String title) async {
    final data = await _client.patch('/sessions/$sessionId', body: {'title': title});
    return ApiSession.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSession(String sessionId) => _client.delete('/sessions/$sessionId');

  Future<List<ApiMessage>> listMessages(String sessionId) async {
    final data = await _client.get('/sessions/$sessionId/messages') as List<dynamic>;
    return data.map((e) => ApiMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Sends a user message and returns both the stored user turn and the
  /// assistant's generated reply, matching POST /sessions/{id}/messages.
  Future<(ApiMessage userMessage, ApiMessage assistantMessage)> sendMessage(
    String sessionId,
    String content,
  ) async {
    final data = await _client.post('/sessions/$sessionId/messages', body: {'content': content})
        as Map<String, dynamic>;
    return (
      ApiMessage.fromJson(data['user_message'] as Map<String, dynamic>),
      ApiMessage.fromJson(data['assistant_message'] as Map<String, dynamic>),
    );
  }

  Future<ApiMessage> updateMessage(String sessionId, String messageId, String content) async {
    final data = await _client.patch(
      '/sessions/$sessionId/messages/$messageId',
      body: {'content': content},
    );
    return ApiMessage.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteMessage(String sessionId, String messageId) =>
      _client.delete('/sessions/$sessionId/messages/$messageId');
}
