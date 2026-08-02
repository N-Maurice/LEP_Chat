import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Screen 5 — Profile. Backed by the real users/me profile fetched at sign-in.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Profile', meta: 'Your account & verification', verified: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.oxblood),
                      child: Text(
                        (profile?.fullName ?? '?').trim().isNotEmpty
                            ? profile!.fullName.trim()[0].toUpperCase()
                            : '?',
                        style: AppText.display(size: 28, weight: FontWeight.w700, color: AppColors.paper),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(profile?.fullName ?? 'Unknown', style: AppText.display(size: 18, weight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  if (profile?.username != null)
                    Center(
                      child: Text('@${profile!.username}', style: AppText.mono(size: 12, color: AppColors.slate)),
                    ),
                  const SizedBox(height: 24),
                  _InfoRow(icon: LucideIcons.mail, label: 'Email', value: profile?.email ?? auth.firebaseUser?.email ?? '—'),
                  _InfoRow(icon: LucideIcons.phone, label: 'Phone', value: profile?.phoneNumber ?? 'Not provided'),
                  _InfoRow(icon: LucideIcons.globe, label: 'Jurisdiction', value: profile?.jurisdiction ?? 'Not provided'),
                  _InfoRow(icon: LucideIcons.idCard, label: 'National ID', value: profile?.nationalId ?? 'Not provided'),
                  const SizedBox(height: 24),
                  LepSecondaryButton(
                    label: 'Sign Out',
                    icon: LucideIcons.logOut,
                    onPressed: () => auth.signOut(),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.paperDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.oxblood),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.mono(size: 10, color: AppColors.slate)),
                Text(value, style: AppText.body(size: 13, weight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
