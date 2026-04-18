import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _onGetStarted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E7D5B), Color(0xFFA5D6A7)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 50),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ShareCare',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.favorite, color: Colors.white, size: 28),
                ],
              ),
              const Spacer(flex: 2),
              // Illustration Concept
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8E6C9), // Light green
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.volunteer_activism,
                    color: Color(0xFFd32f2f), // Red heart flavor
                    size: 75,
                  ),
                ),
              ),
              const Spacer(flex: 1),
              // Tagline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Give. Help. Care.\nTogether, we make a difference.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Bottom Section
              GestureDetector(
                onTap: () => _onGetStarted(context),
                child: ClipPath(
                  clipper: TopCurveClipper(),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFF5F5F5),
                    padding: const EdgeInsets.only(
                      top: 50,
                      bottom: 40,
                      left: 30,
                      right: 30,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              children: const [
                                TextSpan(text: 'A platform that connects '),
                                TextSpan(
                                  text: 'donors',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D5B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: ',\n'),
                                TextSpan(
                                  text: 'NGOs',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D5B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: ', and '),
                                TextSpan(
                                  text: 'volunteers',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D5B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDot(true),
                              const SizedBox(width: 8),
                              _buildDot(false),
                              const SizedBox(width: 8),
                              _buildDot(false),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2E7D5B) : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, 40);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 40);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
