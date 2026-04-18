import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildGradientHeader(context)),
          SliverToBoxAdapter(child: _buildMenuCard(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 40,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your preferences and account',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Account',
              items: [
                _MenuItem(
                  icon: Icons.lock_rounded,
                  label: 'Change Password',
                  gradientColors: [
                    AppTheme.primaryTeal,
                    AppTheme.secondaryGreen,
                  ],
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.changePassword),
                ),
                _MenuItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notification Preferences',
                  gradientColors: [AppTheme.accentOrange, AppTheme.ctaOrange],
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.notificationPreferences),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Appearance',
              items: [
                _MenuItem(
                  icon: Icons.dark_mode_rounded,
                  label: 'Theme Settings',
                  gradientColors: [
                    const Color(0xFF8B5CF6),
                    const Color(0xFF6366F1),
                  ],
                  onTap: () => _showThemePicker(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Support',
              items: [
                _MenuItem(
                  icon: Icons.help_rounded,
                  label: 'Help & Support',
                  gradientColors: [
                    AppTheme.primaryTeal,
                    const Color(0xFF60A5FA),
                  ],
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.helpSupport),
                ),
                _MenuItem(
                  icon: Icons.info_rounded,
                  label: 'About ShareCare',
                  gradientColors: [AppTheme.accentPurple, AppTheme.accentPink],
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.aboutShareCare),
                ),
                _MenuItem(
                  icon: Icons.contact_support_rounded,
                  label: 'Contact Support',
                  gradientColors: [
                    AppTheme.primaryTeal,
                    AppTheme.secondaryGreen,
                  ],
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.contactSupport),
                ),
                _MenuItem(
                  icon: Icons.quiz_rounded,
                  label: 'FAQ',
                  gradientColors: [
                    AppTheme.accentPink,
                    const Color(0xFFF48FB1),
                  ],
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.faq),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '',
              items: [
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  gradientColors: [
                    AppTheme.statusError,
                    const Color(0xFFE57373),
                  ],
                  isDestructive: true,
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF78909C),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.deepShadow,
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                children: [
                  _buildMenuTile(item),
                  if (i < items.length - 1)
                    Divider(height: 1, indent: 68, color: Colors.grey.shade100),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(_MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: item.isDestructive
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: item.isDestructive
                        ? const Color(0xFFEF5350)
                        : const Color(0xFF1A2744),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: item.isDestructive
                    ? const Color(0xFFEF5350).withValues(alpha: 0.5)
                    : const Color(0xFF78909C),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => Column(
                children: [
                  _ThemeOption(
                    title: 'System Default',
                    icon: Icons.brightness_auto,
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () {
                      themeProvider.setTheme(ThemeMode.system);
                      Navigator.maybePop(context);
                    },
                  ),
                  _ThemeOption(
                    title: 'Light Mode',
                    icon: Icons.light_mode,
                    isSelected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () {
                      themeProvider.setTheme(ThemeMode.light);
                      Navigator.maybePop(context);
                    },
                  ),
                  _ThemeOption(
                    title: 'Dark Mode',
                    icon: Icons.dark_mode,
                    isSelected: themeProvider.themeMode == ThemeMode.dark,
                    onTap: () {
                      themeProvider.setTheme(ThemeMode.dark);
                      Navigator.maybePop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F172A).withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A).withOpacity(0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF0F172A)),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.gradientColors,
    this.onTap,
    this.isDestructive = false,
  });
}
