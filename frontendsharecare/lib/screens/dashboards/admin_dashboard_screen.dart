import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/services/sharecare_api_service.dart';
import '../../core/utils/app_routes.dart';
import '../../core/utils/network_error_helper.dart';
import '../../shared/providers/auth_provider.dart';

const _pageBg = Color(0xFFF4F7F3);
const _cardBg = Colors.white;
const _sidebarBg = Color(0xFFE6F1E5);
const _primaryText = Color(0xFF1E2A1F);
const _mutedText = Color(0xFF647067);
const _accent = Color(0xFF3D7C47);
const _danger = Color(0xFFC84848);
const _border = Color(0xFFD9E4D8);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ShareCareApiService _api = ShareCareApiService();

  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _pendingProfiles = const [];
  final Set<int> _processingProfileIds = <int>{};

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.user?.role != 'admin') {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Admin access required.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getAdminDashboard(auth.authHeaders),
        _api.getAdminVerificationList(auth.authHeaders, status: 'pending'),
      ]);

      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _pendingProfiles = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } on ShareCareApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = NetworkErrorHelper.toUserMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = NetworkErrorHelper.toUserMessage(e);
      });
    }
  }

  Future<void> _reviewProfile(int profileId, bool approve) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    setState(() => _processingProfileIds.add(profileId));
    try {
      await _api.approveNgo(
        auth.authHeaders,
        profileId,
        action: approve ? 'approve' : 'reject',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'User accepted.' : 'User rejected.'),
          backgroundColor: approve ? _accent : _danger,
        ),
      );
      await _load();
    } on ShareCareApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(NetworkErrorHelper.toUserMessage(e)),
          backgroundColor: _danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(NetworkErrorHelper.toUserMessage(e)),
          backgroundColor: _danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingProfileIds.remove(profileId));
      }
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );

    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: _pageBg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              return Row(
                children: [
                  if (wide)
                    SizedBox(
                      width: 250,
                      child: _Sidebar(onNavigate: _onNavigate),
                    ),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(color: _accent),
                          )
                        : _error != null
                        ? _ErrorState(message: _error!, onRetry: _load)
                        : RefreshIndicator(
                            color: _accent,
                            onRefresh: _load,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                wide ? 28 : 16,
                                20,
                                wide ? 28 : 16,
                                24,
                              ),
                              children: [
                                _Header(onRefresh: _load),
                                const SizedBox(height: 20),
                                _VerificationPortalCard(
                                  pendingCount: _pendingProfiles.length,
                                  onOpen: _onNavigate,
                                ),
                                const SizedBox(height: 20),
                                _buildStats(wide),
                                const SizedBox(height: 20),
                                _buildPendingApprovals(),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStats(bool wide) {
    final cards = [
      _StatData(
        title: 'Total Users',
        value: _asInt(_dashboard?['users_total']).toString(),
        icon: Icons.people_alt_rounded,
      ),
      _StatData(
        title: 'Donation Requests',
        value: _asInt(_dashboard?['donation_requests_total']).toString(),
        icon: Icons.volunteer_activism_rounded,
      ),
      _StatData(
        title: 'Open Campaigns',
        value: _asInt(_dashboard?['active_campaigns']).toString(),
        icon: Icons.campaign_rounded,
      ),
      _StatData(
        title: 'Pending Reports',
        value: _asInt(_dashboard?['reports_pending']).toString(),
        icon: Icons.flag_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 4 : 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: wide ? 1.6 : 1.25,
      ),
      itemBuilder: (context, index) => _StatCard(data: cards[index]),
    );
  }

  Widget _buildPendingApprovals() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending User Approvals',
            style: GoogleFonts.plusJakartaSans(
              color: _primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Accept or reject NGO verification requests.',
            style: GoogleFonts.plusJakartaSans(color: _mutedText, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (_pendingProfiles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBF8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Text(
                'No users are waiting for approval.',
                style: GoogleFonts.plusJakartaSans(color: _mutedText),
              ),
            )
          else
            ..._pendingProfiles.map((profile) {
              final profileId = _asInt(profile['id']);
              final loading = _processingProfileIds.contains(profileId);
              final username = (profile['username'] ?? 'User').toString();
              final verificationId =
                  (profile['verification_id'] ?? 'Not provided').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFEFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFDDEBDB),
                          child: Icon(Icons.badge_rounded, color: _accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: GoogleFonts.plusJakartaSans(
                                  color: _primaryText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Verification ID: $verificationId',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _mutedText,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: loading
                              ? null
                              : () => _reviewProfile(profileId, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _danger,
                            side: const BorderSide(color: _danger),
                          ),
                          child: const Text('Reject'),
                        ),
                        FilledButton(
                          onPressed: loading
                              ? null
                              : () => _reviewProfile(profileId, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Accept'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _onNavigate(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) {
      _load();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Panel',
                style: GoogleFonts.plusJakartaSans(
                  color: _primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Clean view of users and approvals.',
                style: GoogleFonts.plusJakartaSans(
                  color: _mutedText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRefresh,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Panel',
                    style: GoogleFonts.plusJakartaSans(
                      color: _primaryText,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Clean view of users and approvals.',
                    style: GoogleFonts.plusJakartaSans(
                      color: _mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onRefresh,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _sidebarBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ShareCare Admin',
                style: GoogleFonts.plusJakartaSans(
                  color: _primaryText,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            selected: true,
            onTap: null,
          ),
          _SidebarItem(
            icon: Icons.verified_user_rounded,
            label: 'User Verification Portal',
            onTap: () => onNavigate(AppRoutes.verifyOrganizations),
          ),
        ],
      ),
    );
  }
}

class _VerificationPortalCard extends StatelessWidget {
  const _VerificationPortalCard({
    required this.pendingCount,
    required this.onOpen,
  });

  final int pendingCount;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 680;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FBF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(18),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDEBDB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: _accent,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Verification Portal',
                            style: GoogleFonts.plusJakartaSans(
                              color: _primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$pendingCount pending submissions waiting for review.',
                            style: GoogleFonts.plusJakartaSans(
                              color: _mutedText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Open this first to review submitted organizations.',
                  style: GoogleFonts.plusJakartaSans(
                    color: _mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => onOpen(AppRoutes.verifyOrganizations),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Portal'),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDEBDB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: _accent,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Verification Portal',
                        style: GoogleFonts.plusJakartaSans(
                          color: _primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Open this first to review submitted organizations.',
                        style: GoogleFonts.plusJakartaSans(
                          color: _mutedText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pendingCount pending submissions waiting for review.',
                        style: GoogleFonts.plusJakartaSans(
                          color: _mutedText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => onOpen(AppRoutes.verifyOrganizations),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Portal'),
                ),
              ],
            ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFD7E9D4) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: selected ? _accent : _mutedText, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: selected ? _accent : _primaryText,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: _accent, size: 20),
          const Spacer(),
          Text(
            data.value,
            style: GoogleFonts.plusJakartaSans(
              color: _primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            style: GoogleFonts.plusJakartaSans(
              color: _mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _danger, size: 36),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: _primaryText),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
