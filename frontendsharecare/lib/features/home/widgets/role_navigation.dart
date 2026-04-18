import 'package:flutter/material.dart';

import '../../../screens/dashboards/admin_dashboard_screen.dart';
import '../../../screens/dashboards/ngo_dashboard_screen.dart';
import '../../../screens/home_screen.dart';
import '../../volunteers/screens/volunteer_hub_screen.dart';

/// Supported app roles.
const List<String> shareCareRoles = ['donor', 'ngo', 'volunteer', 'admin'];

/// Dashboard chooser by role.
Widget getDashboardForRole(String? role) {
  switch (role?.toLowerCase()) {
    case 'ngo':
      return const NgoDashboardScreen();
    case 'volunteer':
      return const VolunteerHubScreen();
    case 'admin':
      return const AdminDashboardScreen();
    case 'donor':
    default:
      return const HomeScreen();
  }
}
