import '../core/api_client.dart';
import '../models/api_models.dart';

/// Wraps /users/search and /conversations — in-app direct messages between
/// citizens (see api_lep_chat/app/routers/conversations.py).
class ConversationApiService {
  ConversationApiService(this._client);

  final ApiClient _client;

  Future<List<PublicUser>> searchUsers(String query) async {
    final path = '/users/search?q=${Uri.encodeQueryComponent(query)}';
    final data = await _client.get(path) as List<dynamic>;
    return data.map((e) => PublicUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ApiConversation>> listConversations() async {
    final data = await _client.get('/conversations') as List<dynamic>;
    return data.map((e) => ApiConversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ApiConversation> startConversation(String recipientUid) async {
    final data = await _client.post('/conversations', body: {'recipient_uid': recipientUid});
    return ApiConversation.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ApiDirectMessage>> listMessages(String conversationId) async {
    final data = await _client.get('/conversations/$conversationId/messages') as List<dynamic>;
    return data.map((e) => ApiDirectMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ApiDirectMessage> sendMessage(String conversationId, String content) async {
    final data = await _client.post('/conversations/$conversationId/messages', body: {'content': content});
    return ApiDirectMessage.fromJson(data as Map<String, dynamic>);
  }
}
