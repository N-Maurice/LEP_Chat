import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../models/api_models.dart';
import '../services/case_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'case_detail_screen.dart';
import 'submit_case_screen.dart';

const _statusLabels = {
  'submitted': 'Submitted',
  'under_review': 'Under Review',
  'in_progress': 'In Progress',
  'resolved': 'Resolved',
  'closed': 'Closed',
};

Color _statusColor(String status) {
  switch (status) {
    case 'resolved':
      return AppColors.success;
    case 'closed':
      return AppColors.slate;
    case 'in_progress':
    case 'under_review':
      return AppColors.brass;
    default:
      return AppColors.oxblood;
  }
}

/// Screen — Case Tracking. Lists every case and violation report the citizen has
/// filed (both live in the same /cases collection — see api_lep_chat/app/routers/cases.py),
/// lets them submit a new case, and opens each one to see status + evidence.
class CaseTrackingScreen extends StatefulWidget {
  final CaseApiService? caseApi;
  const CaseTrackingScreen({super.key, this.caseApi});

  @override
  State<CaseTrackingScreen> createState() => _CaseTrackingScreenState();
}

class _CaseTrackingScreenState extends State<CaseTrackingScreen> {
  late final CaseApiService _caseApi = widget.caseApi ?? CaseApiService(ApiClient());
  final _searchController = TextEditingController();

  List<ApiCase> _cases = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cases = await _caseApi.listCases();
      if (!mounted) return;
      setState(() {
        _cases = cases;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load your cases. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _openSubmitCase() async {
    final created = await Navigator.of(context).push<ApiCase>(
      MaterialPageRoute(builder: (_) => SubmitCaseScreen(caseApi: _caseApi)),
    );
    if (created == null) return;
    await _load();
    if (!mounted) return;
    _openDetail(created);
  }

  Future<void> _openDetail(ApiCase item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaseDetailScreen(initialCase: item, caseApi: _caseApi)),
    );
    _load();
  }

  List<ApiCase> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _cases;
    return _cases.where((c) => c.title.toLowerCase().contains(query) || c.ref.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      floatingActionButton: FloatingActionButton(
        onPressed: _openSubmitCase,
        backgroundColor: AppColors.oxblood,
        child: const Icon(LucideIcons.plus, color: AppColors.paper),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Legal Ecosystem', meta: 'Case Tracking · ${_cases.length} filed'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.oxblood))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _SearchBar(controller: _searchController, onChanged: (_) => setState(() {})),
                          const SizedBox(height: 16),
                          if (_error != null) LepErrorBanner(message: _error!),
                          if (_filtered.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.paperDim,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Column(
                                children: [
                                  const Icon(LucideIcons.folderOpen, size: 24, color: AppColors.slate),
                                  const SizedBox(height: 8),
                                  Text(
                                    _cases.isEmpty
                                        ? 'No cases yet. Tap + to submit one, or file a report from Home.'
                                        : 'No cases match your search.',
                                    textAlign: TextAlign.center,
                                    style: AppText.body(size: 12.5, color: AppColors.inkSoft),
                                  ),
                                ],
                              ),
                            )
                          else
                            for (final item in _filtered) _CaseRow(item: item, onTap: () => _openDetail(item)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              onChanged: onChanged,
              style: AppText.body(size: 12.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: 'Search by case ID or name…',
                hintStyle: AppText.body(size: 12.5, color: AppColors.slate),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseRow extends StatelessWidget {
  final ApiCase item;
  final VoidCallback onTap;
  const _CaseRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(11)),
              child: Icon(
                item.isViolationReport ? LucideIcons.circleAlert : LucideIcons.scale,
                size: 17,
                color: AppColors.oxblood,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppText.body(size: 13, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${item.ref} · ${item.category}', style: AppText.mono(size: 10.5, color: AppColors.slate)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
              child: Text(
                _statusLabels[item.status] ?? item.status,
                style: AppText.body(size: 10.5, weight: FontWeight.w700, color: statusColor),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}
