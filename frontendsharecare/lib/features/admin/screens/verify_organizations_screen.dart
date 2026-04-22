import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../widgets/empty_error_state.dart';

const _pageBg = Color(0xFFF4F7F3);
const _cardBg = Colors.white;
const _primaryText = Color(0xFF1E2A1F);
const _mutedText = Color(0xFF647067);
const _accent = Color(0xFF3D7C47);
const _danger = Color(0xFFC84848);
const _border = Color(0xFFD9E4D8);

class VerifyOrganizationsScreen extends StatefulWidget {
  const VerifyOrganizationsScreen({super.key});

  @override
  State<VerifyOrganizationsScreen> createState() =>
      _VerifyOrganizationsScreenState();
}

class _VerifyOrganizationsScreenState extends State<VerifyOrganizationsScreen> {
  final _api = ShareCareApiService();
  List<Map<String, dynamic>> _profiles = [];
  final Set<int> _processing = <int>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Please log in.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getAdminVerificationList(
        auth.authHeaders,
        status: 'pending',
      );
      if (!mounted) return;
      setState(() {
        _profiles = list;
        _loading = false;
      });
    } on ShareCareApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = NetworkErrorHelper.toUserMessage(e);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = NetworkErrorHelper.toUserMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _approve(int profileId, bool approve) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    setState(() => _processing.add(profileId));
    try {
      await _api.approveNgo(
        auth.authHeaders,
        profileId,
        action: approve ? 'approve' : 'reject',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Organization accepted.' : 'Organization rejected.',
          ),
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
    } finally {
      if (mounted) {
        setState(() => _processing.remove(profileId));
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
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: Text(
          'User Verification Portal',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFE6F1E5),
        foregroundColor: _primaryText,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: _primaryText),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        style: FilledButton.styleFrom(backgroundColor: _accent),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: _accent,
                onRefresh: _load,
                child: _profiles.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          EmptyStateWidget(
                            title: 'No pending verifications',
                            subtitle: 'All organizations are verified',
                            icon: Icons.verified_rounded,
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _border),
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 8,
                              spacing: 12,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDDEBDB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.approval_rounded,
                                    color: _accent,
                                  ),
                                ),
                                SizedBox(
                                  width: 320,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pending User Verifications',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: _primaryText,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Review organization and user verification requests.',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: _mutedText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${_profiles.length} pending',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._profiles.map((profile) {
                            final id = _asInt(profile['id']);
                            final name = (profile['username'] ?? 'NGO')
                                .toString();
                            final verificationId =
                                (profile['verification_id'] ?? 'Not provided')
                                    .toString();
                            final notes = (profile['verification_notes'] ?? '')
                                .toString();
                            final loading = _processing.contains(id);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F4EF),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.business_rounded,
                                          color: _accent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    color: _primaryText,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Verification ID: $verificationId',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    color: _mutedText,
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (notes.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FBF8),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _border),
                                      ),
                                      child: Text(
                                        notes,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: _mutedText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: loading
                                            ? null
                                            : () => _approve(id, false),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _danger,
                                          side: const BorderSide(
                                            color: _danger,
                                          ),
                                        ),
                                        icon: const Icon(Icons.close_rounded),
                                        label: const Text('Reject'),
                                      ),
                                      FilledButton.icon(
                                        onPressed: loading
                                            ? null
                                            : () => _approve(id, true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _accent,
                                        ),
                                        icon: loading
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(Icons.check_rounded),
                                        label: const Text('Accept'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
              ),
      ),
    );
  }
}
