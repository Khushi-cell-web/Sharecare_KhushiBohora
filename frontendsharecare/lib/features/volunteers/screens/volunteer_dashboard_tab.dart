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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = width >= 1100
              ? 32.0
              : width >= 760
              ? 24.0
              : 16.0;

          return RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildHeader(context),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.statusError.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.statusError.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.statusError,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            const _SectionTitle(
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
                            const SizedBox(height: 22),
                            const _SectionTitle(
                              icon: Icons.flash_on_rounded,
                              title: 'Quick Actions',
                            ),
                            const SizedBox(height: 12),
                            _QuickActionsSection(
                              onBrowseAvailable: () =>
                                  widget.onSwitchTab?.call(1),
                              onOpenAssigned: () => widget.onSwitchTab?.call(2),
                              onOpenHistory: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.taskHistory),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final points = user?.points ?? 0;
    final rank = _rankForPoints(points);

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryPinkDark,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
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
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              _HeaderInfoChip(
                                icon: Icons.star_rounded,
                                label: '$points Points',
                              ),
                              _HeaderInfoChip(
                                icon: Icons.emoji_events_rounded,
                                label: 'Rank: $rank',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        _HeaderActionButton(
                          icon: Icons.notifications_outlined,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.notifications),
                        ),
                        const SizedBox(height: 8),
                        _HeaderActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.conversations),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
            color: AppTheme.primaryPinkSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryPinkDark),
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
    final cards = [
      _SummaryCardData(
        icon: Icons.inventory_2_outlined,
        title: 'Available for Pickup',
        count: availableCount,
        color: AppTheme.accentBlue,
        onTap: onAvailable,
      ),
      _SummaryCardData(
        icon: Icons.assignment_rounded,
        title: 'Assigned Tasks',
        count: assignedCount,
        color: AppTheme.accentOrange,
        onTap: onAssigned,
      ),
      _SummaryCardData(
        icon: Icons.check_circle_outline_rounded,
        title: 'Completed Deliveries',
        count: completedCount,
        color: AppTheme.statusSuccess,
        onTap: onCompleted,
      ),
      _SummaryCardData(
        icon: Icons.near_me_rounded,
        title: 'Nearby Donations',
        count: nearbyCount,
        color: AppTheme.primaryTeal,
        onTap: onNearby,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final card = cards[index];
          return _SummaryCard(
            icon: card.icon,
            title: card.title,
            count: card.count,
            color: card.color,
            onTap: card.onTap,
          );
        },
      ),
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.14)),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 150;
              final iconBoxSize = compact ? 34.0 : 40.0;
              final iconSize = compact ? 18.0 : 20.0;
              final countFontSize = compact ? 22.0 : 26.0;
              final labelFontSize = compact ? 10.5 : 11.5;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: iconSize, color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$count',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: countFontSize,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryPinkDark,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.navy,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.onBrowseAvailable,
    required this.onOpenAssigned,
    required this.onOpenHistory,
  });

  final VoidCallback onBrowseAvailable;
  final VoidCallback onOpenAssigned;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.search_rounded,
        label: 'Browse Available',
        color: AppTheme.accentBlue,
        onTap: onBrowseAvailable,
      ),
      _QuickActionData(
        icon: Icons.assignment_turned_in_outlined,
        label: 'Open Assigned Tasks',
        color: AppTheme.accentOrange,
        onTap: onOpenAssigned,
      ),
      _QuickActionData(
        icon: Icons.history_rounded,
        label: 'View Task History',
        color: AppTheme.primaryTeal,
        onTap: onOpenHistory,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const spacing = 10.0;
        const minTileWidth = 220.0;
        final rawColumns = (width / (minTileWidth + spacing)).floor();
        final columns = rawColumns.clamp(1, 3).toInt();
        final tileWidth = columns == 1
            ? width
            : (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map(
                (action) => SizedBox(
                  width: tileWidth,
                  child: _QuickActionTile(data: action),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: data.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: data.color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navy,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 18, color: data.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _HeaderInfoChip extends StatelessWidget {
  const _HeaderInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
