import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class _JurisdictionLink {
  final String title;
  final String meta;
  final IconData icon;
  const _JurisdictionLink({required this.title, required this.meta, required this.icon});
}

const _rwandaLinks = [
  _JurisdictionLink(title: 'Constitution', meta: 'Latest amendment: 2023', icon: LucideIcons.bookOpen),
  _JurisdictionLink(title: 'Labour Laws', meta: 'Employment act & regulations', icon: LucideIcons.landmark),
  _JurisdictionLink(title: 'Land Laws', meta: 'Ownership & title research', icon: LucideIcons.mapPin),
];

/// Screen — Regional Law Explorer, reached from the Research Hub's "Open full
/// map" card. No interactive mapping library is wired up yet, so this shows
/// the same jurisdiction detail the mockup's map pin reveals, without a real
/// tappable map — an honest static stand-in rather than a fake interactive one.
class RegionalLawExplorerScreen extends StatelessWidget {
  const RegionalLawExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Regional Law Explorer', meta: 'East African Community (EAC)'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.paperDim,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.mapPin, size: 15, color: AppColors.oxblood),
                          const SizedBox(width: 8),
                          Text('Rwanda selected — 53 more jurisdictions coming soon', style: AppText.body(size: 11.5, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF20603D), Color(0xFFF7D117), Color(0xFF00A1DE)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.4, 0.4, 0.4],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rwanda', style: AppText.display(size: 19, weight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  const VerifiedStamp(small: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        for (final link in _rwandaLinks) ...[
                          _LinkRow(link: link),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 8),
                        LepPrimaryButton(label: 'Deep Dive Into Research', icon: LucideIcons.search, onPressed: () => Navigator.of(context).pop()),
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

class _LinkRow extends StatelessWidget {
  final _JurisdictionLink link;
  const _LinkRow({required this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paperDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.brassSoft, borderRadius: BorderRadius.circular(9)),
            child: Icon(link.icon, size: 15, color: AppColors.oxblood),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(link.title, style: AppText.body(size: 13, weight: FontWeight.w700)),
                Text(link.meta, style: AppText.body(size: 11, color: AppColors.inkSoft)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.slate),
        ],
      ),
    );
  }
}
