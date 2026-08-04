import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../models/api_models.dart';
import '../services/chat_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const _starterPrompts = [
  'What are my rights if I’m dismissed from my job?',
  'How do I register a land title dispute?',
  'Explain the process for filing a small claims case.',
];

/// Talk with Assistant — the AI Legal Assistant, wired to the real backend with
/// full CRUD: sessions can be created, listed, renamed, and deleted (history
/// sheet), and messages can be sent, edited, and deleted (long-press a message
/// you sent). Every reply is grounded in the ingested Firestore chunks via
/// api_lep_chat/app/agents/legal_research_agent.py.
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
    setState(() => _loadingHistory = true);
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

  Future<void> _startNewChat() async {
    setState(() {
      _loadingHistory = true;
      _error = null;
    });
    try {
      final session = await _chatApi.createSession(title: 'Legal Assistant');
      if (!mounted) return;
      setState(() {
        _sessionId = session.id;
        _messages = [];
        _loadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loadingHistory = false;
      });
    }
  }

  Future<void> _switchSession(String sessionId) async {
    Navigator.of(context).pop();
    setState(() {
      _loadingHistory = true;
      _error = null;
    });
    try {
      final messages = await _chatApi.listMessages(sessionId);
      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
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

  Future<void> _openHistory() async {
    List<ApiSession> sessions;
    try {
      sessions = await _chatApi.listSessions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _HistorySheet(
        sessions: sessions,
        activeSessionId: _sessionId,
        onSelect: _switchSession,
        onRename: (session) async {
          final newTitle = await _promptForText(sheetContext, title: 'Rename chat', initial: session.title);
          if (newTitle == null || newTitle.trim().isEmpty) return;
          await _chatApi.renameSession(session.id, newTitle.trim());
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop();
          _openHistory();
        },
        onDelete: (session) async {
          await _chatApi.deleteSession(session.id);
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop();
          if (session.id == _sessionId) {
            _bootstrap();
          } else {
            _openHistory();
          }
        },
      ),
    );
  }

  Future<String?> _promptForText(BuildContext context, {required String title, String? initial}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppText.display(size: 16, weight: FontWeight.w700)),
        content: TextField(controller: controller, autofocus: true, style: AppText.body(size: 13.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text('Save', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.oxblood)),
          ),
        ],
      ),
    );
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

  Future<void> _onMessageLongPress(ApiMessage message) async {
    if (!message.isUser || _sessionId == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.pencil, size: 18, color: AppColors.ink),
              title: const Text('Edit message'),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
              title: const Text('Delete message'),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;

    if (action == 'edit') {
      final newContent = await _promptForText(context, title: 'Edit message', initial: message.content);
      if (newContent == null || newContent.trim().isEmpty) return;
      try {
        final updated = await _chatApi.updateMessage(_sessionId!, message.id, newContent.trim());
        if (!mounted) return;
        setState(() {
          _messages = [for (final m in _messages) if (m.id == message.id) updated else m];
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      }
    } else if (action == 'delete') {
      try {
        await _chatApi.deleteMessage(_sessionId!, message.id);
        if (!mounted) return;
        setState(() => _messages = _messages.where((m) => m.id != message.id).toList());
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _ChatTopBar(onNewChat: _startNewChat, onHistory: _openHistory),
            Expanded(
              child: _loadingHistory
                  ? const Center(child: CircularProgressIndicator(color: AppColors.oxblood))
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      children: [
                        if (_error != null) LepErrorBanner(message: _error!),
                        if (_messages.isEmpty) _EmptyState(onPromptTap: (p) => _send(p)),
                        for (final message in _messages)
                          _MessageBubble(message: message, onLongPress: () => _onMessageLongPress(message)),
                        if (_sending) const _TypingIndicator(),
                        const SizedBox(height: 8),
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

class _ChatTopBar extends StatelessWidget {
  final VoidCallback onNewChat;
  final VoidCallback onHistory;
  const _ChatTopBar({required this.onNewChat, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.oxblood, borderRadius: BorderRadius.circular(11)),
            child: const Icon(LucideIcons.sparkles, size: 17, color: AppColors.paper),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Talk with Assistant', style: AppText.display(size: 16, weight: FontWeight.w700)),
                Text('Grounded in Rwandan law', style: AppText.body(size: 11, color: AppColors.inkSoft)),
              ],
            ),
          ),
          IconButton(
            onPressed: onHistory,
            icon: const Icon(LucideIcons.history, size: 19, color: AppColors.ink),
            tooltip: 'Chat history',
          ),
          IconButton(
            onPressed: onNewChat,
            icon: const Icon(LucideIcons.squarePen, size: 19, color: AppColors.ink),
            tooltip: 'New chat',
          ),
        ],
      ),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  final List<ApiSession> sessions;
  final String? activeSessionId;
  final ValueChanged<String> onSelect;
  final ValueChanged<ApiSession> onRename;
  final ValueChanged<ApiSession> onDelete;

  const _HistorySheet({
    required this.sessions,
    required this.activeSessionId,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chat history', style: AppText.display(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Flexible(
              child: sessions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No conversations yet.', style: AppText.body(size: 12.5, color: AppColors.inkSoft)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: sessions.length,
                      itemBuilder: (context, i) {
                        final session = sessions[i];
                        final active = session.id == activeSessionId;
                        return ListTile(
                          leading: Icon(
                            LucideIcons.messageSquare,
                            size: 18,
                            color: active ? AppColors.oxblood : AppColors.slate,
                          ),
                          title: Text(
                            session.title,
                            style: AppText.body(size: 13.5, weight: active ? FontWeight.w700 : FontWeight.w500),
                          ),
                          onTap: () => onSelect(session.id),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.pencil, size: 15, color: AppColors.slate),
                                onPressed: () => onRename(session),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 15, color: Colors.redAccent),
                                onPressed: () => onDelete(session),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onPromptTap;
  const _EmptyState({required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.brassSoft, borderRadius: BorderRadius.circular(16)),
            child: const Icon(LucideIcons.sparkles, size: 24, color: AppColors.oxblood),
          ),
          const SizedBox(height: 14),
          Text('Ask about Rwandan law', style: AppText.display(size: 17, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Labour rights, land disputes, contracts, and more — grounded in real legal sources.',
            textAlign: TextAlign.center,
            style: AppText.body(size: 12.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 18),
          for (final prompt in _starterPrompts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onPromptTap(prompt),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.paperDim,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.arrowUpRight, size: 14, color: AppColors.oxblood),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(prompt, style: AppText.body(size: 12.5, weight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Avatar(),
            const SizedBox(width: 10),
            Text('Thinking…', style: AppText.body(size: 12.5, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.oxblood, borderRadius: BorderRadius.circular(8)),
      child: const Icon(LucideIcons.scale, size: 13, color: AppColors.paper),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ApiMessage message;
  final VoidCallback onLongPress;
  const _MessageBubble({required this.message, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) ...[const _Avatar(), const SizedBox(width: 10)],
            Flexible(
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.oxblood,
                        borderRadius: BorderRadius.circular(18).copyWith(
                          bottomRight: const Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        message.content,
                        style: AppText.body(size: 13.5, color: AppColors.paper).copyWith(height: 1.5),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: AppText.body(size: 13.5, color: AppColors.ink).copyWith(height: 1.6),
                        ),
                        for (final citation in message.citations) ApiCitationBlockWidget(citation: citation),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(_formatTime(message.createdAt), style: AppText.mono(size: 10, color: AppColors.slate)),
                ],
              ),
            ),
          ],
        ),
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

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  const _Composer({required this.controller, required this.onSend, required this.sending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
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
                controller: controller,
                style: AppText.body(size: 13),
                minLines: 1,
                maxLines: 5,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ask a legal question…',
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
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.paper),
                    )
                  : const Icon(LucideIcons.arrowUp, size: 18, color: AppColors.paper),
            ),
          ),
        ],
      ),
    );
  }
}
