import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

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
/// every piece of sourced legal content — used by the assistant screen and
/// the research hub alike so both read as "verifiable law" the same way.
class CitationBlockWidget extends StatelessWidget {
  final Citation citation;
  const CitationBlockWidget({super.key, required this.citation});

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 8),
          Text(
            '\u201c${citation.quote}\u201d',
            style: AppText
                .display(size: 13.5, weight: FontWeight.w400, style: FontStyle.italic)
                .copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    citation.source,
                    style: AppText.mono(size: 11, weight: FontWeight.w600, color: AppColors.oxbloodDeep),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Read full article', style: AppText.body(size: 11, weight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.externalLink, size: 12, color: AppColors.ink),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              LepPill(label: 'Jurisdiction: ${citation.jurisdiction}'),
              LepPill(label: 'Verified ${citation.verifiedYear}', variant: PillVariant.brass),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
