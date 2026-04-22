import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../widgets/empty_error_state.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _api = ShareCareApiService();
  List<Map<String, dynamic>> _users = [];
  Map<int, int> _pendingProfileByUser = <int, int>{};
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
    if (!auth.isAuthenticated) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please log in.';
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getAdminUsers(auth.authHeaders),
        _api.getAdminVerificationList(auth.authHeaders, status: 'pending'),
      ]);

      final users = results[0];
      final pending = results[1];
      final byUser = <int, int>{};
      for (final p in pending) {
        final userId = (p['user'] as num?)?.toInt();
        final profileId = (p['id'] as num?)?.toInt();
        if (userId != null && profileId != null) {
          byUser[userId] = profileId;
        }
      }

      if (mounted) {
        setState(() {
          _users = users;
          _pendingProfileByUser = byUser;
          _loading = false;
          _error = null;
        });
      }
    } on ShareCareApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = NetworkErrorHelper.toUserMessage(e);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = NetworkErrorHelper.toUserMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _reviewPending(int profileId, bool approve) async {
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
          backgroundColor: approve ? AppTheme.primaryGreen : Colors.red,
        ),
      );
      await _load();
    } on ShareCareApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(NetworkErrorHelper.toUserMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingProfileIds.remove(profileId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: const Color(0xFFE6F1E5),
        foregroundColor: const Color(0xFF1E2A1F),
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
        data: Theme.of(context).copyWith(textTheme: textTheme),
        child: _loading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : _users.isEmpty
            ? const EmptyStateWidget(
                title: 'No users',
                subtitle: 'User list is empty',
                icon: Icons.people_rounded,
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: _users.map((e) {
                  final userId = (e['id'] as num?)?.toInt() ?? 0;
                  final profileId = _pendingProfileByUser[userId];
                  final processing =
                      profileId != null &&
                      _processingProfileIds.contains(profileId);
                  final username = (e['username'] ?? 'User').toString();
                  final email = (e['email'] ?? '').toString();
                  final role = (e['role_display'] ?? e['role'] ?? '')
                      .toString();
                  final verification = (e['verification_status'] ?? 'n/a')
                      .toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD9E4D8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFE6F1E5),
                              child: Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : 'U',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF1E2A1F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E2A1F),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email.isEmpty ? 'No email' : email,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF647067),
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
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [_chip(role), _chip(verification)],
                        ),
                        if (profileId != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: processing
                                    ? null
                                    : () => _reviewPending(profileId, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text('Reject'),
                              ),
                              FilledButton(
                                onPressed: processing
                                    ? null
                                    : () => _reviewPending(profileId, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF3D7C47),
                                ),
                                child: processing
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
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF2E6A35),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
