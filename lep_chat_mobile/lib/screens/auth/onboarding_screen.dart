import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// "Welcome to Digital Justice" — the very first screen a signed-out user sees.
class OnboardingScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const OnboardingScreen({super.key, required this.onGetStarted, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.oxblood, borderRadius: BorderRadius.circular(24)),
                child: const Icon(LucideIcons.shieldCheck, size: 44, color: AppColors.paper),
              ),
              const SizedBox(height: 28),
              Text.rich(
                TextSpan(
                  style: AppText.display(size: 28, weight: FontWeight.w700),
                  children: [
                    const TextSpan(text: 'Welcome to '),
                    TextSpan(text: 'Digital Justice', style: AppText.display(size: 28, weight: FontWeight.w700, color: AppColors.oxblood)),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                'Democratizing legal intelligence for everyone. Empowering citizens '
                'through accessible legal awareness and authoritative guidance.',
                textAlign: TextAlign.center,
                style: AppText.body(size: 13.5, color: AppColors.inkSoft).copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              LepPrimaryButton(label: 'Get Started', icon: LucideIcons.arrowRight, onPressed: onGetStarted),
              const SizedBox(height: 12),
              LepSecondaryButton(label: 'I already have an account', onPressed: onSignIn),
              const Spacer(flex: 2),
              const LepPill(label: 'ENTERPRISE GRADE SECURITY', variant: PillVariant.brass),
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Stat(value: '500k+', label: 'Verified Citizens'),
                  _StatDivider(),
                  _Stat(value: '100%', label: 'Secure Access'),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '© 2024 Legal Ecosystem Platform',
                style: AppText.mono(size: 10, color: AppColors.slate),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.display(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: AppText.body(size: 11, color: AppColors.inkSoft)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: AppColors.line,
    );
  }
}
