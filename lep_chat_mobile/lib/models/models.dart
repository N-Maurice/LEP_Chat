import 'package:flutter/material.dart';

/// Data contracts for the LEP app.
/// These mirror the shape of the future REST responses so screens can be
/// pointed at live endpoints later without changing any widget code:
///   ChatMessage    -> GET /api/v1/assistant/sessions/:id
///   PrimaryCase    -> GET /api/v1/cases/:id
///   ResearchResult -> GET /api/v1/research/search?q=&jurisdiction=

enum MessageRole { assistant, user }

class Citation {
  final String quote;
  final String source;
  final String jurisdiction;
  final int verifiedYear;
  final String url;

  const Citation({
    required this.quote,
    required this.source,
    required this.jurisdiction,
    required this.verifiedYear,
    required this.url,
  });
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String time;
  final String content;
  final Citation? citation;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.time,
    required this.content,
    this.citation,
  });
}

class QuickAction {
  final String id;
  final String label;
  final IconData icon;

  const QuickAction({
    required this.id,
    required this.label,
    required this.icon,
  });
}

enum TimelineState { done, upcoming }

class CaseTimelineItem {
  final String id;
  final String date;
  final String title;
  final TimelineState state;
  final String description;
  final String? attachment;

  const CaseTimelineItem({
    required this.id,
    required this.date,
    required this.title,
    required this.state,
    required this.description,
    this.attachment,
  });
}

class PrimaryCase {
  final String title;
  final String ref;
  final String status;
  final String nextHearing;
  final String institution;
  final int partiesCount;
  final int extraParties;
  final List<CaseTimelineItem> timeline;

  const PrimaryCase({
    required this.title,
    required this.ref,
    required this.status,
    required this.nextHearing,
    required this.institution,
    required this.partiesCount,
    required this.extraParties,
    required this.timeline,
  });
}

class OtherCase {
  final String id;
  final String title;
  final String status;
  final IconData icon;

  const OtherCase({
    required this.id,
    required this.title,
    required this.status,
    required this.icon,
  });
}

class ResearchResult {
  final String id;
  final String institution;
  final String tag;
  final String title;
  final String summary;

  const ResearchResult({
    required this.id,
    required this.institution,
    required this.tag,
    required this.title,
    required this.summary,
  });
}

class RoadmapItem {
  final String label;
  final bool live;

  const RoadmapItem({required this.label, required this.live});
}
