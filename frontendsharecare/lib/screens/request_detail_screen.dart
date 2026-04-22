import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/network_error_helper.dart';
import '../shared/models/donation_request.dart';
import '../shared/providers/auth_provider.dart';

class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key});

  Color _catColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return AppTheme.categoryFoodIcon;
      case 'clothes':
        return AppTheme.categoryClothesIcon;
      case 'funds':
        return AppTheme.categoryFundsIcon;
      case 'blood':
        return AppTheme.categoryBloodIcon;
      case 'organ':
        return AppTheme.categoryOrganIcon;
      default:
        return AppTheme.categoryOtherIcon;
    }
  }

  IconData _catIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'clothes':
        return Icons.checkroom_rounded;
      case 'funds':
        return Icons.attach_money_rounded;
      case 'blood':
        return Icons.water_drop_rounded;
      case 'organ':
        return Icons.favorite_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  Color _urgencyColor(String? urgency) {
    switch (urgency) {
      case 'High':
        return AppTheme.chipUrgent;
      case 'Medium':
        return AppTheme.accentOrange;
      default:
        return AppTheme.statusSuccess;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! DonationRequest) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('Request Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Request details are unavailable for this notification.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(AppRoutes.browseDonationRequests);
                  },
                  child: const Text('Browse Requests'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final request = args;
    final auth = context.watch<AuthProvider>();
    final color = _catColor(request.category);
    final isUrgent = request.urgency == 'High';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.65),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -10,
                    child: Icon(
                      _catIcon(request.category),
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.08),
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
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
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
                              'Request Details',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        request.title,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              request.categoryDisplay ?? request.category,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              request.statusDisplay ?? request.status,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (isUrgent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.priority_high_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'URGENT',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.deepShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.inventory_2_rounded,
                          label: 'Quantity',
                          value: '${request.quantityNeeded}',
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.speed_rounded,
                          label: 'Urgency',
                          value: request.urgency ?? 'N/A',
                          color: _urgencyColor(request.urgency),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.location_on_rounded,
                          label: 'Location',
                          value: request.location,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                      if (request.createdByUsername != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.person_rounded,
                            label: 'Created by',
                            value: request.createdByUsername!,
                            color: AppTheme.accentPurple,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (auth.isAuthenticated) ...[
                    const SizedBox(height: 24),

                    if (auth.user?.isDonor == true)
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          boxShadow: AppTheme.colorShadow(AppTheme.primaryTeal),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed('/offer-donation', arguments: request),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.card_giftcard_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Offer Donation',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (auth.user?.isDonor == true &&
                        request.createdBy != null &&
                        request.createdBy != auth.user?.id) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final ngoName =
                                request.creatorFullName ??
                                request.organization ??
                                request.createdByUsername ??
                                'NGO/Hospital';
                            try {
                              if (!context.mounted) return;
                              await Navigator.of(context).pushNamed(
                                AppRoutes.chatRoom,
                                arguments: <String, dynamic>{
                                  'receiver_id': request.createdBy!,
                                  'receiver_name': ngoName,
                                  'request_id': request.id,
                                  'context_subtitle': request.title,
                                },
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    NetworkErrorHelper.toUserMessage(e),
                                  ),
                                  backgroundColor: AppTheme.statusError,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Chat with NGO/Hospital'),
                        ),
                      ),
                    ],

                    if (auth.user?.isVolunteer == true) ...[
                      if (auth.user?.isDonor == true)
                        const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          boxShadow: AppTheme.colorShadow(AppTheme.primaryTeal),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                              '/volunteer-accept-task',
                              arguments: request,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.volunteer_activism_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Volunteer for This',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppTheme.colorShadow(color),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
