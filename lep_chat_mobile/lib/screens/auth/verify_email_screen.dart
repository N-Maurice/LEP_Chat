import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// Shown while status == AuthStatus.emailUnverified. Firebase sends and hosts
/// the verification link itself (Authentication > Templates in the Firebase
/// Console) — this screen just waits for the user to click it.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final email = auth.firebaseUser?.email ?? 'your email address';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.brassSoft, borderRadius: BorderRadius.circular(22)),
                child: const Icon(LucideIcons.mailCheck, size: 38, color: AppColors.oxblood),
              ),
              const SizedBox(height: 24),
              Text('Verify your email', style: AppText.display(size: 22, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                "We've sent a verification link to",
                textAlign: TextAlign.center,
                style: AppText.body(size: 13, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 2),
              Text(email, style: AppText.mono(size: 13, weight: FontWeight.w700, color: AppColors.oxbloodDeep)),
              const SizedBox(height: 4),
              Text(
                'Open it on this device, then come back and tap Continue.',
                textAlign: TextAlign.center,
                style: AppText.body(size: 12.5, color: AppColors.inkSoft).copyWith(height: 1.5),
              ),
              const SizedBox(height: 28),
              if (auth.errorMessage != null) LepErrorBanner(message: auth.errorMessage!),
              LepPrimaryButton(
                label: "I've verified — Continue",
                loading: auth.isBusy,
                onPressed: () => auth.confirmEmailVerified(),
              ),
              const SizedBox(height: 12),
              LepSecondaryButton(
                label: 'Resend email',
                icon: LucideIcons.refreshCw,
                onPressed: auth.isBusy ? null : () => auth.resendVerificationEmail(),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => auth.signOut(),
                child: Text(
                  'Use a different email',
                  style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.slate),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
