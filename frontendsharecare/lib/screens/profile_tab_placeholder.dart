import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Placeholder for Profile tab (Step 5 will add full Profile screen).
class ProfileTabPlaceholder extends StatelessWidget {
  const ProfileTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_rounded,
              size: 64,
              color: AppTheme.primaryGreen.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Profile, impact & achievements\n(coming in next step)',
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
