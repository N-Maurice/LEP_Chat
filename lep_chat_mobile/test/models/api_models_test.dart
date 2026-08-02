import 'package:flutter_test/flutter_test.dart';
import 'package:lep_app/models/api_models.dart';

void main() {
  group('ApiCitation.fromJson', () {
    test('parses all fields', () {
      final citation = ApiCitation.fromJson({
        'source': 'vat_law.pdf',
        'quote': 'VAT is charged at 18 percent.',
        'law_number': '49',
        'law_year': '2023',
        'gcs_path': 'Domestic laws/Tax/vat_law.pdf',
        'domain': 'Tax',
      });

      expect(citation.source, 'vat_law.pdf');
      expect(citation.quote, 'VAT is charged at 18 percent.');
      expect(citation.lawNumber, '49');
      expect(citation.lawYear, '2023');
      expect(citation.gcsPath, 'Domestic laws/Tax/vat_law.pdf');
      expect(citation.domain, 'Tax');
    });

    test('tolerates missing optional fields', () {
      final citation = ApiCitation.fromJson({'source': 'unknown.pdf'});
      expect(citation.source, 'unknown.pdf');
      expect(citation.quote, isNull);
      expect(citation.lawNumber, isNull);
    });
  });

  group('ApiMessage.fromJson', () {
    test('parses a user message with no citations', () {
      final message = ApiMessage.fromJson({
        'id': 'msg-1',
        'session_id': 'session-1',
        'role': 'user',
        'content': 'What is VAT in Rwanda?',
        'citations': [],
        'created_at': '2024-10-24T10:05:00Z',
      });

      expect(message.id, 'msg-1');
      expect(message.sessionId, 'session-1');
      expect(message.role, 'user');
      expect(message.isUser, isTrue);
      expect(message.content, 'What is VAT in Rwanda?');
      expect(message.citations, isEmpty);
      expect(message.createdAt, DateTime.parse('2024-10-24T10:05:00Z'));
    });

    test('parses an assistant message with citations and isUser is false', () {
      final message = ApiMessage.fromJson({
        'id': 'msg-2',
        'session_id': 'session-1',
        'role': 'assistant',
        'content': 'VAT is 18% [Source 1].',
        'citations': [
          {'source': 'vat_law.pdf'}
        ],
      });

      expect(message.isUser, isFalse);
      expect(message.citations, hasLength(1));
      expect(message.citations.first.source, 'vat_law.pdf');
      expect(message.createdAt, isNull);
    });

    test('defaults citations to an empty list when absent', () {
      final message = ApiMessage.fromJson({
        'id': 'msg-3',
        'session_id': 'session-1',
        'role': 'assistant',
        'content': 'No sources needed.',
      });
      expect(message.citations, isEmpty);
    });
  });

  group('ApiSession.fromJson', () {
    test('parses fields', () {
      final session = ApiSession.fromJson({
        'id': 'session-1',
        'user_id': 'user-1',
        'title': 'Land dispute',
        'updated_at': '2024-10-24T10:00:00Z',
      });

      expect(session.id, 'session-1');
      expect(session.userId, 'user-1');
      expect(session.title, 'Land dispute');
      expect(session.updatedAt, DateTime.parse('2024-10-24T10:00:00Z'));
    });
  });

  group('UserProfile.fromJson', () {
    test('parses required and optional fields', () {
      final profile = UserProfile.fromJson({
        'uid': 'user-1',
        'email': 'jean.luc@example.com',
        'full_name': 'Jean-Luc',
        'username': 'jeanluc',
        'jurisdiction': 'Rwanda',
      });

      expect(profile.uid, 'user-1');
      expect(profile.email, 'jean.luc@example.com');
      expect(profile.fullName, 'Jean-Luc');
      expect(profile.username, 'jeanluc');
      expect(profile.jurisdiction, 'Rwanda');
      expect(profile.phoneNumber, isNull);
      expect(profile.nationalId, isNull);
    });
  });
}
