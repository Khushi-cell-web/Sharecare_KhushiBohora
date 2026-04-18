import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/progress_stepper.dart';

/// Donation Tracking: step indicator (Offered → Accepted → Volunteer Assigned → Delivered).
class DonationTrackingScreen extends StatelessWidget {
  const DonationTrackingScreen({super.key, this.currentStep = 0});

  final int currentStep;

  static const List<String> _steps = [
    'Offered',
    'Accepted',
    'Volunteer Assigned',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Tracking'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your donation status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryGreenDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ProgressStepper(
                      steps: _steps,
                      currentIndex: currentStep.clamp(0, _steps.length - 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Current step: ${_steps[currentStep.clamp(0, _steps.length - 1)]}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
