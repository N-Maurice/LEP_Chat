import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../widgets/shared_widgets.dart';
import 'regional_law_explorer_screen.dart';

/// Screen 3 — Legal Research Hub.
/// Data source: [researchResults] / [researchCategories] in
/// data/mock_data.dart. Point these at
/// GET /api/v1/research/search?q=&jurisdiction= to go live.
class ResearchHubScreen extends StatefulWidget {
  const ResearchHubScreen({super.key});

  @override
  State<ResearchHubScreen> createState() => _ResearchHubScreenState();
}

class _ResearchHubScreenState extends State<ResearchHubScreen> {
  String _activeCategory = researchCategories.first;

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is in the build queue — coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _comingSoon('Saving custom searches'),
        backgroundColor: AppColors.oxblood,
        child: const Icon(LucideIcons.plus, color: AppColors.paper),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Legal Ecosystem', meta: 'Legal Research Hub'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _SearchRow(onJurisdictionTap: () => _comingSoon('Switching jurisdictions')),
                  const SizedBox(height: 16),
                  const SectionLabel('Popular jurisdictions'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final category in researchCategories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CategoryChip(
                              label: category,
                              active: category == _activeCategory,
                              onTap: () => setState(() => _activeCategory = category),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Showing $researchResultCount results for "$researchQuery"',
                    style: AppText.body(size: 11.5, color: AppColors.slate),
                  ),
                  const SizedBox(height: 12),
                  for (final result in researchResults)
                    _ResultCard(result: result, onComingSoon: _comingSoon),
                  const SizedBox(height: 4),
                  const _ExplorerCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final VoidCallback onJurisdictionTap;
  const _SearchRow({required this.onJurisdictionTap});

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
                  child: TextFormField(
                    initialValue: researchQuery,
                    style: AppText.body(size: 12.5),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.oxblood, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.bot, size: 13, color: AppColors.paper),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onJurisdictionTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.paperDim,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(researchJurisdiction, style: AppText.body(size: 11.5, weight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.oxblood : AppColors.paper,
          border: Border.all(color: active ? AppColors.oxblood : AppColors.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppText.body(size: 12, weight: FontWeight.w600, color: active ? AppColors.paper : AppColors.inkSoft),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ResearchResult result;
  final void Function(String feature) onComingSoon;
  const _ResultCard({required this.result, required this.onComingSoon});

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
                      'AI SUMMARY',
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
                onPressed: () => onComingSoon('Reading the original source'),
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
              _OutlineIconButton(icon: LucideIcons.download, onTap: () => onComingSoon('Downloading results')),
              const SizedBox(width: 8),
              _OutlineIconButton(icon: LucideIcons.bookmark, onTap: () => onComingSoon('Bookmarking results')),
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
