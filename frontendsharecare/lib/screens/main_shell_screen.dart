import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'role_dashboard_screen.dart';
import 'donate_tab_screen.dart';
import '../features/donations/screens/requests_screen.dart';
import '../features/matching/screens/matchmaking_screen.dart';
import '../features/profile/screens/view_profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  final List<Widget?> _tabs = [null, null, null, null, null];

  Widget _tabAt(int index) {
    if (_tabs[index] != null) return _tabs[index]!;
    switch (index) {
      case 0:
        _tabs[0] = const RoleDashboardScreen();
        break;
      case 1:
        _tabs[1] = const DonateTabScreen();
        break;
      case 2:
        _tabs[2] = const RequestsScreen();
        break;
      case 3:
        _tabs[3] = const MatchmakingScreen();
        break;
      default:
        _tabs[index] = const ViewProfileScreen(showBackButton: false);
    }
    return _tabs[index]!;
  }

  Widget _childAt(int index) {
    if (_currentIndex == index) return _tabAt(index);
    return _tabs[index] ?? const SizedBox.shrink();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    setShareCareMainShellSwitchTab((index) {
      if (mounted) setState(() => _currentIndex = index.clamp(0, 4));
    });
  }

  @override
  void dispose() {
    setShareCareMainShellSwitchTab(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _childAt(0),
          _childAt(1),
          _childAt(2),
          _childAt(3),
          _childAt(4),
        ],
      ),
      bottomNavigationBar: _FloatingBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItemData(Icons.home_rounded, 'Home'),
    _NavItemData(Icons.favorite_rounded, 'Donate'),
    _NavItemData(Icons.assignment_rounded, 'Requests'),
    _NavItemData(Icons.people_alt_rounded, 'Matchmaking'),
    _NavItemData(Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppTheme.secondaryGreen.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryTeal.withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final selected = currentIndex == i;
                return _NavItem(
                  icon: _items[i].icon,
                  label: _items[i].label,
                  isSelected: selected,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Keep labels compact to avoid bottom-nav overflow on small screens.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryTeal.withValues(alpha: 0.15),
                    AppTheme.primaryTeal.withValues(alpha: 0.06),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 26 : 24,
              height: isSelected ? 26 : 24,
              child: Icon(
                icon,
                size: isSelected ? 24 : 24,
                color: isSelected
                    ? AppTheme.primaryTeal
                    : const Color(0xFFB0BEC5),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
