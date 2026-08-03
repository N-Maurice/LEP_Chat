import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../models/api_models.dart';
import '../services/conversation_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'conversation_thread_screen.dart';

/// Community — direct messages between citizens. Search finds people by
/// username; tapping a result starts (or reuses) a conversation with them.
class CommunityScreen extends StatefulWidget {
  final ConversationApiService? conversationApi;
  const CommunityScreen({super.key, this.conversationApi});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final ConversationApiService _api = widget.conversationApi ?? ConversationApiService(ApiClient());
  final _searchController = TextEditingController();

  List<ApiConversation> _conversations = [];
  List<PublicUser> _searchResults = [];
  bool _loading = true;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final conversations = await _api.listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load conversations.';
        _loading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await _api.searchUsers(query.trim());
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  Future<void> _startConversation(PublicUser user) async {
    try {
      final conversation = await _api.startConversation(user.uid);
      if (!mounted) return;
      setState(() {
        _searchController.clear();
        _searchResults = [];
      });
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ConversationThreadScreen(conversation: conversation, conversationApi: _api)),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Could not start this conversation.')),
      );
    }
  }

  Future<void> _openConversation(ApiConversation conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ConversationThreadScreen(conversation: conversation, conversationApi: _api)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Community', meta: 'Direct messages with other citizens'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.paperDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.search, size: 16, color: AppColors.slate),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _search,
                        style: AppText.body(size: 12.5),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          hintText: 'Find someone by username to message…',
                          hintStyle: AppText.body(size: 12.5, color: AppColors.slate),
                        ),
                      ),
                    ),
                    if (_searching)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.oxblood),
                      ),
                  ],
                ),
              ),
            ),
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final user in _searchResults)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.oxblood,
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.paper),
                          ),
                        ),
                        title: Text(user.fullName, style: AppText.body(size: 13, weight: FontWeight.w600)),
                        subtitle: Text('@${user.username}', style: AppText.body(size: 11.5, color: AppColors.inkSoft)),
                        onTap: () => _startConversation(user),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.oxblood))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          if (_error != null) LepErrorBanner(message: _error!),
                          if (_conversations.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.paperDim,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Column(
                                children: [
                                  const Icon(LucideIcons.users, size: 24, color: AppColors.slate),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No conversations yet. Search for someone above to start one.',
                                    textAlign: TextAlign.center,
                                    style: AppText.body(size: 12.5, color: AppColors.inkSoft),
                                  ),
                                ],
                              ),
                            )
                          else
                            for (final conversation in _conversations)
                              _ConversationRow(conversation: conversation, onTap: () => _openConversation(conversation)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final ApiConversation conversation;
  final VoidCallback onTap;
  const _ConversationRow({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final other = conversation.otherParticipant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.oxblood,
              child: Text(
                (other?.fullName.isNotEmpty ?? false) ? other!.fullName[0].toUpperCase() : '?',
                style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.paper),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(other?.fullName ?? 'Unknown user', style: AppText.body(size: 13, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 11.5, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}
