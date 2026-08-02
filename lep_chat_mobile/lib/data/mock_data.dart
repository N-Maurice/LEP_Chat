import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';

/// Mock data shaped like future API responses.
/// Replace each constant below with a real repository/fetch call once the
/// backend is ready — screen widgets read straight from these, so nothing
/// else needs to change.
///   assistantMessages / assistantQuickActions -> assistant session endpoint
///   primaryCase / otherCases / activeCaseCount -> case tracking endpoint
///   researchResults / researchCategories       -> legal research endpoint

const List<ChatMessage> assistantMessages = [
  ChatMessage(
    id: 'm1',
    role: MessageRole.assistant,
    time: '10:02 AM',
    content:
        "Greetings. I am your specialized AI Legal Assistant. How can I assist you with Rwandan law or international legal frameworks today?",
  ),
  ChatMessage(
    id: 'm2',
    role: MessageRole.user,
    time: '10:05 AM',
    content:
        "Can you explain the right to a fair trial under the Constitution of Rwanda?",
  ),
  ChatMessage(
    id: 'm3',
    role: MessageRole.assistant,
    time: '10:06 AM',
    content:
        "In simple terms, the Constitution ensures that every person has the right to be heard by a competent, independent, and impartial court. This means no one can be punished for an act that wasn't a crime when it happened, and everyone is presumed innocent until proven guilty.",
    citation: Citation(
      quote:
          "Everyone has the right to be informed of the nature and cause of charges against them and the right to defense. No one shall be prosecuted, arrested, detained or punished except in cases provided for by the law in force at the time the offense was committed.",
      source: 'Article 29, Constitution of Rwanda',
      jurisdiction: 'Rwanda',
      verifiedYear: 2024,
      url: '#',
    ),
  ),
];

const List<QuickAction> assistantQuickActions = [
  QuickAction(id: 'qa1', label: 'Speak to a Lawyer', icon: LucideIcons.users),
  QuickAction(id: 'qa2', label: 'View Court Process', icon: LucideIcons.landmark),
  QuickAction(id: 'qa3', label: 'Draft Legal Notice', icon: LucideIcons.fileText),
];

const int activeCaseCount = 12;

const PrimaryCase primaryCase = PrimaryCase(
  title: 'Labour Dispute #4521',
  ref: 'RWF-2024-LD-009',
  status: 'In Progress',
  nextHearing: 'Oct 24, 2023',
  institution: 'High Court, Kigali',
  partiesCount: 2,
  extraParties: 2,
  timeline: [
    CaseTimelineItem(
      id: 't1',
      date: 'Oct 12, 2023',
      title: 'Evidence Uploaded',
      state: TimelineState.done,
      description:
          '12 PDF documents and 3 video recordings successfully filed to the repository.',
      attachment: 'contracts_revised.pdf',
    ),
    CaseTimelineItem(
      id: 't2',
      date: 'Oct 15, 2023',
      title: 'Preliminary Hearing',
      state: TimelineState.done,
      description:
          'Procedural motions reviewed. The judge sustained the motion to expedite.',
    ),
    CaseTimelineItem(
      id: 't3',
      date: 'Upcoming · Nov 02, 2023',
      title: 'Final Verdict',
      state: TimelineState.upcoming,
      description:
          "Final deliberation and reading of the court's decision regarding the dispute.",
    ),
  ],
);

const List<OtherCase> otherCases = [
  OtherCase(
    id: 'c2',
    title: 'Real Estate Dispute',
    status: 'Pending Review',
    icon: LucideIcons.scale,
  ),
  OtherCase(
    id: 'c3',
    title: 'IP Infringement #003',
    status: 'Case Closed',
    icon: LucideIcons.fileText,
  ),
];

const String researchJurisdiction = 'Rwanda';
const List<String> jurisdictionOptions = ['Rwanda', 'South Africa', 'Kenya', 'Nigeria'];
const List<String> researchCategories = [
  'All Categories',
  'Labour Law',
  'Family Law',
  'Property',
  'Constitutional',
];
const String researchQuery = 'employment dismissal terms';
const int researchResultCount = 1240;

const List<ResearchResult> researchResults = [
  ResearchResult(
    id: 'r1',
    institution: 'High Court of Rwanda',
    tag: 'Labour Law',
    title: 'Article 24: Termination of Employment Contracts',
    summary:
        "Outlines an employer's obligation to provide written notice and just cause when ending an employment contract, and the employee's right to contest dismissal before the labour inspectorate.",
  ),
  ResearchResult(
    id: 'r2',
    institution: 'Constitutional Court',
    tag: 'Constitutional',
    title: 'The Right to Fair Labour Practice (Bill of Rights)',
    summary:
        'Detailed breakdown of the constitutional guarantee underpinning all labour legislation, establishing dignity and fairness in the workplace as a fundamental right.',
  ),
];

const List<RoadmapItem> roadmap = [
  RoadmapItem(label: 'AI Legal Assistant', live: true),
  RoadmapItem(label: 'Case Tracking', live: true),
  RoadmapItem(label: 'Legal Research Hub', live: true),
  RoadmapItem(label: 'Lawyer & Firm Portal', live: false),
  RoadmapItem(label: 'Document Management', live: false),
  RoadmapItem(label: 'Dispute Resolution', live: false),
  RoadmapItem(label: 'Compliance Monitoring', live: false),
  RoadmapItem(label: 'Gov Services Integration', live: false),
  RoadmapItem(label: 'Notifications', live: false),
];
