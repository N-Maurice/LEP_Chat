import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../data/mock_data.dart';
import '../models/api_models.dart';
import '../models/models.dart';
import '../services/chat_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Screen 1 — AI Legal Assistant, wired to the real backend: it loads (or
/// creates) the user's most recent chat session, then every send/receive
/// goes through ChatApiService -> api_lep_chat/app/routers/messages.py.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatApiService _chatApi = ChatApiService(ApiClient());

  String? _sessionId;
  List<ApiMessage> _messages = [];
  bool _loadingHistory = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final sessions = await _chatApi.listSessions();
      final session = sessions.isEmpty
          ? await _chatApi.createSession(title: 'Legal Assistant')
          : sessions.first;
      final messages = await _chatApi.listMessages(session.id);
      if (!mounted) return;
      setState(() {
        _sessionId = session.id;
        _messages = messages;
        _loadingHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loadingHistory = false;
      });
    }
  }

  Future<void> _send([String? presetText]) async {
    final text = (presetText ?? _controller.text).trim();
    final sessionId = _sessionId;
    if (text.isEmpty || sessionId == null || _sending) return;

    _controller.clear();
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final (userMessage, assistantMessage) = await _chatApi.sendMessage(sessionId, text);
      if (!mounted) return;
      setState(() => _messages = [..._messages, userMessage, assistantMessage]);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _friendlyError(Object e) => e is ApiException ? e.message : 'Something went wrong. Please try again.';

  String _questionFor(String actionLabel) {
    switch (actionLabel) {
      case 'Speak to a Lawyer':
        return 'I need help finding a lawyer for my situation. How does that work?';
      case 'View Court Process':
        return 'Can you explain the typical court process for a case like mine?';
      case 'Draft Legal Notice':
        return 'Can you help me draft a legal notice?';
      default:
        return actionLabel;
    }
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
              child: _loadingHistory
                  ? const Center(child: CircularProgressIndicator(color: AppColors.oxblood))
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      children: [
                        if (_error != null) LepErrorBanner(message: _error!),
                        if (_messages.isEmpty) const _EmptyState(),
                        for (final message in _messages) _MessageBubble(message: message),
                        if (_sending) const _TypingBubble(),
                        const SizedBox(height: 4),
                        for (final action in assistantQuickActions)
                          _QuickActionChip(action: action, onTap: () => _send(_questionFor(action.label))),
                      ],
                    ),
            ),
            _Composer(controller: _controller, onSend: () => _send(), sending: _sending),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(LucideIcons.bot, size: 28, color: AppColors.brass),
          const SizedBox(height: 10),
          Text(
            'Ask about Rwandan law — labour rights, land disputes, contracts, and more.',
            textAlign: TextAlign.center,
            style: AppText.body(size: 12.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.paperDim,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.oxblood),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ApiMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
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
                for (final citation in message.citations) ApiCitationBlockWidget(citation: citation),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(_formatTime(message.createdAt), style: AppText.mono(size: 10, color: AppColors.slate)),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final local = time.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }
}

class _QuickActionChip extends StatelessWidget {
  final QuickAction action;
  final VoidCallback onTap;
  const _QuickActionChip({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
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
  final VoidCallback onSend;
  final bool sending;
  const _Composer({required this.controller, required this.onSend, required this.sending});

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
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
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
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.paper),
                    )
                  : const Icon(LucideIcons.send, size: 16, color: AppColors.paper),
            ),
          ),
        ],
      ),
    );
  }
}
