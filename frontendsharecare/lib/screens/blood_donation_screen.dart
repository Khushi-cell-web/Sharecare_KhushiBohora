import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/app_routes.dart';
import '../shared/providers/auth_provider.dart';

class BloodDonationScreen extends StatefulWidget {
  const BloodDonationScreen({super.key});

  @override
  State<BloodDonationScreen> createState() => _BloodDonationScreenState();
}

class _BloodDonationScreenState extends State<BloodDonationScreen> {
  bool _loading = true;
  bool _bloodEligible = true;
  int _daysUntilEligible = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    try {
      final bloodRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/blood/status/'),
        headers: auth.authHeaders,
      );
      if (bloodRes.statusCode == 200) {
        final data = jsonDecode(bloodRes.body);
        _bloodEligible = data['eligible'] ?? true;
        if (!_bloodEligible && data['next_available_date'] != null) {
          final nextDate = DateTime.parse(data['next_available_date']);
          _daysUntilEligible = nextDate.difference(DateTime.now()).inDays;
        }
      }
    } catch (e) {
      debugPrint("Error loading blood donation status: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registerBloodDonation() async {
    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/blood/register/'),
        headers: auth.authHeaders,
      );
      if (res.statusCode == 200) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registered as blood donor!'),
              backgroundColor: AppTheme.statusSuccess,
            ),
          );
        }
      } else {
        throw Exception("Failed to register");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not register blood donation.'),
            backgroundColor: AppTheme.statusError,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Donation'),
        backgroundColor: Colors.red[700],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.red[700], size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Eligibility Status',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Text(
                  _bloodEligible
                      ? 'You are eligible to donate blood.'
                      : 'Not eligible. You can donate again in ${_daysUntilEligible > 0 ? _daysUntilEligible : 0} days.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _bloodEligible
                        ? AppTheme.statusSuccess
                        : AppTheme.statusError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                if (_bloodEligible)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _registerBloodDonation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Register as Blood Donor'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.browseDonationRequests);
              },
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('View Blood Requests'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[700]!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
