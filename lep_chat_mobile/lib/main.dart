import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'core/auth_controller.dart';
import 'core/env.dart';
import 'firebase_options.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/case_tracking_screen.dart';
import 'screens/community_screen.dart';
import 'screens/home_screen.dart';
import 'screens/legal_education_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const LepApp(),
    ),
  );
}

/// LEP — Legal Ecosystem Platform.
/// App entry point: wires up the "Docket & Ledger" theme and hands control to
/// [AuthGate], which switches between the auth funnel (onboarding, sign in,
/// sign up, email verification, profile completion) and the signed-in home
/// shell purely off [AuthController.status].
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
      home: const AuthGate(),
    );
  }
}

enum _SignedOutView { onboarding, signIn, signUp }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  _SignedOutView _view = _SignedOutView.onboarding;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const _SplashScreen();

      case AuthStatus.signedOut:
        switch (_view) {
          case _SignedOutView.onboarding:
            return OnboardingScreen(
              onGetStarted: () => setState(() => _view = _SignedOutView.signUp),
              onSignIn: () => setState(() => _view = _SignedOutView.signIn),
            );
          case _SignedOutView.signIn:
            return SignInScreen(onCreateAccount: () => setState(() => _view = _SignedOutView.signUp));
          case _SignedOutView.signUp:
            return SignUpScreen(onSignIn: () => setState(() => _view = _SignedOutView.signIn));
        }

      case AuthStatus.emailUnverified:
        return const VerifyEmailScreen();

      case AuthStatus.profileIncomplete:
        return const CompleteProfileScreen();

      case AuthStatus.signedIn:
        return const LepHomeShell();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(child: CircularProgressIndicator(color: AppColors.oxblood)),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

/// The signed-in shell: bottom nav across Home, Talk with Assistant (the AI
/// Legal Assistant chat), Cases, Education (courses + legal research), and
/// Profile. Community (direct messages) is reached from Home's Quick Actions.
class LepHomeShell extends StatefulWidget {
  const LepHomeShell({super.key});

  @override
  State<LepHomeShell> createState() => _LepHomeShellState();
}

class _LepHomeShellState extends State<LepHomeShell> {
  int _index = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(LucideIcons.home, 'Home'),
    _NavItem(LucideIcons.messageCircle, 'Talk with Assistant'),
    _NavItem(LucideIcons.scale, 'Cases'),
    _NavItem(LucideIcons.graduationCap, 'Education'),
    _NavItem(LucideIcons.user, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToTab: (i) => setState(() => _index = i),
        onOpenCommunity: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CommunityScreen()),
        ),
      ),
      const AiAssistantScreen(),
      const CaseTrackingScreen(),
      const LegalEducationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
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
