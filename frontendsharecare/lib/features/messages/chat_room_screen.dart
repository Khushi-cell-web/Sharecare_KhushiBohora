import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/sharecare_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/network_error_helper.dart';
import '../../shared/providers/auth_provider.dart';

/// Chat room screen for one conversation.
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.initialRoomId,
    this.requestId,
    this.donationId,
    this.contextSubtitle,
  });

  final int receiverId;
  final String receiverName;
  final int? initialRoomId;
  final int? requestId;
  final int? donationId;
  final String? contextSubtitle;

  /// Builds a chat screen from route arguments.
  static ChatRoomScreen? fromArguments(Object? raw) {
    if (raw == null) return null;
    final Map<String, dynamic> m;
    if (raw is Map<String, dynamic>) {
      m = raw;
    } else if (raw is Map) {
      m = Map<String, dynamic>.from(raw);
    } else {
      return null;
    }
    final rid = m['receiver_id'] ?? m['other_user_id'];
    final receiverId = rid is int
        ? rid
        : int.tryParse(rid?.toString() ?? '') ?? 0;
    if (receiverId == 0) return null;
    final roomRaw = m['room_id'] ?? m['id'];
    final roomId = roomRaw is int
        ? roomRaw
        : int.tryParse(roomRaw?.toString() ?? '');
    final name =
        (m['receiver_name'] ??
                m['other_user_username'] ??
                m['display_name'] ??
                'User')
            .toString();
    final req = m['request_id'];
    final requestId = req is int ? req : int.tryParse(req?.toString() ?? '');
    final don = m['donation_id'];
    final donationId = don is int ? don : int.tryParse(don?.toString() ?? '');
    final sub = (m['context_subtitle'] ?? m['request_subtitle'])?.toString();
    return ChatRoomScreen(
      receiverId: receiverId,
      receiverName: name,
      initialRoomId: roomId,
      requestId: requestId,
      donationId: donationId,
      contextSubtitle: (sub != null && sub.isNotEmpty) ? sub : null,
    );
  }

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _bootstrapping = true;
  bool _loadingMessages = false;
  String? _error;
  int? _roomId;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    print('Chat room opened with user: ${widget.receiverId}');
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsChannel?.sink.close();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() {
        _bootstrapping = false;
        _error = 'Please sign in to chat';
      });
      return;
    }
    setState(() {
      _bootstrapping = true;
      _error = null;
    });
    try {
      var roomId = widget.initialRoomId;
      if (roomId == null) {
        final room = await _api.getOrCreateChatRoom(
          auth.authHeaders,
          otherUserId: widget.receiverId,
        );
        roomId = room['id'] as int? ?? (room['chat_room'] as num?)?.toInt();
      }
      if (roomId == null) {
        throw Exception('Could not open chat room');
      }
      _roomId = roomId;
      if (!mounted) return;
      setState(() {});
      await _loadMessages();
      await _api.markChatRead(auth.authHeaders, roomId: _roomId!);
      _connectWs();
    } catch (e) {
      if (mounted) {
        setState(() => _error = NetworkErrorHelper.toUserMessage(e));
      }
    } finally {
      if (mounted) setState(() => _bootstrapping = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_roomId == null) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    setState(() {
      _loadingMessages = true;
      _error = null;
    });
    try {
      final list = await _api.getChatMessages(
        auth.authHeaders,
        roomId: _roomId!,
      );
      if (mounted) {
        setState(() => _messages = list);
        _scrollToBottom();
      }
    } on ShareCareApiException catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  void _connectWs() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.accessToken == null || _roomId == null) {
      return;
    }
    final wsUrl =
        '${ApiConstants.wsBaseUrl}/ws/messages/$_roomId/?token=${auth.accessToken}';
    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _wsSub = _wsChannel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            _onWsMessage(msg);
          } catch (_) {}
        },
        onError: (_) {},
        onDone: () {},
      );
    } catch (_) {}
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    final mid = msg['id'];
    if (mid != null &&
        _messages.any((m) => m['id'].toString() == mid.toString())) {
      return;
    }
    final sid = msg['sender'] ?? msg['sender_id'];
    final text = msg['text']?.toString() ?? '';
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) {
        final idVal = m['id'];
        if (idVal is! int || idVal >= 0) return false;
        final ms = m['sender'] ?? m['sender_id'];
        return m['text']?.toString() == text &&
            ms?.toString() == sid?.toString();
      });
      _messages.add(msg);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _roomId == null) return;

    final auth = context.read<AuthProvider>();
    final me = auth.user?.id;
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = <String, dynamic>{
      'id': tempId,
      'sender': me,
      'sender_id': me,
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
    };

    _msgController.clear();
    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    try {
      final msg = await _api.sendChatMessage(
        auth.authHeaders,
        roomId: _roomId!,
        text: text,
        requestId: widget.requestId,
        donationId: widget.donationId,
      );
      if (!mounted) return;
      setState(() {
        final i = _messages.indexWhere((m) => m['id'] == tempId);
        if (i >= 0) {
          _messages[i] = msg;
        } else if (!_messages.any(
          (m) => m['id'].toString() == msg['id']?.toString(),
        )) {
          _messages.add(msg);
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(NetworkErrorHelper.toUserMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.id;
    final name = widget.receiverName.trim().isEmpty
        ? 'User'
        : widget.receiverName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (_error != null && !_bootstrapping && _roomId == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppTheme.accentDark),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _bootstrap, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 20,
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.contextSubtitle != null &&
                          widget.contextSubtitle!.isNotEmpty)
                        Text(
                          widget.contextSubtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        )
                      else
                        Text(
                          'Messages',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _bootstrapping || (_loadingMessages && _messages.isEmpty)
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.poppins(
                            color: AppTheme.accentDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Say hello to start the conversation',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final senderId = msg['sender'] ?? msg['sender_id'];
                      final isMe =
                          senderId?.toString() == currentUserId?.toString();
                      final msgText = msg['text'] ?? '';
                      final time = msg['created_at'] ?? '';
                      final isRead =
                          (msg['is_read'] == true) ||
                          (msg['read_at'] != null &&
                              msg['read_at'].toString().isNotEmpty);
                      var timeStr = '';
                      try {
                        final dt = DateTime.parse(time.toString());
                        timeStr =
                            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      } catch (_) {}

                      return _MessageBubble(
                        text: msgText.toString(),
                        time: timeStr,
                        isMe: isMe,
                        isRead: isRead,
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLightGrey,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgController,
                        enabled: _roomId != null && !_bootstrapping,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.accentDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message…',
                          hintStyle: GoogleFonts.poppins(
                            color: AppTheme.textTertiary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.colorShadow(AppTheme.primaryTeal),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _send,
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isRead,
  });
  final String text;
  final String time;
  final bool isMe;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryTeal, AppTheme.primaryTealDark],
                )
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? AppTheme.primaryTeal.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : AppTheme.navy,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.65)
                      : AppTheme.textTertiary,
                ),
              ),
              if (isMe)
                Text(
                  isRead ? 'Seen' : 'Sent',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
