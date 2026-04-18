import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Placeholder for Requests tab (Step 4 will add My Donations).
class RequestsTabPlaceholder extends StatelessWidget {
  const RequestsTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_rounded,
              size: 64,
              color: AppTheme.primaryGreen.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'My Donations & requests\n(coming in next step)',
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
