import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../models/api_models.dart';
import '../services/education_api_service.dart';
import '../services/research_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'course_module_screen.dart';
import 'regional_law_explorer_screen.dart';

enum _EducationSegment { tracks, research }

/// Screen — Legal Education. Combines two real, backend-grounded views:
///   - Learning Tracks: 5-module courses generated per track from ingested
///     Firestore chunks (api_lep_chat/app/agents/course_agent.py).
///   - Legal Research: semantic search over the same corpus
///     (api_lep_chat/app/agents/legal_research_agent.py's `search`), formerly
///     its own "Legal Ecosystem" tab, now folded in here.
class LegalEducationScreen extends StatefulWidget {
  final EducationApiService? educationApi;
  final ResearchApiService? researchApi;
  const LegalEducationScreen({super.key, this.educationApi, this.researchApi});

  @override
  State<LegalEducationScreen> createState() => _LegalEducationScreenState();
}

class _LegalEducationScreenState extends State<LegalEducationScreen> {
  late final EducationApiService _educationApi = widget.educationApi ?? EducationApiService(ApiClient());
  late final ResearchApiService _researchApi = widget.researchApi ?? ResearchApiService(ApiClient());

  _EducationSegment _segment = _EducationSegment.tracks;

  List<EducationTrack> _tracks = [];
  String? _activeTrackSlug;
  EducationCourse? _course;
  bool _loadingTracks = true;
  bool _loadingCourse = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final tracks = await _educationApi.listTracks();
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _loadingTracks = false;
      });
      if (tracks.isNotEmpty) {
        await _loadCourse(tracks.first.slug);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loadingTracks = false;
      });
    }
  }

  Future<void> _loadCourse(String slug, {bool regenerate = false}) async {
    setState(() {
      _activeTrackSlug = slug;
      _loadingCourse = true;
      _error = null;
    });
    try {
      final course = await _educationApi.getCourse(slug, regenerate: regenerate);
      if (!mounted) return;
      setState(() {
        _course = course;
        _loadingCourse = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loadingCourse = false;
      });
    }
  }

  String _friendlyError(Object e) => e is ApiException ? e.message : 'Could not load this course. Please try again.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Legal Education', meta: 'Generated from real Rwandan legal sources'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _SegmentToggle(
                segment: _segment,
                onChanged: (s) => setState(() => _segment = s),
              ),
            ),
            Expanded(
              child: _segment == _EducationSegment.tracks
                  ? _buildLearningTracks()
                  : _LegalResearchSection(researchApi: _researchApi),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningTracks() {
    return _loadingTracks
        ? const Center(child: CircularProgressIndicator(color: AppColors.oxblood))
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (_error != null) LepErrorBanner(message: _error!),
              const SectionLabel('Learning Tracks'),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tracks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final track = _tracks[i];
                    final active = track.slug == _activeTrackSlug;
                    return GestureDetector(
                      onTap: () => _loadCourse(track.slug),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? AppColors.oxblood : AppColors.paperDim,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: active ? AppColors.oxblood : AppColors.line),
                        ),
                        child: Text(
                          track.label,
                          style: AppText.body(
                            size: 12,
                            weight: FontWeight.w700,
                            color: active ? AppColors.paper : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_loadingCourse)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.oxblood)),
                )
              else if (_course != null)
                _CourseContent(
                  course: _course!,
                  onRegenerate: () => _loadCourse(_course!.track, regenerate: true),
                ),
            ],
          );
  }
}

class _SegmentToggle extends StatelessWidget {
  final _EducationSegment segment;
  final ValueChanged<_EducationSegment> onChanged;
  const _SegmentToggle({required this.segment, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paperDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(child: _segmentButton('Learning Tracks', _EducationSegment.tracks)),
          Expanded(child: _segmentButton('Legal Research', _EducationSegment.research)),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, _EducationSegment value) {
    final active = segment == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.oxblood : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: AppText.body(size: 12.5, weight: FontWeight.w700, color: active ? AppColors.paper : AppColors.inkSoft),
        ),
      ),
    );
  }
}

