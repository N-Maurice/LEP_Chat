import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/api_models.dart';

/// Reusable pieces shared across every LEP screen so the "Docket & Ledger"
/// visual language — the citation block, verified stamp, and screen header —
/// stays perfectly consistent no matter which module renders it.

enum PillVariant { muted, brass, tag }

class LepPill extends StatelessWidget {
  final String label;
  final PillVariant variant;

  const LepPill({super.key, required this.label, this.variant = PillVariant.muted});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (variant) {
      case PillVariant.muted:
        bg = const Color(0xFFE7DED0);
        fg = AppColors.inkSoft;
        break;
      case PillVariant.brass:
        bg = AppColors.brassSoft;
        fg = const Color(0xFF7A5F22);
        break;
      case PillVariant.tag:
        bg = AppColors.oxblood;
        fg = AppColors.paper;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppText.mono(size: 9.5, weight: FontWeight.w600, color: fg)),
    );
  }
}

/// The little rotated "Verified" stamp — evokes an official document seal.
class VerifiedStamp extends StatelessWidget {
  final bool small;
  const VerifiedStamp({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.035,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 6 : 7, vertical: small ? 1 : 2),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.success, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shieldCheck, size: small ? 11 : 13, color: AppColors.success),
            const SizedBox(width: 3),
            Text(
              'Verified',
              style: AppText.mono(size: small ? 9 : 10, weight: FontWeight.w600, color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }
}

/// The signature element: a ledger-style rule + brass corner tag that wraps
/// every piece of sourced legal content returned by the AI Legal Assistant —
/// backed by the agent's real citations (api_lep_chat/app/agents), not mock data.
class ApiCitationBlockWidget extends StatelessWidget {
  final ApiCitation citation;
  const ApiCitationBlockWidget({super.key, required this.citation});

  @override
  Widget build(BuildContext context) {
    final hasLawRef = citation.lawNumber != null && citation.lawYear != null;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.paperDim,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: Border(left: BorderSide(color: AppColors.oxblood, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bookOpen, size: 12, color: AppColors.brass),
              const SizedBox(width: 5),
              Text(
                'OFFICIAL LEGAL SOURCE',
                style: AppText.mono(size: 10, weight: FontWeight.w700, color: AppColors.brass, letterSpacing: 0.06),
              ),
            ],
          ),
          if (citation.quote != null && citation.quote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '\u201c${citation.quote}\u201d',
              style: AppText
                  .display(size: 13.5, weight: FontWeight.w400, style: FontStyle.italic)
                  .copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Text(
              citation.source,
              style: AppText.mono(size: 11, weight: FontWeight.w600, color: AppColors.oxbloodDeep),
            ),
          ),
          if (hasLawRef || citation.domain != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (hasLawRef) LepPill(label: 'Law No. ${citation.lawNumber} of ${citation.lawYear}'),
                if (citation.domain != null) LepPill(label: citation.domain!, variant: PillVariant.brass),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Consistent top header used by all three screens: scale-mark avatar,
/// title, meta line, optional verified stamp, and a notification bell.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String meta;
  final bool verified;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.meta,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop) ...[
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(LucideIcons.arrowLeft, size: 17, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.oxblood, borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.scale, size: 18, color: AppColors.paper),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppText.display(size: 16.5, weight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      const VerifiedStamp(small: true),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(meta, style: AppText.body(size: 11.5, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(LucideIcons.bell, size: 17, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase mono label used above sections ("Primary case",
/// "Case timeline", "Other cases"...).
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: AppColors.slate, letterSpacing: 0.08),
    );
  }
}

/// Labeled text input matching the signup/sign-in forms in the mockup:
/// an uppercase mono label above a paper-bordered field.
class LepFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const LepFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: AppText.body(size: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body(size: 13.5, color: AppColors.slate),
            filled: true,
            fillColor: AppColors.paper,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.oxblood, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}

/// Password input built on [LepFormField] with a show/hide toggle (eye icon),
/// matching the mockup's obscured-password field with visibility control.
class LepPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;

  const LepPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
  });

  @override
  State<LepPasswordField> createState() => _LepPasswordFieldState();
}

class _LepPasswordFieldState extends State<LepPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return LepFormField(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      obscureText: _obscure,
      validator: widget.validator,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
          size: 18,
          color: AppColors.slate,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

/// Full-width primary button in oxblood, used for the main CTA on every
/// auth screen (Get Started, Sign In, Verify Identity...).
class LepPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const LepPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.oxblood,
          foregroundColor: AppColors.paper,
          disabledBackgroundColor: AppColors.oxblood.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.paper),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: AppText.body(size: 14.5, weight: FontWeight.w700, color: AppColors.paper)),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 17, color: AppColors.paper),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Full-width secondary/outline button — "I already have an account",
/// "Sign in with Google", etc.
class LepSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const LepSecondaryButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.line),
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: AppColors.oxblood),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppText.body(size: 14, weight: FontWeight.w700, color: AppColors.oxbloodDeep)),
          ],
        ),
      ),
    );
  }
}

/// Inline error banner shown under forms when an auth/API call fails.
class LepErrorBanner extends StatelessWidget {
  final String message;
  const LepErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE9E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3A8A8)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.triangleAlert, size: 16, color: AppColors.oxbloodDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppText.body(size: 12.5, color: AppColors.oxbloodDeep)),
          ),
        ],
      ),
    );
  }
}
