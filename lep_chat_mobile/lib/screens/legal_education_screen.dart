import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../models/api_models.dart';
import '../services/education_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'course_module_screen.dart';

/// Screen — Legal Education. Courses are generated server-side per track from the
/// actual ingested Firestore document chunks (embedding + vector search + Gemini),
/// grounded and cached — see api_lep_chat/app/agents/course_agent.py.
class LegalEducationScreen extends StatefulWidget {
  final EducationApiService? educationApi;
  const LegalEducationScreen({super.key, this.educationApi});

  @override
  State<LegalEducationScreen> createState() => _LegalEducationScreenState();
}

class _LegalEducationScreenState extends State<LegalEducationScreen> {
  late final EducationApiService _educationApi = widget.educationApi ?? EducationApiService(ApiClient());

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
            Expanded(
              child: _loadingTracks
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
                    ),
            ),
          ],
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
