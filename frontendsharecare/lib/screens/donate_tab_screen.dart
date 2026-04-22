import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/app_routes.dart';

class DonateTabScreen extends StatelessWidget {
  const DonateTabScreen({super.key});

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
                top: MediaQuery.of(context).padding.top + 32,
                bottom: 32,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Make a Difference ??',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to help',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _CategoryCard(
                  label: 'Donate Items',
                  subtitle: 'Food, clothes, books & more',
                  icon: Icons.card_giftcard_rounded,
                  color: AppTheme.categoryFoodIcon,
                  route: AppRoutes.donateItems,
                ),
                const SizedBox(height: 16),
                _CategoryCard(
                  label: 'Donate Money',
                  subtitle: 'Financial support via funds',
                  icon: Icons.attach_money_rounded,
                  color: AppTheme.categoryFundsIcon,
                  route: AppRoutes
                      .donateFunds, // Assuming this stays inside category since it is fully functional
                ),
                const SizedBox(height: 16),
                _CategoryCard(
                  label: 'Browse Requests',
                  subtitle: 'Fulfill NGO and hospital needs',
                  icon: Icons.list_alt_rounded,
                  color: AppTheme.categoryOtherIcon,
                  route: AppRoutes.donateBrowse,
                ),
                const SizedBox(height: 16),
                _CategoryCard(
                  label: 'Life Donations ??',
                  subtitle: 'Blood & Organ pledges',
                  icon: Icons.favorite_rounded,
                  color: AppTheme.statusError, // Redish
                  route: AppRoutes.lifeDonations, // Will create next
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(context, route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
