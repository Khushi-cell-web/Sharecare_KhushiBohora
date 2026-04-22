import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

/// Color-coded status label. UI only.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.small = false,
  });

  final String label;
  final Color? color;
  final bool small;

  static Color colorForStatus(String status) {
    final s = status.toLowerCase();
    if (s == 'fulfilled' || s == 'completed' || s == 'delivered') {
      return AppTheme.statusSuccess;
    }
    if (s == 'open' || s == 'pending' || s == 'assigned') {
      return AppTheme.primaryTeal;
    }
    if (s == 'matched' || s == 'accepted' || s == 'picked') {
      return AppTheme.statusWarning;
    }
    if (s == 'closed' || s == 'rejected') return Colors.grey;
    if (s == 'urgent' || s == 'high') return AppTheme.chipUrgent;
    return AppTheme.primaryTeal;
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? colorForStatus(label);
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final fontSize = small ? 11.0 : 12.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: c.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}
