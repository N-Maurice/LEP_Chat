import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../models/api_models.dart';
import '../services/case_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const _caseCategories = [
  'Labour Dispute',
  'Land Dispute',
  'Family Law',
  'Business / Contract',
  'Consumer Complaint',
  'Other',
];

/// Submit a Case — reached from the Cases tab. Creates a case via POST /cases,
/// then uploads any attached evidence, and hands the caller back the created
/// ApiCase so it can be opened immediately in CaseDetailScreen.
class SubmitCaseScreen extends StatefulWidget {
  final CaseApiService? caseApi;
  const SubmitCaseScreen({super.key, this.caseApi});

  @override
  State<SubmitCaseScreen> createState() => _SubmitCaseScreenState();
}

class _SubmitCaseScreenState extends State<SubmitCaseScreen> {
  late final CaseApiService _caseApi = widget.caseApi ?? CaseApiService(ApiClient());
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  String _category = _caseCategories.first;
  final List<PlatformFile> _evidence = [];
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final result = await FilePicker.pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() => _evidence.addAll(result.files));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final created = await _caseApi.createCase(
        title: _title.text.trim(),
        category: _category,
        description: _description.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      );
      var latest = created;
      for (final file in _evidence) {
        if (file.bytes == null) continue;
        latest = await _caseApi.uploadEvidence(created.id, bytes: file.bytes!, filename: file.name);
      }
      if (!mounted) return;
      Navigator.of(context).pop<ApiCase>(latest);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Could not submit this case. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Submit a Case', meta: 'Track it from the Cases tab once filed'),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    LepFormField(
                      label: 'Case title',
                      controller: _title,
                      hint: 'e.g. Unpaid overtime dispute',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Give this case a title' : null,
                    ),
                    const SizedBox(height: 14),
                    const SectionLabel('Category'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _category,
                          isExpanded: true,
                          icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.slate),
                          style: AppText.body(size: 13.5),
                          items: [for (final c in _caseCategories) DropdownMenuItem(value: c, child: Text(c))],
                          onChanged: (v) => v != null ? setState(() => _category = v) : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LepFormField(
                      label: 'Location (optional)',
                      controller: _location,
                      hint: 'District, sector, cell…',
                      suffixIcon: const Icon(LucideIcons.mapPin, size: 16, color: AppColors.slate),
                    ),
                    const SizedBox(height: 14),
                    const SectionLabel('Description'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _description,
                      maxLines: 5,
                      style: AppText.body(size: 13),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Describe the case' : null,
                      decoration: InputDecoration(
                        hintText: 'What happened, who was involved, and any specific dates…',
                        hintStyle: AppText.body(size: 12.5, color: AppColors.slate),
                        filled: true,
                        fillColor: AppColors.paper,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.oxblood, width: 1.4)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('Evidence (optional)'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickEvidence,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.paperDim,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          children: [
                            const Icon(LucideIcons.upload, size: 22, color: AppColors.oxblood),
                            const SizedBox(height: 8),
                            Text('Tap to attach files', style: AppText.body(size: 12.5, weight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Any format — photos, PDFs, audio, video', style: AppText.body(size: 11, color: AppColors.slate)),
                          ],
                        ),
                      ),
                    ),
                    if (_evidence.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      for (final file in _evidence)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.paperclip, size: 14, color: AppColors.slate),
                              const SizedBox(width: 8),
                              Expanded(child: Text(file.name, style: AppText.mono(size: 11.5, color: AppColors.inkSoft), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    LepPrimaryButton(
                      label: 'Submit Case',
                      icon: LucideIcons.circleCheck,
                      loading: _submitting,
                      onPressed: _submit,
                    ),
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
