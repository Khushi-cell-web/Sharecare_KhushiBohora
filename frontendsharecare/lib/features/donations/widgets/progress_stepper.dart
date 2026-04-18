import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Vertical progress stepper for donation status.
class ProgressStepper extends StatelessWidget {
  const ProgressStepper({
    super.key,
    required this.steps,
    this.currentIndex = 0,
  });

  final List<String> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= currentIndex
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade300,
                      border: Border.all(
                        color: i <= currentIndex
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: i < currentIndex
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i <= currentIndex
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: i < currentIndex
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i < steps.length - 1 ? 24 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i],
                        style: TextStyle(
                          fontWeight: i <= currentIndex
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 15,
                          color: i <= currentIndex
                              ? AppTheme.primaryGreenDark
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
