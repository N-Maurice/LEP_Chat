import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/auth_controller.dart';
import '../../data/mock_data.dart' show jurisdictionOptions;
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// Shown when status == AuthStatus.profileIncomplete with no pending signup
/// data to auto-submit — the Google sign-in path (already verified, but the
/// backend has no users/ document yet), or a resumed session mid-signup.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _nationalId = TextEditingController();
  String _jurisdiction = jurisdictionOptions.first;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().firebaseUser;
    _fullName = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _phone.dispose();
    _nationalId.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    await auth.completeProfile(
      fullName: _fullName.text.trim(),
      username: _username.text.trim(),
      phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      jurisdiction: _jurisdiction,
      nationalId: _nationalId.text.trim().isEmpty ? null : _nationalId.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.oxblood, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(LucideIcons.userCircle, size: 24, color: AppColors.paper),
                ),
                const SizedBox(height: 18),
                Text('Complete your profile', style: AppText.display(size: 22, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  "You're verified — just a few more details before you're set up.",
                  style: AppText.body(size: 12.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 24),
                if (auth.errorMessage != null) LepErrorBanner(message: auth.errorMessage!),
                LepFormField(
                  label: 'Full name',
                  controller: _fullName,
                  hint: 'Johnathan Doe',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 14),
                LepFormField(
                  label: 'Username',
                  controller: _username,
                  hint: '@jdoe_legal',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Choose a username' : null,
                ),
                const SizedBox(height: 14),
                LepFormField(
                  label: 'Phone number',
                  controller: _phone,
                  hint: '+250 700 000 000',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Jurisdiction / Country'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _jurisdiction,
                          isExpanded: true,
                          icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.slate),
                          style: AppText.body(size: 13.5),
                          items: [
                            for (final option in jurisdictionOptions)
                              DropdownMenuItem(value: option, child: Text(option)),
                          ],
                          onChanged: (v) => v != null ? setState(() => _jurisdiction = v) : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LepFormField(label: 'National ID / Passport ID', controller: _nationalId, hint: 'Enter ID number'),
                const SizedBox(height: 24),
                LepPrimaryButton(
                  label: 'Continue',
                  icon: LucideIcons.arrowRight,
                  loading: auth.isBusy,
                  onPressed: () => _submit(auth),
                ),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () => auth.signOut(),
                    child: Text('Sign out', style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.slate)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
