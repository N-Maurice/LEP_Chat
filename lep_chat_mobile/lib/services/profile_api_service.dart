import '../core/api_client.dart';
import '../models/api_models.dart';

/// Wraps the /users/me endpoints, matching api_lep_chat/app/routers/users.py.
/// The uid always comes from the caller's Firebase ID token server-side —
/// nothing here ever sends a uid in the request body.
class ProfileApiService {
  ProfileApiService(this._client);

  final ApiClient _client;

  Future<UserProfile> getMyProfile() async {
    final data = await _client.get('/users/me');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<UserProfile> createMyProfile({
    required String fullName,
    required String username,
    String? phoneNumber,
    String? jurisdiction,
    String? nationalId,
  }) async {
    final data = await _client.post(
      '/users/me',
      body: {
        'full_name': fullName,
        'username': username,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (jurisdiction != null) 'jurisdiction': jurisdiction,
        if (nationalId != null) 'national_id': nationalId,
      },
    );
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<UserProfile> updateMyProfile(Map<String, dynamic> fields) async {
    final data = await _client.patch('/users/me', body: fields);
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }
}
