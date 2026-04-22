import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../shared/providers/auth_provider.dart';

class OrganDonationScreen extends StatefulWidget {
  const OrganDonationScreen({super.key});

  @override
  State<OrganDonationScreen> createState() => _OrganDonationScreenState();
}

class _OrganDonationScreenState extends State<OrganDonationScreen> {
  bool _loading = true;
  bool _organPledged = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    try {
      final organRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/organ/status/'),
        headers: auth.authHeaders,
      );
      if (organRes.statusCode == 200) {
        final data = jsonDecode(organRes.body);
        _organPledged = data['pledged'] ?? false;
      }
    } catch (e) {
      debugPrint("Error loading organ donation status: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pledgeOrgan() async {
    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/organ/pledge/'),
        headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'organ_pledge_details': 'General Pledge'}),
      );

      if (res.statusCode == 200) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registered as organ donor!'),
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
            content: Text('Could not pledge organ.'),
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
        title: const Text('Organ Donation'),
        backgroundColor: AppTheme.primaryPinkDark,
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                    Icon(
                      Icons.monitor_heart,
                      color: AppTheme.primaryPinkDark,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Organ Pledge Status',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Text(
                  _organPledged
                      ? 'You have pledged your organs.'
                      : 'You have not pledged your organs yet.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _organPledged
                        ? AppTheme.statusSuccess
                        : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                if (!_organPledged)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pledgeOrgan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPinkDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Pledge Organ'),
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
                Navigator.maybePop(context);
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Learn More about Pledging'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppTheme.primaryPinkDark,
                side: BorderSide(color: AppTheme.primaryPinkDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
