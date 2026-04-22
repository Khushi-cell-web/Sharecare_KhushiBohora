import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/models/notification_model.dart';
import '../../core/services/sharecare_api_service.dart';
import '../../core/utils/app_routes.dart';
import '../../core/utils/network_error_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<NotificationModel> _list = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getNotifications(auth.authHeaders);
      if (mounted) setState(() => _list = list);
    } on ShareCareApiException catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      await _api.markAllNotificationsRead(auth.authHeaders);
      if (mounted) _load();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Gradient header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_list.any((n) => !n.isRead))
                    GestureDetector(
                      onTap: _loading ? null : _markAllRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Read all',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Content
          if (_loading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_list.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pull to refresh',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final n = _list[index];
                  return _NotificationTile(notification: n);
                }, childCount: _list.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});
  final NotificationModel notification;

  void _openNotification(BuildContext context) {
    final type = notification.notificationType;

    // Map notification types to routes that can be opened without extra payload.
    if (type == 'offer_received' ||
        type == 'offer_accepted' ||
        type == 'offer_rejected' ||
        type == 'request_created') {
      Navigator.of(context).pushNamed(AppRoutes.manageMyRequests);
      return;
    }

    if (type == 'donation_made') {
      Navigator.of(context).pushNamed(AppRoutes.myOffers);
      return;
    }

    if (type == 'task_assigned' || type == 'task_status_updated') {
      Navigator.of(context).pushNamed(AppRoutes.volunteerTasks);
      return;
    }

    if (notification.targetType == 'donation_request' &&
        notification.targetId != null) {
      Navigator.of(context).pushNamed(AppRoutes.browseDonationRequests);
      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.notifications);
  }

  @override
  Widget build(BuildContext context) {
    String timeAgo = '';
    if (notification.createdAt != null) {
      try {
        final dt = DateTime.parse(notification.createdAt!);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    final iconData = _iconForType(notification.notificationType);
    final iconColor = _colorForType(notification.notificationType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: notification.isRead
            ? null
            : Border.all(color: iconColor.withValues(alpha: 0.20)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: GestureDetector(
        onTap: () => _openNotification(context),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (!notification.isRead)
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    notification.isRead ? 16 : 12,
                    14,
                    16,
                    14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              iconColor.withValues(alpha: 0.15),
                              iconColor.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: GoogleFonts.poppins(
                                      fontWeight: notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.navy,
                                    ),
                                  ),
                                ),
                                if (timeAgo.isNotEmpty)
                                  Text(
                                    timeAgo,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'offer_received':
      case 'offer_accepted':
        return AppTheme.statusSuccess;
      case 'offer_rejected':
        return AppTheme.statusError;
      case 'task_assigned':
      case 'task_status_updated':
        return AppTheme.accentOrange;
      case 'request_created':
      case 'request_matched':
      case 'request_completed':
        return AppTheme.primaryTeal;
      case 'verification_updated':
        return AppTheme.accentPurple;
      case 'donation_made':
        return AppTheme.statusSuccess;
      case 'campaign_created':
      case 'campaign_approved':
        return AppTheme.primaryTeal;
      case 'campaign_goal_reached':
        return AppTheme.accentOrange;
      default:
        return AppTheme.primaryTeal;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'offer_received':
      case 'offer_accepted':
      case 'offer_rejected':
        return Icons.card_giftcard_rounded;
      case 'task_assigned':
      case 'task_status_updated':
        return Icons.volunteer_activism_rounded;
      case 'request_created':
      case 'request_matched':
      case 'request_completed':
        return Icons.assignment_rounded;
      case 'verification_updated':
        return Icons.verified_rounded;
      case 'donation_made':
        return Icons.attach_money_rounded;
      case 'campaign_created':
      case 'campaign_approved':
        return Icons.campaign_rounded;
      case 'campaign_goal_reached':
        return Icons.emoji_events_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
