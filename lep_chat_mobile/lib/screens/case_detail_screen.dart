import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../models/api_models.dart';
import '../services/case_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

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

/// Case / Report detail — shows live status and evidence, and lets the citizen
/// attach more evidence after the fact (e.g. new documents from a hearing).
class CaseDetailScreen extends StatefulWidget {
  final ApiCase initialCase;
  final CaseApiService? caseApi;
  const CaseDetailScreen({super.key, required this.initialCase, this.caseApi});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late final CaseApiService _caseApi = widget.caseApi ?? CaseApiService(ApiClient());
  late ApiCase _case = widget.initialCase;
  bool _uploading = false;

  Future<void> _addEvidence() async {
    final result = await FilePicker.pickFiles(allowMultiple: true, withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      var latest = _case;
      for (final file in result.files) {
        if (file.bytes == null) continue;
        latest = await _caseApi.uploadEvidence(_case.id, bytes: file.bytes!, filename: file.name);
      }
      if (!mounted) return;
      setState(() => _case = latest);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Could not upload evidence. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_case.status);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: _case.ref, meta: _case.isViolationReport ? 'Violation Report' : 'Case Tracking'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(_case.title, style: AppText.display(size: 17, weight: FontWeight.w600)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                                  const SizedBox(width: 5),
                                  Text(
                                    _statusLabels[_case.status] ?? _case.status,
                                    style: AppText.body(size: 11, weight: FontWeight.w700, color: statusColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(_case.category, style: AppText.mono(size: 11, color: AppColors.slate)),
                        if (_case.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, size: 12, color: AppColors.slate),
                              const SizedBox(width: 4),
                              Text(_case.location!, style: AppText.body(size: 11.5, color: AppColors.inkSoft)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(_case.description, style: AppText.body(size: 13).copyWith(height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionLabel('Evidence'),
                      TextButton.icon(
                        onPressed: _uploading ? null : _addEvidence,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        icon: _uploading
                            ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.oxblood))
                            : const Icon(LucideIcons.upload, size: 14, color: AppColors.oxblood),
                        label: Text('Add', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.oxblood)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_case.evidence.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.paperDim,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text('No evidence uploaded yet.', style: AppText.body(size: 12.5, color: AppColors.inkSoft)),
                    )
                  else
                    for (final e in _case.evidence)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.fileText, size: 16, color: AppColors.oxblood),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(e.filename, style: AppText.body(size: 12.5, weight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
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
