import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'theme/app_theme.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/case_tracking_screen.dart';
import 'screens/research_hub_screen.dart';

void main() {
  runApp(const LepApp());
}

/// LEP — Legal Ecosystem Platform.
/// App entry point: wires up the "Docket & Ledger" theme and the bottom
/// navigation shell that hosts the three live modules built so far
/// (AI Legal Assistant, Case Tracking, Legal Research Hub). Remaining
/// modules — Lawyer & Firm Portal, Document Management, Dispute
/// Resolution, Compliance Monitoring, Gov Services Integration, and
/// Notifications — are stubbed as "coming soon" tabs below.
class LepApp extends StatelessWidget {
  const LepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LEP — Legal Ecosystem Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.oxblood,
          primary: AppColors.oxblood,
          surface: AppColors.paper,
        ),
      ),
      home: const LepHomeShell(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class LepHomeShell extends StatefulWidget {
  const LepHomeShell({super.key});

  @override
  State<LepHomeShell> createState() => _LepHomeShellState();
}

class _LepHomeShellState extends State<LepHomeShell> {
  int _index = 0;

  static const List<Widget> _screens = [
    AiAssistantScreen(),
    ResearchHubScreen(),
    CaseTrackingScreen(),
    _ComingSoonScreen(title: 'Community'),
    _ComingSoonScreen(title: 'Profile'),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(LucideIcons.home, 'Home'),
    _NavItem(LucideIcons.bot, 'AI Search'),
    _NavItem(LucideIcons.scale, 'Cases'),
    _NavItem(LucideIcons.users, 'Community'),
    _NavItem(LucideIcons.user, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.paper,
        selectedItemColor: AppColors.oxblood,
        unselectedItemColor: AppColors.slate,
        selectedLabelStyle: AppText.body(size: 9.5, weight: FontWeight.w700),
        unselectedLabelStyle: AppText.body(size: 9.5, weight: FontWeight.w500),
        items: [
          for (final item in _navItems)
            BottomNavigationBarItem(icon: Icon(item.icon), label: item.label),
        ],
      ),
    );
  }
}

/// Placeholder for modules not yet built, so the nav bar reflects the
/// full 9-module vision without dead taps.
class _ComingSoonScreen extends StatelessWidget {
  final String title;
  const _ComingSoonScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.hammer, size: 28, color: AppColors.brass),
            const SizedBox(height: 10),
            Text('$title module', style: AppText.display(size: 17, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('In the build queue — coming soon.', style: AppText.body(size: 12.5, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}
