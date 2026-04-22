import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/app_routes.dart';
import 'category_requests_screen.dart';

class CategoryListingScreen extends StatelessWidget {
  const CategoryListingScreen({super.key});

  static final List<Map<String, dynamic>> _categories = [
    {
      'key': 'food',
      'label': 'Food',
      'subtitle': 'Dry food, cooked meals, baby food',
      'icon': Icons.restaurant_rounded,
      'color': AppTheme.categoryFood,
      'iconColor': AppTheme.categoryFoodIcon,
      'route': AppRoutes.foodDonation,
    },
    {
      'key': 'clothes',
      'label': 'Clothes',
      'subtitle': 'Men, women, children',
      'icon': Icons.checkroom_rounded,
      'color': AppTheme.categoryClothes,
      'iconColor': AppTheme.categoryClothesIcon,
      'route': AppRoutes.clothesDonation,
    },
    {
      'key': 'funds',
      'label': 'Funds',
      'subtitle': 'Financial support',
      'icon': Icons.attach_money_rounded,
      'color': AppTheme.categoryFunds,
      'iconColor': AppTheme.categoryFundsIcon,
      'route': AppRoutes.fundsDonation,
    },
    {
      'key': 'blood',
      'label': 'Blood',
      'subtitle': 'Blood donations',
      'icon': Icons.water_drop_rounded,
      'color': AppTheme.categoryBlood,
      'iconColor': AppTheme.categoryBloodIcon,
      'route': AppRoutes.bloodDonation,
    },
    {
      'key': 'organ',
      'label': 'Organ',
      'subtitle': 'Awareness & pledge',
      'icon': Icons.favorite_rounded,
      'color': AppTheme.categoryOrgan,
      'iconColor': AppTheme.categoryOrganIcon,
      'route': AppRoutes.organDonation,
    },
    {
      'key': 'other',
      'label': 'Other',
      'subtitle': 'Other items',
      'icon': Icons.more_horiz_rounded,
      'color': AppTheme.impactGreen,
      'iconColor': AppTheme.categoryOtherIcon,
      'route': AppRoutes.otherDonation,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildGradientHeader(context, topPadding),
            ),
            SliverToBoxAdapter(child: _buildFloatingContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context, double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 36),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Layered depth: decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.searchFilter),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Donation Categories',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick a category to browse open requests or start a donation.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final c = _categories[index];
          final key = c['key'] as String;
          final label = c['label'] as String;
          final subtitle = c['subtitle'] as String;
          final icon = c['icon'] as IconData;
          final iconColor = c['iconColor'] as Color;
          final donateRoute = c['route'] as String;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.colorShadow(iconColor),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed(donateRoute),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  iconColor,
                                  iconColor.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: iconColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(icon, size: 20, color: Colors.white),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            height: 1.25,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 11,
                            child: SizedBox(
                              height: 40,
                              child: FilledButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(donateRoute),
                                style: FilledButton.styleFrom(
                                  backgroundColor: iconColor,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Donate',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 9,
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CategoryRequestsScreen(
                                      categoryKey: key,
                                      categoryLabel: '$label Donations',
                                      subtitle: subtitle,
                                    ),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: iconColor,
                                  side: BorderSide(
                                    color: iconColor.withValues(alpha: 0.5),
                                  ),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'View',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
