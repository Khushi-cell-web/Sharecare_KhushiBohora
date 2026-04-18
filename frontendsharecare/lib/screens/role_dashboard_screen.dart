import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/providers/auth_provider.dart';
import '../features/home/widgets/role_navigation.dart';

/// Routes to the dashboard for the current user role.
class RoleDashboardScreen extends StatelessWidget {
  const RoleDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role ?? 'donor';
    return getDashboardForRole(role);
  }
}
