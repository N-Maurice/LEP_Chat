import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/auth_controller.dart';
import '../../data/mock_data.dart' show jurisdictionOptions;
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onSignIn;

  const SignUpScreen({super.key, required this.onSignIn});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _nationalId = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _jurisdiction = jurisdictionOptions.first;

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _phone.dispose();
    _nationalId.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    await auth.signUpWithEmail(
      email: _email.text.trim(),
      password: _password.text,
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration:
                              BoxDecoration(color: AppColors.oxblood, borderRadius: BorderRadius.circular(9)),
                          child: const Icon(LucideIcons.scale, size: 15, color: AppColors.paper),
                        ),
                        const SizedBox(width: 8),
                        Text('Legal Ecosystem', style: AppText.display(size: 14.5, weight: FontWeight.w700)),
                      ],
                    ),
                    TextButton(
                      onPressed: widget.onSignIn,
                      child: Text(
                        'LOG IN',
                        style: AppText.mono(size: 11, weight: FontWeight.w700, color: AppColors.oxblood),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Create Professional\nAccount', style: AppText.display(size: 23, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Join the global legal network. Secure your identity with our encrypted verification system.',
                  style: AppText.body(size: 12.5, color: AppColors.inkSoft).copyWith(height: 1.5),
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
                _JurisdictionField(
                  value: _jurisdiction,
                  onChanged: (v) => setState(() => _jurisdiction = v),
                ),
                const SizedBox(height: 18),
                _IdentityVerificationCard(controller: _nationalId),
                const SizedBox(height: 18),
                LepFormField(
                  label: 'Email address',
                  controller: _email,
                  hint: 'professional@firm.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 14),
                LepFormField(
                  label: 'Password',
                  controller: _password,
                  hint: '••••••••••••',
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
                ),
                const SizedBox(height: 24),
                LepPrimaryButton(
                  label: 'Create Account',
                  icon: LucideIcons.arrowRight,
                  loading: auth.isBusy,
                  onPressed: () => _submit(auth),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: widget.onSignIn,
                    child: Text.rich(
                      TextSpan(
                        style: AppText.body(size: 12.5, color: AppColors.inkSoft),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.oxblood),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(child: VerifiedStamp()),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'End-to-End Encryption Enabled',
                    style: AppText.mono(size: 10, color: AppColors.slate),
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

class _JurisdictionField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _JurisdictionField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
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
              value: value,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.slate),
              style: AppText.body(size: 13.5),
              items: [
                for (final option in jurisdictionOptions)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (v) => v != null ? onChanged(v) : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityVerificationCard extends StatelessWidget {
  final TextEditingController controller;
  const _IdentityVerificationCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shield, size: 15, color: AppColors.oxblood),
              const SizedBox(width: 6),
              Text('Identity Verification', style: AppText.display(size: 14.5, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          LepFormField(label: 'National ID / Passport ID', controller: controller, hint: 'Enter ID number'),
          const SizedBox(height: 8),
          Text(
            'Required for AML/KYC compliance in your selected jurisdiction.',
            style: AppText.body(size: 11, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