class _CourseContent extends StatelessWidget {
  final EducationCourse course;
  final VoidCallback onRegenerate;
  const _CourseContent({required this.course, required this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppColors.ink, AppColors.oxbloodDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LepPill(label: 'Generated Course', variant: PillVariant.tag),
                  InkWell(
                    onTap: onRegenerate,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.refreshCw, size: 15, color: AppColors.paper),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(course.title, style: AppText.display(size: 18, weight: FontWeight.w700, color: AppColors.paper)),
              const SizedBox(height: 6),
              Text(
                course.description,
                style: AppText.body(size: 12, color: AppColors.paper.withValues(alpha: 0.85)).copyWith(height: 1.4),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.layers, size: 12, color: AppColors.paper),
                  const SizedBox(width: 4),
                  Text('${course.modules.length} modules', style: AppText.body(size: 11, color: AppColors.paper.withValues(alpha: 0.85))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Modules'),
        const SizedBox(height: 10),
        if (course.modules.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.paperDim,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              "No ingested legal content is available for this track yet — check back once more documents have been added.",
              style: AppText.body(size: 12.5, color: AppColors.inkSoft),
            ),
          )
        else
          for (var i = 0; i < course.modules.length; i++) ...[
            _ModuleCard(
              index: i + 1,
              module: course.modules[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CourseModuleScreen(course: course, initialIndex: i)),
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final int index;
  final CourseModule module;
  final VoidCallback onTap;
  const _ModuleCard({required this.index, required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LepPill(label: 'MODULE $index'),
                    const SizedBox(height: 8),
                    Text(module.title, style: AppText.display(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      module.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 12, color: AppColors.inkSoft).copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}

/// The former Research Hub ("Legal Ecosystem") content, now the "Legal
/// Research" segment of Legal Education. Search is real: it calls
/// GET /research/search, which runs the same embedding + vector search used
/// by the AI Assistant, just without the final grounded-answer generation.
class _LegalResearchSection extends StatefulWidget {
  final ResearchApiService researchApi;
  const _LegalResearchSection({required this.researchApi});

  @override
  State<_LegalResearchSection> createState() => _LegalResearchSectionState();
}

class _LegalResearchSectionState extends State<_LegalResearchSection> {
  final TextEditingController _queryController = TextEditingController(text: 'employment dismissal terms');
  List<ApiResearchResult> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.researchApi.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Search failed. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _openDocument(ApiResearchResult result) async {
    final gcsPath = result.gcsPath;
    if (gcsPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No source document is linked to this result.')),
      );
      return;
    }
    try {
      final url = await widget.researchApi.getDocumentUrl(gcsPath);
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Could not open the source document.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SearchRow(controller: _queryController, onSubmitted: _search),
        const SizedBox(height: 16),
        if (_error != null) LepErrorBanner(message: _error!),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.oxblood)),
          )
        else ...[
          Text(
            '${_results.length} results for "${_queryController.text.trim()}"',
            style: AppText.body(size: 11.5, color: AppColors.slate),
          ),
          const SizedBox(height: 12),
          if (_results.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paperDim,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                'No matching ingested content found. Try a different phrasing.',
                style: AppText.body(size: 12.5, color: AppColors.inkSoft),
              ),
            )
          else
            for (final result in _results) _ResultCard(result: result, onOpenDocument: () => _openDocument(result)),
        ],
        const SizedBox(height: 4),
        const _ExplorerCard(),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  const _SearchRow({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.paperDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.search, size: 16, color: AppColors.slate),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: AppText.body(size: 12.5),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSubmitted(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.oxblood, borderRadius: BorderRadius.circular(12)),
          child: IconButton(
            onPressed: onSubmitted,
            icon: const Icon(LucideIcons.arrowRight, size: 18, color: AppColors.paper),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ApiResearchResult result;
  final VoidCallback onOpenDocument;
  const _ResultCard({required this.result, required this.onOpenDocument});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(LucideIcons.landmark, size: 13, color: AppColors.slate),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        result.institution,
                        style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.slate),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LepPill(label: result.tag, variant: PillVariant.tag),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.title,
            style: AppText.display(size: 15.5, weight: FontWeight.w600).copyWith(height: 1.3),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.paperDim,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              border: Border(left: BorderSide(color: AppColors.brass, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.messageSquareText, size: 12, color: AppColors.brass),
                    const SizedBox(width: 5),
                    Text(
                      'FROM THE SOURCE',
                      style: AppText.mono(size: 10, weight: FontWeight.w700, color: AppColors.brass, letterSpacing: 0.05),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  result.summary,
                  style: AppText.body(size: 12).copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onOpenDocument,
                icon: const Icon(LucideIcons.fileText, size: 14, color: AppColors.paper),
                label: Text(
                  'Read original',
                  style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.paper),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.oxblood,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 8),
              _OutlineIconButton(icon: LucideIcons.download, onTap: onOpenDocument),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlineIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 15, color: AppColors.inkSoft),
      ),
    );
  }
}

class _ExplorerCard extends StatelessWidget {
  const _ExplorerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, Color(0xFF3A2A24), AppColors.oxbloodDeep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Regional Law Explorer',
            style: AppText.display(size: 16, weight: FontWeight.w600, color: AppColors.paper),
          ),
          const SizedBox(height: 6),
          Text(
            'Navigate across 54 jurisdictions in Africa to compare legal frameworks and case precedents instantly.',
            style: AppText.body(size: 12, color: AppColors.paper.withValues(alpha: 0.85)).copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegionalLawExplorerScreen()),
            ),
            icon: const Icon(LucideIcons.map, size: 15, color: AppColors.ink),
            label: Text('Open full map', style: AppText.body(size: 12, weight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paper,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
