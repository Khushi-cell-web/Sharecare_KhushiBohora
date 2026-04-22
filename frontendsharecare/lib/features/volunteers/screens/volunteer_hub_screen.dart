import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'volunteer_dashboard_tab.dart';
import 'volunteer_available_tab.dart';
import 'volunteer_assigned_tab.dart';
import 'volunteer_map_tab.dart';
import '../../profile/screens/view_profile_screen.dart';

/// Volunteer hub: bottom nav with Home, Available Tasks, Assigned Tasks, Map, Profile.
class VolunteerHubScreen extends StatefulWidget {
  const VolunteerHubScreen({super.key});

  @override
  State<VolunteerHubScreen> createState() => _VolunteerHubScreenState();
}

class _VolunteerHubScreenState extends State<VolunteerHubScreen> {
  int _currentIndex = 0;

  static const List<_NavItem> _tabs = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.inventory_2_outlined, label: 'Available'),
    _NavItem(icon: Icons.assignment_rounded, label: 'Assigned'),
    _NavItem(icon: Icons.map_rounded, label: 'Map'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _switchToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          VolunteerDashboardTab(onSwitchTab: _switchToTab),
          const VolunteerAvailableTab(),
          const VolunteerAssignedTab(),
          const VolunteerMapTab(),
          const ViewProfileScreen(showBackButton: false),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppTheme.floatingShadow,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final item = _tabs[i];
                final selected = _currentIndex == i;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryTeal.withValues(alpha: 0.16),
                                AppTheme.accentPurple.withValues(alpha: 0.12),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _currentIndex = i),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                size: selected ? 25 : 23,
                                color: selected
                                    ? AppTheme.primaryTeal
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? AppTheme.primaryTeal
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
