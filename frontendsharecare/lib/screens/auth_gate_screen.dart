import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../shared/providers/auth_provider.dart';
import '../features/auth/screens/welcome_screen.dart';
import 'main_shell_screen.dart';
import '../features/volunteers/screens/volunteer_hub_screen.dart';

/// Shows login when not authenticated, home when authenticated.
/// Used as the app's root so unauthenticated users are redirected to login.
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  bool? _hasSeenWelcome;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_welcome') ?? false;
    if (mounted) {
      setState(() {
        _hasSeenWelcome = hasSeen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Wait until auth has loaded
    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spaceXl),
              padding: const EdgeInsets.all(AppTheme.spaceXl),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 34,
                    width: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Preparing ShareCare...',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      if (auth.user?.role == 'volunteer') {
        return const VolunteerHubScreen();
      }
      return const MainShellScreen();
    }

    return const WelcomeScreen();
  }
}
