import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_routes.dart';
import '../../features/home/widgets/dashboard_card.dart';
import '../../features/home/widgets/donation_charts.dart';
import '../../features/home/widgets/summary_card.dart';
import '../../shared/models/donation_request.dart';
import '../../shared/providers/auth_provider.dart';
import '../../core/services/sharecare_api_service.dart';
import '../../core/utils/network_error_helper.dart';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationRequest> _requests = [];
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
      final list = await _api.getMyRequests(auth.authHeaders);
      if (mounted) setState(() => _requests = list);
    } on ShareCareApiException catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _requests.length;
    final fulfilled = _requests.where((r) => r.isFulfilled).length;
    final pending = _requests.where((r) => r.isOpen || r.isMatched).length;

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
              decoration: const BoxDecoration(
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
                          'Organization',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your requests & impact',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
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
                  // Quick actions card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.deepShadow,
                    ),
                    child: Column(
                      children: [
                        _GradientActionBtn(
                          icon: Icons.add_rounded,
                          label: 'Create Donation Request',
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryGreen,
                              AppTheme.primaryGreenDark,
                            ],
                          ),
                          shadowColor: AppTheme.primaryTeal,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.createRequest),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _OutlinedActionBtn(
                                icon: Icons.assignment_rounded,
                                label: 'My Requests',
                                color: AppTheme.primaryTeal,
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.manageMyRequests),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _OutlinedActionBtn(
                                icon: Icons.badge_outlined,
                                label: 'Verification',
                                color: AppTheme.accentOrange,
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.ngoVerification),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          value: '$total',
                          label: 'Total requests',
                          icon: Icons.assignment_rounded,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          value: '$fulfilled',
                          label: 'Fulfilled',
                          icon: Icons.check_circle_rounded,
                          color: AppTheme.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          value: '$pending',
                          label: 'Pending',
                          icon: Icons.schedule_rounded,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Analytics
                  _SectionHeading(
                    icon: Icons.analytics_outlined,
                    title: 'Donation Analytics',
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const DonationChartsSection(),
                  ),

                  const SizedBox(height: 24),

                  // Active requests
                  _SectionHeading(
                    icon: Icons.list_alt_rounded,
                    title: 'My Active Requests',
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
                    Text(_error!, style: TextStyle(color: AppTheme.statusError))
                  else if (_requests.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No requests yet. Create one above.',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._requests.map(
                      (r) => DashboardCard(
                        title: r.title,
                        badge: r.statusDisplay ?? r.status,
                        badgeColor: r.isFulfilled
                            ? AppTheme.statusSuccess
                            : AppTheme.accentOrange,
                        onTap: () => Navigator.of(context)
                            .pushNamed(
                              AppRoutes.ngoRequestDetails,
                              arguments: r.toMap(),
                            )
                            .then((_) => _load()),
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

class _GradientActionBtn extends StatelessWidget {
  const _GradientActionBtn({
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

class _OutlinedActionBtn extends StatelessWidget {
  const _OutlinedActionBtn({
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
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
