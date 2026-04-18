import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/services/sharecare_api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/network_error_helper.dart';
import '../shared/providers/auth_provider.dart';
import 'blood_donation_form_screen.dart';
import 'organ_pledge_form_screen.dart';

class LifeDonationsScreen extends StatefulWidget {
  const LifeDonationsScreen({super.key});

  @override
  State<LifeDonationsScreen> createState() => _LifeDonationsScreenState();
}

class _LifeDonationsScreenState extends State<LifeDonationsScreen> {
  final ShareCareApiService _api = ShareCareApiService();

  bool _loading = true;
  String? _statusError;

  bool _bloodEligible = true;
  String? _bloodNextDate;
  String? _bloodGroup;
  String? _lastBloodIso;

  bool _organPledged = false;

  @override
  void initState() {
    super.initState();
    debugPrint('LifeDonationsScreen loaded');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRemoteStatus());
  }

  Future<void> _loadRemoteStatus() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() {
        _loading = false;
        _bloodEligible = true;
        _organPledged = false;
        _statusError = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _statusError = null;
    });

    try {
      final blood = await _api.getLifeBloodStatus(auth.authHeaders);
      final organ = await _api.getLifeOrganStatus(auth.authHeaders);
      if (!mounted) return;
      setState(() {
        _bloodEligible = blood['eligible'] == true;
        _bloodNextDate = blood['next_available_date']?.toString();
        _bloodGroup = blood['blood_group']?.toString();
        _lastBloodIso = blood['last_donation']?.toString();
        _organPledged = organ['is_pledged'] == true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusError = NetworkErrorHelper.toUserMessage(e);
        _loading = false;
      });
    }
  }

  String get _bloodMessage {
    if (!context.read<AuthProvider>().isAuthenticated) {
      return 'Sign in to track eligibility and register with the clinic record.';
    }
    if (_bloodEligible) {
      if (_bloodGroup != null && _bloodGroup!.isNotEmpty) {
        return 'You are eligible to donate blood. Your registered blood group: $_bloodGroup.';
      }
      return 'You are eligible to donate blood.';
    }
    final next = _bloodNextDate;
    if (next != null && next.isNotEmpty) {
      try {
        final d = DateTime.parse(next);
        final formatted = DateFormat.yMMMMd().format(d);
        return 'You are not eligible to donate blood yet. You can donate after $formatted.';
      } catch (_) {
        return 'You are not eligible to donate blood yet. You can donate after $next.';
      }
    }
    return 'You are not eligible to donate blood yet. Please wait until the 90-day period has passed.';
  }

  Future<void> _openBloodForm() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to continue.')),
      );
      await Navigator.of(context).pushNamed(AppRoutes.login);
      if (mounted) await _loadRemoteStatus();
      return;
    }

    final u = auth.user;
    final fullName = [
      u?.firstName,
      u?.lastName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim();
    final name = fullName.isNotEmpty ? fullName : (u?.username ?? '');
    final phone = u?.phone;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BloodDonationFormScreen(
          initialFullName: name.isNotEmpty ? name : null,
          initialPhone: (phone != null && phone.isNotEmpty) ? phone : null,
          onSuccess: _loadRemoteStatus,
        ),
      ),
    );
    if (mounted) await _loadRemoteStatus();
  }

  Future<void> _openOrganForm() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to continue.')),
      );
      await Navigator.of(context).pushNamed(AppRoutes.login);
      if (mounted) await _loadRemoteStatus();
      return;
    }

    final u = auth.user;
    final fullName = [
      u?.firstName,
      u?.lastName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim();
    final name = fullName.isNotEmpty ? fullName : (u?.username ?? '');

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrganPledgeFormScreen(
          initialFullName: name.isNotEmpty ? name : null,
          initialEmail: u?.email,
          initialPhone: u?.phone,
          onSuccess: _loadRemoteStatus,
        ),
      ),
    );
    if (mounted) await _loadRemoteStatus();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Life Donations',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : _loadRemoteStatus,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRemoteStatus,
              color: AppTheme.primaryGreen,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth < 560
                      ? constraints.maxWidth
                      : 560.0;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Save a life',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Register blood donations and organ pledges securely. '
                              'Blood donations follow a 90-day medical interval.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.4,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            if (_statusError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _statusError!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.statusError,
                                ),
                              ),
                            ],
                            if (!auth.isAuthenticated) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed(AppRoutes.login)
                                    .then((_) => _loadRemoteStatus()),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text(
                                  'Sign in to sync with your account',
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            _BloodSection(
                              message: _bloodMessage,
                              isAuthenticated: auth.isAuthenticated,
                              serverEligible: _bloodEligible,
                              onRegister: _openBloodForm,
                              lastDonationLabel: _formatLastDonation(
                                _lastBloodIso,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _OrganSection(
                              pledged: auth.isAuthenticated && _organPledged,
                              onPledge: _openOrganForm,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String? _formatLastDonation(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateFormat.yMMMMd().format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return null;
    }
  }
}

class _BloodSection extends StatelessWidget {
  const _BloodSection({
    required this.message,
    required this.isAuthenticated,
    required this.serverEligible,
    required this.onRegister,
    this.lastDonationLabel,
  });

  final String message;
  final bool isAuthenticated;
  final bool serverEligible;
  final VoidCallback onRegister;
  final String? lastDonationLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: Colors.red.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Blood donation',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textDark,
              ),
            ),
            if (lastDonationLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last recorded donation: $lastDonationLabel',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: (!isAuthenticated || serverEligible)
                  ? onRegister
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Text(
                'Register Blood Donation',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            if (isAuthenticated && !serverEligible)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Registration opens when you are eligible.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrganSection extends StatelessWidget {
  const _OrganSection({required this.pledged, required this.onPledge});

  final bool pledged;
  final VoidCallback onPledge;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.pink.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Organ donation',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              pledged
                  ? 'Thank you for your organ donation pledge.'
                  : 'Complete the pledge form with your details, organ choices, and legal consent.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textDark,
              ),
            ),
            if (!pledged) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onPledge,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Open pledge form',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
