import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../widgets/shared_widgets.dart';

/// Screen 2 — Case Tracking.
/// Data source: [primaryCase] / [otherCases] / [activeCaseCount] in
/// data/mock_data.dart. Point these at GET /api/v1/cases?citizenId=:id
/// to go live.
class CaseTrackingScreen extends StatelessWidget {
  const CaseTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Legal Ecosystem', meta: 'Case Tracking · $activeCaseCount active'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const _SearchBar(),
                  const SizedBox(height: 16),
                  const SectionLabel('Primary case'),
                  const SizedBox(height: 8),
                  const _PrimaryCaseCard(),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionLabel('Case timeline'),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: Text(
                          'View all',
                          style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.oxblood),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _CaseTimeline(),
                  const SizedBox(height: 4),
                  const SectionLabel('Other cases'),
                  const SizedBox(height: 8),
                  for (final other in otherCases) _OtherCaseRow(item: other),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

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
          const Icon(LucideIcons.slidersHorizontal, size: 16, color: AppColors.slate),
        ],
      ),
    );
  }
}

class _PrimaryCaseCard extends StatelessWidget {
  const _PrimaryCaseCard();

  @override
  Widget build(BuildContext context) {
    const c = primaryCase;
    return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title, style: AppText.display(size: 17, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Ref: ${c.ref}', style: AppText.mono(size: 11, color: AppColors.slate)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(c.status, style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
            child: Row(
              children: [
                Expanded(
                  child: _MetaBlock(icon: LucideIcons.calendar, label: 'Next hearing', value: c.nextHearing),
                ),
                Expanded(
                  child: _MetaBlock(icon: LucideIcons.landmark, label: 'Institution', value: c.institution),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: c.partiesCount * 18.0 + 26,
                height: 26,
                child: Stack(
                  children: [
                    for (int i = 0; i < c.partiesCount; i++)
                      Positioned(
                        left: i * 18.0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.brassSoft,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.paper, width: 2),
                          ),
                        ),
                      ),
                    Positioned(
                      left: c.partiesCount * 18.0,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.paperDim,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.paper, width: 2),
                        ),
                        child: Text(
                          '+${c.extraParties}',
                          style: AppText.body(size: 9.5, weight: FontWeight.w700, color: AppColors.inkSoft),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                icon: const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.oxblood),
                label: Text(
                  'View details',
                  style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.oxblood),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.upload, size: 16, color: AppColors.paper),
              label: Text(
                'Upload new evidence',
                style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.paper),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.oxblood,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaBlock({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.slate),
            const SizedBox(width: 5),
            Text(label, style: AppText.body(size: 10.5, color: AppColors.slate)),
          ],
        ),
        const SizedBox(height: 3),
        Text(value, style: AppText.body(size: 12.5, weight: FontWeight.w600)),
      ],
    );
  }
}

class _CaseTimeline extends StatelessWidget {
  const _CaseTimeline();

  @override
  Widget build(BuildContext context) {
    final items = primaryCase.timeline;
    return Column(
      children: [
        for (int i = 0; i < items.length; i++)
          _TimelineRow(item: items[i], isLast: i == items.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final CaseTimelineItem item;
  final bool isLast;
  const _TimelineRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isDone = item.state == TimelineState.done;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.oxblood : AppColors.paperDim,
                  shape: BoxShape.circle,
                  border: isDone ? null : Border.all(color: AppColors.oxblood, width: 2),
                ),
                child: isDone
                    ? const Icon(LucideIcons.checkCircle2, size: 13, color: AppColors.paper)
                    : Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: AppColors.oxblood, shape: BoxShape.circle),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.line,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.date,
                    style: AppText.mono(
                      size: 10.5,
                      weight: item.state == TimelineState.upcoming ? FontWeight.w700 : FontWeight.w500,
                      color: item.state == TimelineState.upcoming ? AppColors.oxblood : AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(item.title, style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: AppText.body(size: 12, color: AppColors.inkSoft).copyWith(height: 1.45),
                  ),
                  if (item.attachment != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.paperDim,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.fileText, size: 13, color: AppColors.inkSoft),
                          const SizedBox(width: 6),
                          Text(item.attachment!, style: AppText.mono(size: 11, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherCaseRow extends StatelessWidget {
  final OtherCase item;
  const _OtherCaseRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, size: 17, color: AppColors.oxblood),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppText.body(size: 12.5, weight: FontWeight.w700)),
                Text('Status: ${item.status}', style: AppText.body(size: 11, color: AppColors.slate)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.ink),
        ],
      ),
    );
  }
}
