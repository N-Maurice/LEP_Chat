import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onCreateAccount;

  const SignInScreen({super.key, required this.onCreateAccount});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    await auth.signInWithEmail(email: _email.text.trim(), password: _password.text);
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
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.oxblood, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(LucideIcons.scale, size: 17, color: AppColors.paper),
                    ),
                    const SizedBox(width: 10),
                    Text('Legal Ecosystem', style: AppText.display(size: 16, weight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 32),
                Text('Welcome back', style: AppText.display(size: 24, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue to your legal ecosystem.',
                  style: AppText.body(size: 13, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 28),
                if (auth.errorMessage != null) LepErrorBanner(message: auth.errorMessage!),
                LepFormField(
                  label: 'Email address',
                  controller: _email,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                LepFormField(
                  label: 'Password',
                  controller: _password,
                  hint: '••••••••••••',
                  obscureText: true,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                const SizedBox(height: 24),
                LepPrimaryButton(
                  label: 'Sign In',
                  loading: auth.isBusy,
                  onPressed: () => _submit(auth),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.line)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('or', style: AppText.body(size: 11.5, color: AppColors.slate)),
                    ),
                    const Expanded(child: Divider(color: AppColors.line)),
                  ],
                ),
                const SizedBox(height: 14),
                LepSecondaryButton(
                  label: 'Sign in with Google',
                  icon: LucideIcons.globe,
                  onPressed: auth.isBusy ? null : () => auth.signInWithGoogle(),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: widget.onCreateAccount,
                    child: Text.rich(
                      TextSpan(
                        style: AppText.body(size: 12.5, color: AppColors.inkSoft),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Create one',
                            style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.oxblood),
                          ),
                        ],
                      ),
                    ),
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
