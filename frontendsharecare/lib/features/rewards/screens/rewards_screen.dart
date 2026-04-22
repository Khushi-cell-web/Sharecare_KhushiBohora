import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../volunteers/screens/volunteer_rewards_tab.dart';
import 'donor_rewards_screen.dart';

/// Generic rewards screen that routes based on user role.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role?.toLowerCase();

    if (role == 'volunteer') {
      return const VolunteerRewardsTab();
    } else if (role == 'donor') {
      return const DonorRewardsScreen();
    } else {
      // Fallback for other roles
      return Scaffold(
        appBar: AppBar(title: const Text('Rewards')),
        body: const Center(
          child: Text('Rewards not available for your account type.'),
        ),
      );
    }
  }
}
