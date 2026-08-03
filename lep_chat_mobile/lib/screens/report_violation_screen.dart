import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../services/case_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class _ViolationCategory {
  final String label;
  final IconData icon;
  const _ViolationCategory(this.label, this.icon);
}

const _categories = [
  _ViolationCategory('Corruption', LucideIcons.landmark),
  _ViolationCategory('Labour Abuse', LucideIcons.users2),
  _ViolationCategory('Fraud', LucideIcons.banknote),
  _ViolationCategory('GBV', LucideIcons.handHeart),
  _ViolationCategory('Environment', LucideIcons.trees),
  _ViolationCategory('Other', LucideIcons.ellipsis),
];

/// Screen — Report a Violation. A 3-step wizard (Incident / Location / Evidence)
/// that submits to the same /cases backend as Case Tracking, tagged
/// case_type=violation_report, so a filed report shows up in "Track a Case" too.
class ReportViolationScreen extends StatefulWidget {
  final CaseApiService? caseApi;
  const ReportViolationScreen({super.key, this.caseApi});

  @override
  State<ReportViolationScreen> createState() => _ReportViolationScreenState();
}

class _ReportViolationScreenState extends State<ReportViolationScreen> {
  late final CaseApiService _caseApi = widget.caseApi ?? CaseApiService(ApiClient());

  int _step = 0;
  String? _category;
  final _description = TextEditingController();
  final _location = TextEditingController();
  final List<PlatformFile> _evidence = [];
  bool _submitting = false;

  @override
  void dispose() {
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() => _evidence.addAll(result.files));
  }

  void _next() {
    if (_step == 0 && (_category == null || _description.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category and describe the incident.')),
      );
      return;
    }
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final created = await _caseApi.createCase(
        caseType: 'violation_report',
        title: '$_category violation report',
        category: _category!,
        description: _description.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      );
      for (final file in _evidence) {
        if (file.bytes == null) continue;
        await _caseApi.uploadEvidence(created.id, bytes: file.bytes!, filename: file.name);
      }
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Could not submit this report. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Report submitted', style: AppText.display(size: 17, weight: FontWeight.w700)),
        content: Text(
          'Your report has been recorded and added to your tracked cases. You can follow its '
          'status from the Cases tab.',
          style: AppText.body(size: 12.5, color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Done', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.oxblood)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: const BoxDecoration(color: AppColors.paper, border: Border(bottom: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(LucideIcons.arrowLeft, size: 17, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.oxblood, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(LucideIcons.scale, size: 18, color: AppColors.paper),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Report a Violation', style: AppText.display(size: 16.5, weight: FontWeight.w600))),
                  const Icon(LucideIcons.bell, size: 18, color: AppColors.ink),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: _StepIndicator(step: _step),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  if (_step == 0) _IncidentStep(category: _category, onCategory: (c) => setState(() => _category = c), description: _description),
                  if (_step == 1) _LocationStep(controller: _location),
                  if (_step == 2) _EvidenceStep(evidence: _evidence, onAdd: _pickEvidence),
                  const SizedBox(height: 20),
                  LepPrimaryButton(
                    label: _step < 2 ? 'Continue' : 'Submit Report',
                    icon: _step < 2 ? LucideIcons.arrowRight : LucideIcons.circleCheck,
                    loading: _submitting,
                    onPressed: _next,
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

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  static const _labels = ['Incident', 'Location', 'Evidence'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= step ? AppColors.oxblood : AppColors.paperDim,
                  border: Border.all(color: i <= step ? AppColors.oxblood : AppColors.line),
                ),
                child: Text(
                  '${i + 1}',
                  style: AppText.body(size: 13, weight: FontWeight.w700, color: i <= step ? AppColors.paper : AppColors.slate),
                ),
              ),
              const SizedBox(height: 6),
              Text(_labels[i], style: AppText.mono(size: 9.5, weight: FontWeight.w600, color: i == step ? AppColors.oxblood : AppColors.slate)),
            ],
          ),
          if (i < 2)
            Container(width: 40, height: 1.4, margin: const EdgeInsets.only(bottom: 18), color: i < step ? AppColors.oxblood : AppColors.line),
        ],
      ],
    );
  }
}

class _IncidentStep extends StatelessWidget {
  final String? category;
  final ValueChanged<String> onCategory;
  final TextEditingController description;

  const _IncidentStep({required this.category, required this.onCategory, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Category', style: AppText.display(size: 17, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('What type of violation are you reporting?', style: AppText.body(size: 12, color: AppColors.inkSoft)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            for (final c in _categories)
              InkWell(
                onTap: () => onCategory(c.label),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: category == c.label ? AppColors.oxblood.withValues(alpha: 0.06) : AppColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: category == c.label ? AppColors.oxblood : AppColors.line, width: category == c.label ? 1.4 : 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icon, size: 20, color: AppColors.oxblood),
                      const SizedBox(height: 6),
                      Text(c.label, style: AppText.body(size: 12, weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionLabel('Description of incident'),
        const SizedBox(height: 8),
        TextField(
          controller: description,
          maxLines: 5,
          style: AppText.body(size: 13),
          decoration: InputDecoration(
            hintText: 'Please provide detailed information about what happened, who was involved, and any specific dates…',
            hintStyle: AppText.body(size: 12.5, color: AppColors.slate),
            filled: true,
            fillColor: AppColors.paper,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.oxblood, width: 1.4)),
          ),
        ),
      ],
    );
  }
}

class _LocationStep extends StatelessWidget {
  final TextEditingController controller;
  const _LocationStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where did this happen?', style: AppText.display(size: 17, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Approximate location helps route your report to the right authority.', style: AppText.body(size: 12, color: AppColors.inkSoft)),
        const SizedBox(height: 16),
        LepFormField(label: 'Location', controller: controller, hint: 'District, sector, cell…', suffixIcon: const Icon(LucideIcons.mapPin, size: 16, color: AppColors.slate)),
      ],
    );
  }
}

class _EvidenceStep extends StatelessWidget {
  final List<PlatformFile> evidence;
  final VoidCallback onAdd;
  const _EvidenceStep({required this.evidence, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attach evidence', style: AppText.display(size: 17, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Optional — photos, documents, or recordings that support your report.', style: AppText.body(size: 12, color: AppColors.inkSoft)),
        const SizedBox(height: 16),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.paperDim,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.upload, size: 24, color: AppColors.oxblood),
                const SizedBox(height: 8),
                Text('Tap to attach files', style: AppText.body(size: 12.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Any format — photos, PDFs, audio, video', style: AppText.body(size: 11, color: AppColors.slate)),
              ],
            ),
          ),
        ),
        if (evidence.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final file in evidence)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.paperclip, size: 14, color: AppColors.slate),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(file.name, style: AppText.mono(size: 11.5, color: AppColors.inkSoft), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
