import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'report_violation_screen.dart';

/// Screen 0 — Home dashboard. Quick actions jump either to a sibling bottom-nav
/// tab (via [onNavigateToTab]) or push a standalone screen (Legal Education,
/// Report a Violation). A couple of actions (Find Legal Help, Book
/// Consultation) don't have a dedicated screen yet, so they show a
/// "coming soon" toast rather than a dead tap.
class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onOpenCommunity;

  const HomeScreen({super.key, required this.onNavigateToTab, required this.onOpenCommunity});

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is in the build queue — coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final firstName = (profile?.fullName ?? 'there').split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 18 ? 'Good afternoon' : 'Good evening');

    final quickActions = <_QuickActionItem>[
      _QuickActionItem(label: 'Know Your Rights', icon: LucideIcons.shieldCheck, onTap: () => onNavigateToTab(3)),
      _QuickActionItem(label: 'Search Laws', icon: LucideIcons.search, onTap: () => onNavigateToTab(3)),
      _QuickActionItem(
        label: 'Report a Violation',
        icon: LucideIcons.circleAlert,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportViolationScreen())),
      ),
      _QuickActionItem(label: 'Track a Case', icon: LucideIcons.target, onTap: () => onNavigateToTab(2)),
      _QuickActionItem(label: 'Find Legal Help', icon: LucideIcons.headset, onTap: () => _comingSoon(context, 'Find Legal Help')),
      _QuickActionItem(label: 'Legal Education', icon: LucideIcons.graduationCap, onTap: () => onNavigateToTab(3)),
      _QuickActionItem(label: 'Community Discussions', icon: LucideIcons.users, onTap: onOpenCommunity),
    ];

    return Scaffold(
      backgroundColor: AppColors.paper,
      floatingActionButton: FloatingActionButton(
        onPressed: () => onNavigateToTab(1),
        backgroundColor: AppColors.oxblood,
        child: const Icon(LucideIcons.messageCircle, color: AppColors.paper),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.oxblood, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(LucideIcons.scale, size: 16, color: AppColors.paper),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Legal Ecosystem', style: AppText.display(size: 16, weight: FontWeight.w700)),
                ),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.paperDim,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(LucideIcons.bell, size: 16, color: AppColors.ink),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.oxblood),
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                    style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.paper),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
                      onTap: () => onNavigateToTab(1),
                      readOnly: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search legal resources…',
                        hintStyle: AppText.body(size: 13, color: AppColors.slate),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.oxblood, AppColors.oxbloodDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$greeting, $firstName.', style: AppText.display(size: 19, weight: FontWeight.w700, color: AppColors.paper)),
                  const SizedBox(height: 4),
                  Text('Your Rights, Protected.', style: AppText.body(size: 12.5, color: AppColors.paper.withValues(alpha: 0.9))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.paper.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.badgeCheck, size: 13, color: AppColors.paper),
                        const SizedBox(width: 5),
                        Text('Verified Citizen', style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: AppColors.paper)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paperDim,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.brassSoft, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(LucideIcons.bookOpen, size: 18, color: AppColors.oxblood),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Knowledge is Power', style: AppText.display(size: 14.5, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'Explore your rights in Rwanda and stay informed about the latest legal protections.',
                          style: AppText.body(size: 11.5, color: AppColors.inkSoft).copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Quick Actions'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [for (final action in quickActions) _QuickActionTile(action: action)],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionLabel('Trending Legal Topics'),
                Text('View All', style: AppText.body(size: 11.5, weight: FontWeight.w700, color: AppColors.oxblood)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 236,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _trendingTopics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _TrendingCard(topic: _trendingTopics[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingTopic {
  final String badge;
  final String title;
  final String summary;
  final String meta;
  final IconData icon;
  const _TrendingTopic({
    required this.badge,
    required this.title,
    required this.summary,
    required this.meta,
    required this.icon,
  });
}

const _trendingTopics = <_TrendingTopic>[
  _TrendingTopic(
    badge: 'UPDATE',
    title: 'New Labour Law Updates 2024',
    summary: "Understand the critical changes in Rwanda's latest employment regulations.",
    meta: 'Oct 24, 2023',
    icon: LucideIcons.fileText,
  ),
  _TrendingTopic(
    badge: 'GUIDE',
    title: 'Land Dispute Resolution',
    summary: 'A step-by-step guide for landowners navigating boundary disagreements.',
    meta: '1.2k views',
    icon: LucideIcons.map,
  ),
  _TrendingTopic(
    badge: 'GUIDE',
    title: 'Business Compliance Checklist',
    summary: 'What every registered company needs to file this quarter to stay compliant.',
    meta: '860 views',
    icon: LucideIcons.building2,
  ),
  _TrendingTopic(
    badge: 'RIGHTS',
    title: 'Protections Against GBV',
    summary: 'Know the legal protections available and how to report incidents safely.',
    meta: '2.1k views',
    icon: LucideIcons.handHeart,
  ),
  _TrendingTopic(
    badge: 'UPDATE',
    title: 'Family Law: Custody Rights',
    summary: 'Recent amendments affecting child custody arrangements after separation.',
    meta: 'Sep 30, 2023',
    icon: LucideIcons.users,
  ),
];

class _QuickActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickActionItem({required this.label, required this.icon, required this.onTap});
}

class _QuickActionTile extends StatelessWidget {
  final _QuickActionItem action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.brassSoft, borderRadius: BorderRadius.circular(10)),
              child: Icon(action.icon, size: 16, color: AppColors.oxblood),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: AppText.body(size: 12, weight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final _TrendingTopic topic;
  const _TrendingCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder — swap for a real Image.network/asset once
          // article artwork is available; the icon + gradient stand in for now.
          Container(
            height: 96,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.ink, AppColors.inkSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Icon(LucideIcons.image, size: 26, color: AppColors.paper.withValues(alpha: 0.25)),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Icon(topic.icon, size: 30, color: AppColors.paper.withValues(alpha: 0.45)),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: LepPill(label: topic.badge, variant: PillVariant.tag),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: AppText.display(size: 14, weight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topic.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(size: 11.5, color: AppColors.inkSoft).copyWith(height: 1.4),
                      ),
                    ],
                  ),
                  Text(topic.meta, style: AppText.mono(size: 10.5, color: AppColors.slate)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
