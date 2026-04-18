import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/soft_design_system.dart';
import '../models/donation_request.dart';

/// Modern, clean donation card with all details in card-based UI
class ModernDonationCard extends StatelessWidget {
  const ModernDonationCard({
    super.key,
    required this.request,
    this.onTap,
    this.distanceKm,
    this.showDistance = true,
    this.trailing,
  });

  final DonationRequest request;
  final VoidCallback? onTap;
  final double? distanceKm;
  final bool showDistance;
  final Widget? trailing;

  static const Map<String, Color> _categoryColors = {
    'food': AppTheme.categoryFoodIcon,
    'clothes': AppTheme.categoryClothesIcon,
    'funds': AppTheme.categoryFundsIcon,
    'blood': AppTheme.categoryBloodIcon,
    'organ': AppTheme.categoryOrganIcon,
    'other': AppTheme.categoryOtherIcon,
  };

  static const Map<String, IconData> _categoryIcons = {
    'food': Icons.restaurant_rounded,
    'clothes': Icons.checkroom_rounded,
    'funds': Icons.attach_money_rounded,
    'blood': Icons.water_drop_rounded,
    'organ': Icons.favorite_rounded,
    'other': Icons.more_horiz_rounded,
  };

  Color get _categoryColor =>
      _categoryColors[request.category] ?? AppTheme.primaryTeal;
  IconData get _categoryIcon =>
      _categoryIcons[request.category] ?? Icons.info_rounded;

  Color get _urgencyColor {
    switch (request.urgency?.toLowerCase()) {
      case 'high':
        return AppTheme.statusError;
      case 'medium':
        return AppTheme.accentOrange;
      default:
        return AppTheme.statusSuccess;
    }
  }

  String get _distanceText {
    if (distanceKm == null) return 'Location unknown';
    if (distanceKm! < 1) return '< 1 km away';
    return '${distanceKm!.toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = request.urgency?.toLowerCase() == 'high';

    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header with category and urgency badges
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryIcon,
                              size: 14,
                              color: _categoryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              request.category.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _categoryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Urgency badge
                      if (isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _urgencyColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                size: 12,
                                color: _urgencyColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'URGENT',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _urgencyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Title
                  Text(
                    request.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                      height: 1.4,
                    ),
                  ),
                  if (request.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      request.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Divider
            Container(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
            // Footer with details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Quantity and contact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Qty: ${request.quantityNeeded}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (showDistance && distanceKm != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _distanceText,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Trailing widget
                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: trailing!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact donation card for horizontal scrolling (recommendations)
class CompactDonationCard extends StatelessWidget {
  const CompactDonationCard({super.key, required this.request, this.onTap});

  final DonationRequest request;
  final VoidCallback? onTap;

  static const Map<String, Color> _categoryColors = {
    'food': AppTheme.categoryFoodIcon,
    'clothes': AppTheme.categoryClothesIcon,
    'funds': AppTheme.categoryFundsIcon,
    'blood': AppTheme.categoryBloodIcon,
    'organ': AppTheme.categoryOrganIcon,
    'other': AppTheme.categoryOtherIcon,
  };

  Color get _categoryColor =>
      _categoryColors[request.category] ?? AppTheme.primaryTeal;

  @override
  Widget build(BuildContext context) {
    final isUrgent = request.urgency?.toLowerCase() == 'high';

    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Category and urgent badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      request.category.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _categoryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.statusError.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'URGENT',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.statusError,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                request.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              // Description
              if (request.description.isNotEmpty)
                Text(
                  request.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
