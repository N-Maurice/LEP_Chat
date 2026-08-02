/// Data contracts mirroring the FastAPI backend's response shapes (see
/// api_lep_chat/app/schemas/). Kept separate from models.dart, which still
/// backs the screens that don't have a live endpoint yet (Cases, Research Hub).
library;

class ApiCitation {
  final String source;
  final String? quote;
  final String? lawNumber;
  final String? lawYear;
  final String? gcsPath;
  final String? domain;

  const ApiCitation({
    required this.source,
    this.quote,
    this.lawNumber,
    this.lawYear,
    this.gcsPath,
    this.domain,
  });

  factory ApiCitation.fromJson(Map<String, dynamic> json) => ApiCitation(
        source: json['source'] as String,
        quote: json['quote'] as String?,
        lawNumber: json['law_number'] as String?,
        lawYear: json['law_year'] as String?,
        gcsPath: json['gcs_path'] as String?,
        domain: json['domain'] as String?,
      );
}

class ApiMessage {
  final String id;
  final String sessionId;
  final String role; // 'user' | 'assistant'
  final String content;
  final List<ApiCitation> citations;
  final DateTime? createdAt;

  const ApiMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.citations = const [],
    this.createdAt,
  });

  bool get isUser => role == 'user';

  factory ApiMessage.fromJson(Map<String, dynamic> json) => ApiMessage(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        citations: (json['citations'] as List<dynamic>? ?? [])
            .map((e) => ApiCitation.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      );
}

class ApiSession {
  final String id;
  final String userId;
  final String title;
  final DateTime? updatedAt;

  const ApiSession({
    required this.id,
    required this.userId,
    required this.title,
    this.updatedAt,
  });

  factory ApiSession.fromJson(Map<String, dynamic> json) => ApiSession(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      );
}

class UserProfile {
  final String uid;
  final String? email;
  final String fullName;
  final String username;
  final String? phoneNumber;
  final String? jurisdiction;
  final String? nationalId;

  const UserProfile({
    required this.uid,
    this.email,
    required this.fullName,
    required this.username,
    this.phoneNumber,
    this.jurisdiction,
    this.nationalId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String,
        email: json['email'] as String?,
        fullName: json['full_name'] as String,
        username: json['username'] as String,
        phoneNumber: json['phone_number'] as String?,
        jurisdiction: json['jurisdiction'] as String?,
        nationalId: json['national_id'] as String?,
      );
}

class EducationTrack {
  final String slug;
  final String label;

  const EducationTrack({required this.slug, required this.label});

  factory EducationTrack.fromJson(Map<String, dynamic> json) => EducationTrack(
        slug: json['slug'] as String,
        label: json['label'] as String,
      );
}

class CourseModule {
  final String title;
  final String summary;
  final List<ApiCitation> citations;

  const CourseModule({required this.title, required this.summary, this.citations = const []});

  factory CourseModule.fromJson(Map<String, dynamic> json) => CourseModule(
        title: json['title'] as String,
        summary: json['summary'] as String,
        citations: (json['citations'] as List<dynamic>? ?? [])
            .map((e) => ApiCitation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class EducationCourse {
  final String track;
  final String title;
  final String description;
  final List<CourseModule> modules;
  final DateTime? generatedAt;

  const EducationCourse({
    required this.track,
    required this.title,
    required this.description,
    this.modules = const [],
    this.generatedAt,
  });

  factory EducationCourse.fromJson(Map<String, dynamic> json) => EducationCourse(
        track: json['track'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        modules: (json['modules'] as List<dynamic>? ?? [])
            .map((e) => CourseModule.fromJson(e as Map<String, dynamic>))
            .toList(),
        generatedAt: json['generated_at'] != null ? DateTime.tryParse(json['generated_at'] as String) : null,
      );
}
