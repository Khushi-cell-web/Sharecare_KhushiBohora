import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Modern, rounded button with consistent styling across the app
class ModernButton extends StatelessWidget {
  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool fullWidth;

  double get _height {
    switch (size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  double get _fontSize {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    switch (variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton(enabled);
      case ButtonVariant.secondary:
        return _buildSecondaryButton(enabled);
      case ButtonVariant.danger:
        return _buildDangerButton(enabled);
      case ButtonVariant.ghost:
        return _buildGhostButton(enabled);
    }
  }

  Widget _buildPrimaryButton(bool enabled) {
    return Container(
      height: _height,
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: enabled
            ? AppTheme.ctaGradient
            : LinearGradient(
                colors: [Colors.grey.shade400, Colors.grey.shade300],
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          splashColor: Colors.white.withValues(alpha: 0.14),
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: Padding(
            padding: _padding,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: _height - 16,
                      width: _height - 16,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: _fontSize + 4),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: _fontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(bool enabled) {
    return Container(
      height: _height,
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: enabled ? AppTheme.primaryTeal : Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          hoverColor: AppTheme.primaryTeal.withValues(alpha: 0.06),
          splashColor: AppTheme.primaryTeal.withValues(alpha: 0.10),
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: Padding(
            padding: _padding,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: enabled
                          ? AppTheme.primaryTeal
                          : Colors.grey.shade400,
                      size: _fontSize + 4,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? AppTheme.primaryTeal
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerButton(bool enabled) {
    return Container(
      height: _height,
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: AppTheme.statusError.withValues(alpha: enabled ? 1 : 0.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppTheme.statusError.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          splashColor: Colors.white.withValues(alpha: 0.14),
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: Padding(
            padding: _padding,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: _fontSize + 4),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton(bool enabled) {
    return Container(
      height: _height,
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.grey.shade100,
          splashColor: Colors.grey.shade200,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: Padding(
            padding: _padding,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: enabled
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                      size: _fontSize + 4,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ButtonVariant { primary, secondary, danger, ghost }

enum ButtonSize { small, medium, large }
