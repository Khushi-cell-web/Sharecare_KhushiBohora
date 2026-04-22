import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_routes.dart';
import '../../features/home/widgets/dashboard_card.dart';
import '../../shared/models/donation_request.dart';
import '../../shared/providers/auth_provider.dart';
import '../../core/services/sharecare_api_service.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationRequest> _recommendations = [];
  bool _loadingRec = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    setState(() => _loadingRec = true);
    try {
      final list = await _api.getRecommendations(auth.authHeaders);
      if (mounted) setState(() => _recommendations = list);
    } catch (_) {}
    if (mounted) setState(() => _loadingRec = false);
  }

  Color _urgencyColor(String? urgency) {
    switch (urgency) {
      case 'High':
        return AppTheme.chipUrgent;
      case 'Medium':
        return AppTheme.accentOrange;
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _loadRecommendations,
        color: AppTheme.primaryTeal,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildGradientHeader(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildQuickActions(context),
                    const SizedBox(height: 28),
                    _buildRecommendationsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return SliverToBoxAdapter(
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
                    'Donor Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your generosity changes lives',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            _IconBtn(
              Icons.chat_bubble_outline_rounded,
              () => Navigator.of(context).pushNamed(AppRoutes.conversations),
            ),
            const SizedBox(width: 8),
            _IconBtn(
              Icons.notifications_outlined,
              () => Navigator.of(context).pushNamed(AppRoutes.notifications),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.deepShadow,
      ),
      child: Column(
        children: [
          _ActionButton(
            icon: Icons.search_rounded,
            label: 'Browse All Requests',
            gradient: const LinearGradient(
              colors: [AppTheme.accentYellow, AppTheme.accentOrange],
            ),
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.browseDonationRequests),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButtonOutlined(
                  icon: Icons.track_changes_rounded,
                  label: 'P2P Track',
                  color: AppTheme.accentOrange,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.p2pDonations),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButtonOutlined(
                  icon: Icons.history_rounded,
                  label: 'History',
                  color: AppTheme.primaryTeal,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.donationHistory),
                ),
              ),
            ],
          ),
            const SizedBox(height: 12),
            _ActionButtonOutlined(
              icon: Icons.local_shipping_outlined,
              label: 'Track My Donations',
              color: AppTheme.primaryGreen,
              onTap: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.myDonationRecords),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.accentOrange,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Recommended for You',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_loadingRec)
          Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
          )
        else if (_recommendations.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volunteer_activism,
                    size: 36,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No recommendations yet.',
                  style: GoogleFonts.poppins(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Make a donation to start getting personalized suggestions!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ..._recommendations
              .take(5)
              .map(
                (r) => DashboardCard(
                  title: r.title,
                  subtitle: '${r.category.toUpperCase()} \u2022 ${r.location}',
                  badge: r.urgency,
                  badgeColor: _urgencyColor(r.urgency),
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.requestDetail, arguments: r),
                ),
              ),
        if (_recommendations.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.browseDonationRequests),
              child: Text(
                'See more recommendations',
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn(this.icon, this.onTap);
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.colorShadow(AppTheme.primaryTeal),
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

class _ActionButtonOutlined extends StatelessWidget {
  const _ActionButtonOutlined({
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
