import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/donation_request.dart';
import 'urgency_badge.dart';

/// Card for a donation request (title, category, urgency, quantity, View Details).
class DonationCard extends StatelessWidget {
  const DonationCard({
    super.key,
    required this.request,
    this.onTap,
    this.onChat,
    this.onFulfill,
  });

  final DonationRequestModel request;
  final VoidCallback? onTap;
  final VoidCallback? onChat;
  final VoidCallback? onFulfill;

  static IconData _iconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('food')) return Icons.restaurant_rounded;
    if (c.contains('clothes')) return Icons.checkroom_rounded;
    if (c.contains('fund')) return Icons.attach_money_rounded;
    if (c.contains('blood')) return Icons.water_drop_rounded;
    if (c.contains('organ')) return Icons.favorite_rounded;
    return Icons.inventory_2_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.impactGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconForCategory(request.category),
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryGreenDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.category,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (request.requestedByLabel != null &&
                            request.requestedByLabel!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            request.requestedByLabel!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryGreenDark.withValues(
                                alpha: 0.85,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  UrgencyBadge(
                    label: request.urgency,
                    urgency: request.urgency,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.numbers_rounded,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Qty: ${request.quantity}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (onChat != null || onFulfill != null)
                Row(
                  children: [
                    if (onChat != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onChat,
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Chat'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryTeal,
                            side: const BorderSide(color: AppTheme.primaryTeal),
                          ),
                        ),
                      ),
                    if (onChat != null && onFulfill != null)
                      const SizedBox(width: 8),
                    if (onFulfill != null)
                      Expanded(
                        child: FilledButton(
                          onPressed: onFulfill,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Fulfill'),
                        ),
                      ),
                  ],
                ),
              if (onChat != null || onFulfill != null)
                const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
