import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Placeholder for Donate tab (Step 2 will add Create Donation / Categories).
class DonateTabPlaceholder extends StatelessWidget {
  const DonateTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 64,
              color: AppTheme.ctaOrange.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Donate',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create donation & browse categories\n(coming in next step)',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
