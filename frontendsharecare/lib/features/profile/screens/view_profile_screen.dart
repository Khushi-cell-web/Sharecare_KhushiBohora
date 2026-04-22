import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../shared/providers/auth_provider.dart';

class ViewProfileScreen extends StatelessWidget {
  const ViewProfileScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isVolunteer = user?.role == 'volunteer';
    final isDonor = user?.role == 'donor';
    final name = user?.firstName != null && user!.firstName!.isNotEmpty
        ? '${user.firstName} ${user.lastName ?? ''}'.trim()
        : user?.username ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

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
          final contentMaxWidth = width >= 1200 ? 980.0 : 860.0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Gradient profile header
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    bottom: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPinkDark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (showBackButton)
                                  GestureDetector(
                                    onTap: () => Navigator.maybePop(context),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                if (showBackButton) const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Profile',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.settings),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.settings_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white24, Colors.white10],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (user?.email != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                user!.email!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                            if (user?.roleDisplay != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  user?.roleDisplay ?? '',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            if (isVolunteer || isDonor) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total Points: ${user?.points ?? 0}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (isDonor) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.volunteer_activism_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Thank you for supporting families through donations.',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.donationHistory),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.12),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'History',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Menu items
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          boxShadow: AppTheme.deepShadow,
                        ),
                        child: Column(
                          children: [
                            _ProfileMenuItem(
                              icon: Icons.edit_rounded,
                              label: 'Edit Profile',
                              color: AppTheme.primaryTeal,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.editProfile),
                            ),
                            _Divider(),
                            _ProfileMenuItem(
                              icon: Icons.history_rounded,
                              label: 'Activity History',
                              color: AppTheme.accentOrange,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.activityHistory),
                            ),
                            _Divider(),
                            if (isDonor) ...[
                              _ProfileMenuItem(
                                icon: Icons.receipt_long_rounded,
                                label: 'Donation History',
                                color: AppTheme.accentPurple,
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.donationHistory),
                              ),
                              _Divider(),
                              _ProfileMenuItem(
                                icon: Icons.local_shipping_outlined,
                                label: 'Track My Donations',
                                color: AppTheme.primaryGreen,
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.myDonationRecords),
                              ),
                              _Divider(),
                              _ProfileMenuItem(
                                icon: Icons.inventory_2_rounded,
                                label: 'My Offers',
                                color: AppTheme.accentBlue,
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.myOffers),
                              ),
                              _Divider(),
                            ],
                            if (isVolunteer) ...[
                              _ProfileMenuItem(
                                icon: Icons.card_giftcard_rounded,
                                label: 'Rewards',
                                color: AppTheme.accentYellow,
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.rewards),
                              ),
                              _Divider(),
                            ],
                            if (isDonor) ...[
                              _ProfileMenuItem(
                                icon: Icons.card_giftcard_rounded,
                                label: 'Rewards',
                                color: AppTheme.accentYellow,
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.rewards),
                              ),
                              _Divider(),
                            ],
                            _ProfileMenuItem(
                              icon: Icons.help_outline_rounded,
                              label: 'Help & Support',
                              color: AppTheme.accentBlue,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.helpSupport),
                            ),
                            _Divider(),
                            _ProfileMenuItem(
                              icon: Icons.settings_rounded,
                              label: 'Settings',
                              color: AppTheme.textSecondary,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.settings),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Logout
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        10,
                        horizontalPadding,
                        0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            onTap: () async {
                              await auth.logout();
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.login,
                                  (_) => false,
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: AppTheme.statusError,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Log Out',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.statusError,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navy,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }
}
