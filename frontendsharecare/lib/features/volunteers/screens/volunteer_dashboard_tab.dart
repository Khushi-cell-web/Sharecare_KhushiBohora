import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/models/volunteer_task.dart';
import '../../../shared/models/donation_request.dart';
import '../../../shared/providers/auth_provider.dart';

/// Volunteer dashboard summary tab.
class VolunteerDashboardTab extends StatefulWidget {
  const VolunteerDashboardTab({super.key, this.onSwitchTab});

  final void Function(int index)? onSwitchTab;

  @override
  State<VolunteerDashboardTab> createState() => _VolunteerDashboardTabState();
}

class _VolunteerDashboardTabState extends State<VolunteerDashboardTab> {
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationRequest> _available = [];
  List<VolunteerTask> _myTasks = [];
  String? _error;

  String _rankForPoints(int points) {
    if (points >= 150) return 'Top Contributor';
    if (points >= 51) return 'Active';
    return 'Beginner';
  }

  int get _availableCount => _available.length;
  int get _assignedCount =>
      _myTasks.where((t) => t.taskStatus != 'delivered').length;
  int get _completedCount =>
      _myTasks.where((t) => t.taskStatus == 'delivered').length;
  int get _nearbyCount => _available
      .length; // Same list; could filter by distance when location available

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() {});
      return;
    }
    setState(() {
      _error = null;
    });
    try {
      await auth.loadUser();
      final results = await Future.wait([
        _api.getAvailableRequestsForVolunteer(auth.authHeaders),
        _api.getMyTasks(auth.authHeaders),
      ]);
      if (mounted) {
        setState(() {
          _available = results[0] as List<DonationRequest>;
          _myTasks = results[1] as List<VolunteerTask>;
        });
      }
    } on ShareCareApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = NetworkErrorHelper.toUserMessage(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = NetworkErrorHelper.toUserMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildHeader(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.statusError),
                        ),
                      ),
                    ],
                    _SectionTitle(
                      icon: Icons.dashboard_rounded,
                      title: 'Summary',
                    ),
                    const SizedBox(height: 12),
                    _SummaryGrid(
                      availableCount: _availableCount,
                      assignedCount: _assignedCount,
                      completedCount: _completedCount,
                      nearbyCount: _nearbyCount,
                      onAvailable: () => widget.onSwitchTab?.call(1),
                      onAssigned: () => widget.onSwitchTab?.call(2),
                      onCompleted: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.taskHistory),
                      onNearby: () => widget.onSwitchTab?.call(1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final points = user?.points ?? 0;
    final rank = _rankForPoints(points);
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: MediaQuery.of(context).padding.top + 16,
          bottom: 24,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volunteer Hub',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help deliver hope to those in need',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$points Points',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rank: $rank',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.notifications),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.conversations),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryTeal),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.navy,
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.availableCount,
    required this.assignedCount,
    required this.completedCount,
    required this.nearbyCount,
    required this.onAvailable,
    required this.onAssigned,
    required this.onCompleted,
    required this.onNearby,
  });

  final int availableCount;
  final int assignedCount;
  final int completedCount;
  final int nearbyCount;
  final VoidCallback onAvailable;
  final VoidCallback onAssigned;
  final VoidCallback onCompleted;
  final VoidCallback onNearby;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _SummaryCard(
          icon: Icons.inventory_2_outlined,
          label: 'Available for Pickup',
          count: availableCount,
          color: AppTheme.accentBlue,
          onTap: onAvailable,
        ),
        _SummaryCard(
          icon: Icons.assignment_rounded,
          label: 'Assigned Tasks',
          count: assignedCount,
          color: AppTheme.accentOrange,
          onTap: onAssigned,
        ),
        _SummaryCard(
          icon: Icons.check_circle_outline_rounded,
          label: 'Completed Deliveries',
          count: completedCount,
          color: AppTheme.statusSuccess,
          onTap: onCompleted,
        ),
        _SummaryCard(
          icon: Icons.near_me_rounded,
          label: 'Nearby Donations',
          count: nearbyCount,
          color: AppTheme.primaryTeal,
          onTap: onNearby,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
