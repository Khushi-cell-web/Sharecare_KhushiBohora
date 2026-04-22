import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_routes.dart';
import '../../features/home/widgets/dashboard_card.dart';
import '../../shared/models/volunteer_task.dart';
import '../../shared/providers/auth_provider.dart';
import '../../core/services/sharecare_api_service.dart';
import '../../core/utils/network_error_helper.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<VolunteerTask> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getMyTasks(auth.authHeaders);
      if (mounted) setState(() => _tasks = list);
    } on ShareCareApiException catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<VolunteerTask> get _assignedTasks => _tasks
      .where((t) => t.taskStatus == 'assigned' || t.taskStatus == 'picked')
      .toList();
  List<VolunteerTask> get _completedTasks =>
      _tasks.where((t) => t.taskStatus == 'delivered').toList();

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
                left: 24,
                right: 24,
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 48,
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
                        const SizedBox(height: 2),
                        Text(
                          'Help deliver hope to those in need',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Total Points: ${context.watch<AuthProvider>().user?.points ?? 0}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _HdrBtn(
                    Icons.chat_bubble_outline_rounded,
                    () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.conversations),
                  ),
                  const SizedBox(width: 8),
                  _HdrBtn(
                    Icons.notifications_outlined,
                    () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.notifications),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.deepShadow,
                    ),
                    child: Column(
                      children: [
                        _GradientBtn(
                          icon: Icons.search_rounded,
                          label: 'Browse Donation Requests',
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryGreen,
                              AppTheme.primaryGreenDark,
                            ],
                          ),
                          shadowColor: AppTheme.primaryTeal,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.browseDonationRequests),
                        ),
                        const SizedBox(height: 12),
                        _OutlinedBtn(
                          icon: Icons.history_rounded,
                          label: 'Task History',
                          color: AppTheme.primaryTeal,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.taskHistory),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Stat chips
                  Row(
                    children: [
                      _StatChip(
                        value: '${_assignedTasks.length}',
                        label: 'Active',
                        color: AppTheme.accentOrange,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        value: '${_completedTasks.length}',
                        label: 'Completed',
                        color: AppTheme.statusSuccess,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Assigned tasks
                  _SectionHeading(
                    icon: Icons.assignment_ind_rounded,
                    title: 'Assigned Tasks',
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppTheme.statusError),
                      ),
                    )
                  else if (_assignedTasks.isEmpty)
                    _EmptyState(
                      message: 'No assigned tasks.',
                      icon: Icons.inbox_rounded,
                    )
                  else
                    ..._assignedTasks.map(
                      (t) => DashboardCard(
                        title:
                            '${t.pickupLocation} \u2192 ${t.deliveryLocation}',
                        subtitle: t.donationRequestTitle ?? 'Task',
                        badge: t.taskStatusDisplay ?? t.taskStatus,
                        badgeColor: AppTheme.accentOrange,
                        onTap: () => Navigator.of(context)
                            .pushNamed(
                              AppRoutes.taskDetails,
                              arguments: t.toMap(),
                            )
                            .then((_) => _load()),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Completed tasks
                  _SectionHeading(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Completed Tasks',
                    color: AppTheme.statusSuccess,
                  ),
                  const SizedBox(height: 12),
                  if (!_loading && _error == null && _completedTasks.isEmpty)
                    _EmptyState(
                      message: 'No completed tasks yet.',
                      icon: Icons.emoji_events_rounded,
                    )
                  else if (!_loading && _error == null)
                    ..._completedTasks.map(
                      (t) => DashboardCard(
                        title:
                            '${t.pickupLocation} \u2192 ${t.deliveryLocation}',
                        subtitle: t.donationRequestTitle ?? 'Task',
                        badge: t.taskStatusDisplay ?? t.taskStatus,
                        badgeColor: AppTheme.statusSuccess,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.taskDetails,
                          arguments: t.toMap(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HdrBtn extends StatelessWidget {
  const _HdrBtn(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _GradientBtn extends StatelessWidget {
  const _GradientBtn({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.colorShadow(shadowColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedBtn extends StatelessWidget {
  const _OutlinedBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.color,
  });
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.navy,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.icon});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade300),
          const SizedBox(width: 12),
          Text(
            message,
            style: GoogleFonts.poppins(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
