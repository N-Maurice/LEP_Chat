import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../widgets/shared_widgets.dart';

/// Screen 1 — AI Legal Assistant.
/// Data source: [assistantMessages] / [assistantQuickActions] in
/// data/mock_data.dart. Point these at GET /api/v1/assistant/sessions/:id
/// (and POST a new user message on send) to go live.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(
              title: 'AI Legal Assistant',
              meta: 'Always active · Secure encryption',
              verified: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                children: [
                  for (final message in assistantMessages) _MessageBubble(message: message),
                  const SizedBox(height: 4),
                  for (final action in assistantQuickActions) _QuickActionChip(action: action),
                ],
              ),
            ),
            _Composer(controller: _controller),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: isUser ? AppColors.oxblood : AppColors.paperDim,
              border: isUser ? null : Border.all(color: AppColors.line),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isUser ? 16 : 4),
                topRight: Radius.circular(isUser ? 4 : 16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: AppText
                      .body(size: 13.5, color: isUser ? AppColors.paper : AppColors.ink)
                      .copyWith(height: 1.5),
                ),
                if (message.citation != null) CitationBlockWidget(citation: message.citation!),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(message.time, style: AppText.mono(size: 10, color: AppColors.slate)),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final QuickAction action;
  const _QuickActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(action.icon, size: 15, color: AppColors.oxbloodDeep),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              action.label,
              style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.oxbloodDeep),
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.oxblood.withValues(alpha: 0.05),
            side: const BorderSide(color: AppColors.oxblood),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  const _Composer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 14, 16),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.plus, size: 18, color: AppColors.inkSoft),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.paperDim,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.line),
              ),
              child: TextField(
                controller: controller,
                style: AppText.body(size: 12.5),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ask a legal question…',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.paperclip, size: 16, color: AppColors.inkSoft),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.mic, size: 16, color: AppColors.inkSoft),
          ),
          Container(
            margin: const EdgeInsets.only(left: 2),
            decoration: const BoxDecoration(color: AppColors.oxblood, shape: BoxShape.circle),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(LucideIcons.send, size: 16, color: AppColors.paper),
            ),
          ),
        ],
      ),
    );
  }
}
