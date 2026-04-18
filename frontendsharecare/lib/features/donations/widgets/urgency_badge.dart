import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Color badge for urgency level (normal, high, urgent).
class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({super.key, required this.label, this.urgency = 'normal'});

  final String label;
  final String urgency;

  static Color _colorFor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'urgent':
        return AppTheme.chipUrgent;
      case 'high':
        return AppTheme.ctaOrange;
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
