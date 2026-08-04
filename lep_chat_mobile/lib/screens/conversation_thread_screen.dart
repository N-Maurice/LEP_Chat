import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_controller.dart';
import '../models/api_models.dart';
import '../services/conversation_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// A single direct-message thread with another citizen.
class ConversationThreadScreen extends StatefulWidget {
  final ApiConversation conversation;
  final ConversationApiService? conversationApi;
  const ConversationThreadScreen({super.key, required this.conversation, this.conversationApi});

  @override
  State<ConversationThreadScreen> createState() => _ConversationThreadScreenState();
}

class _ConversationThreadScreenState extends State<ConversationThreadScreen> {
  late final ConversationApiService _api = widget.conversationApi ?? ConversationApiService(ApiClient());
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<ApiDirectMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final messages = await _api.listMessages(widget.conversation.id);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load this conversation.';
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      final message = await _api.sendMessage(widget.conversation.id, text);
      if (!mounted) return;
      setState(() => _messages = [..._messages, message]);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Could not send this message.')),
      );
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

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthController>().firebaseUser?.uid;
    final other = widget.conversation.otherParticipant;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: other?.fullName ?? 'Conversation', meta: other != null ? '@${other.username}' : ''),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.oxblood))
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      children: [
                        if (_error != null) LepErrorBanner(message: _error!),
                        if (_messages.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No messages yet. Say hello!',
                              textAlign: TextAlign.center,
                              style: AppText.body(size: 12.5, color: AppColors.inkSoft),
                            ),
                          ),
                        for (final message in _messages) _MessageBubble(message: message, isMine: message.senderId == myUid),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              decoration: const BoxDecoration(color: AppColors.paper, border: Border(top: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.paperDim,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: AppText.body(size: 13),
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Message…',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(color: AppColors.oxblood, shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.paper))
                          : const Icon(LucideIcons.arrowUp, size: 18, color: AppColors.paper),
                    ),
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

class _MessageBubble extends StatelessWidget {
  final ApiDirectMessage message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isMine ? AppColors.oxblood : AppColors.paperDim,
          border: isMine ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMine ? const Radius.circular(4) : null,
            bottomLeft: !isMine ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.content,
          style: AppText.body(size: 13.5, color: isMine ? AppColors.paper : AppColors.ink).copyWith(height: 1.4),
        ),
      ),
    );
  }
}
