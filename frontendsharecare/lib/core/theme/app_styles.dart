import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Shared UI styles (decorations, borders) — no business logic.
class AppStyles {
  AppStyles._();

  /// Card with soft shadow and rounded corners
  static BoxDecoration cardDecoration({Color? color, double? radius}) {
    return BoxDecoration(
      color: color ?? AppTheme.surfaceWhite,
      borderRadius: BorderRadius.circular(radius ?? AppTheme.radiusMd),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Section heading style
  static TextStyle sectionTitle(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppTheme.primaryGreenDark,
    );
  }

  /// Body text style
  static TextStyle bodyStyle({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: color ?? Colors.black87,
    );
  }

  /// Input border (focused style)
  static OutlineInputBorder inputBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      borderSide: BorderSide(
        color: focused ? AppTheme.primaryTeal : Colors.grey.shade300,
        width: focused ? 2 : 1,
      ),
    );
  }
}
