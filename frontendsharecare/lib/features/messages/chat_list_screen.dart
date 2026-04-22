import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/services/sharecare_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_routes.dart';
import '../../core/utils/network_error_helper.dart';
import '../../shared/providers/auth_provider.dart';

/// Chat home: people you can message (NGO/donor/volunteer context + existing chats).
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('Chat list loaded');
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() {
        _loading = false;
        _error = 'Sign in to view messages';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<Map<String, dynamic>> rows;
      try {
        rows = await _api.getChatPartners(auth.authHeaders);
      } catch (_) {
        final rooms = await _api.getChatRooms(auth.authHeaders);
        rows = rooms.map((c) {
          final last = c['last_message'] as Map<String, dynamic>?;
          return <String, dynamic>{
            'user_id': c['other_user_id'],
            'username': c['other_user_username'],
            'display_name': c['other_user_username'],
            'context_subtitle': null,
            'request_id': null,
            'donation_id': null,
            'room_id': c['id'],
            'last_message': last,
            'unread_count': c['unread_count'] ?? 0,
          };
        }).toList();
      }
      if (mounted) setState(() => _rows = rows);
    } on ShareCareApiException catch (e) {
      if (mounted) {
        setState(() => _error = NetworkErrorHelper.toUserMessage(e));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = NetworkErrorHelper.toUserMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primaryTeal,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 28,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chats',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _loading ? 'Loading…' : '${_rows.length} contacts',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_rows.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No contacts yet',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Offer a donation, accept a task, or open a request to chat with NGOs, donors, and volunteers.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final row = _rows[index];
                    final uid = row['user_id'];
                    final userId = uid is int
                        ? uid
                        : int.tryParse(uid?.toString() ?? '') ?? 0;
                    final name =
                        (row['display_name'] ?? row['username'] ?? 'User')
                            .toString();
                    final subtitle = (row['context_subtitle'] as String?)
                        ?.trim();
                    final last = row['last_message'] as Map<String, dynamic>?;
                    final lastText = (last?['text'] ?? '').toString().trim();
                    final lastAt = last?['created_at']?.toString();
                    final timeText = _formatTime(lastAt);
                    final unread = (row['unread_count'] as num?)?.toInt() ?? 0;
                    final initial = name.isNotEmpty
                        ? name[0].toUpperCase()
                        : '?';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: userId == 0
                              ? null
                              : () {
                                  Navigator.of(context)
                                      .pushNamed(
                                        AppRoutes.chatRoom,
                                        arguments: <String, dynamic>{
                                          'receiver_id': userId,
                                          'receiver_name': name,
                                          'room_id': row['room_id'],
                                          'request_id': row['request_id'],
                                          'donation_id': row['donation_id'],
                                          'context_subtitle': subtitle,
                                        },
                                      )
                                      .then((_) => _load());
                                },
                          child: Ink(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: unread > 0
                                    ? AppTheme.primaryTeal.withValues(
                                        alpha: 0.35,
                                      )
                                    : Colors.grey.shade100,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppTheme.primaryGreen
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: AppTheme.accentDark,
                                          ),
                                        ),
                                        if (subtitle != null &&
                                            subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          lastText.isEmpty
                                              ? 'No messages yet'
                                              : lastText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: lastText.isEmpty
                                                ? AppTheme.textTertiary
                                                : AppTheme.textMuted,
                                            fontStyle: lastText.isEmpty
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (timeText.isNotEmpty)
                                        Text(
                                          timeText,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppTheme.textTertiary,
                                          ),
                                        ),
                                      if (unread > 0) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryTeal,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '$unread',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: _rows.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
