import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// A single course module on its own page, with Previous/Next navigation between
/// the other modules in the same generated course — reached from LegalEducationScreen.
class CourseModuleScreen extends StatefulWidget {
  final EducationCourse course;
  final int initialIndex;
  const CourseModuleScreen({super.key, required this.course, required this.initialIndex});

  @override
  State<CourseModuleScreen> createState() => _CourseModuleScreenState();
}

class _CourseModuleScreenState extends State<CourseModuleScreen> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final modules = widget.course.modules;
    final module = modules[_index];
    final isFirst = _index == 0;
    final isLast = _index == modules.length - 1;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Module ${_index + 1} of ${modules.length}', meta: widget.course.title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  LepPill(label: 'MODULE ${_index + 1}'),
                  const SizedBox(height: 10),
                  Text(module.title, style: AppText.display(size: 20, weight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(
                    module.summary,
                    style: AppText.body(size: 13.5, color: AppColors.inkSoft).copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('Sources'),
                  const SizedBox(height: 10),
                  if (module.citations.isEmpty)
                    Text('No sources cited for this module.', style: AppText.body(size: 12, color: AppColors.slate))
                  else
                    for (final citation in module.citations) ApiCitationBlockWidget(citation: citation),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  if (!isFirst)
                    Expanded(
                      child: LepSecondaryButton(
                        label: 'Previous',
                        icon: LucideIcons.arrowLeft,
                        onPressed: () => setState(() => _index -= 1),
                      ),
                    ),
                  if (!isFirst) const SizedBox(width: 10),
                  Expanded(
                    child: isLast
                        ? LepPrimaryButton(
                            label: 'Finish',
                            icon: LucideIcons.circleCheck,
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        : LepPrimaryButton(
                            label: 'Next',
                            icon: LucideIcons.arrowRight,
                            onPressed: () => setState(() => _index += 1),
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
