import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';

/// NGO/Hospital: submit verification ID (registration/license) and see verification status.
class NgoVerificationScreen extends StatefulWidget {
  const NgoVerificationScreen({super.key});

  @override
  State<NgoVerificationScreen> createState() => _NgoVerificationScreenState();
}

class _NgoVerificationScreenState extends State<NgoVerificationScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  final _formKey = GlobalKey<FormState>();
  final _verificationIdController = TextEditingController();
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _verificationIdController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    final value = _verificationIdController.text.trim();
    if (value.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await _api.submitVerification(auth.authHeaders, verificationId: value);
      await auth.loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification ID submitted. An admin will verify your organization.',
            ),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
        setState(() {
          _submitting = false;
          _submitError = null;
        });
      }
    } on ShareCareApiException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = NetworkErrorHelper.toUserMessage(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = NetworkErrorHelper.toUserMessage(e);
        });
      }
    }
  }

  Color _statusColor(String status, bool isVerified) {
    if (isVerified) return AppTheme.statusSuccess;
    if (status == 'rejected') return AppTheme.statusError;
    return AppTheme.ctaOrange;
  }

  IconData _statusIcon(String status, bool isVerified) {
    if (isVerified) return Icons.verified_rounded;
    if (status == 'rejected') return Icons.cancel_rounded;
    return Icons.pending_rounded;
  }

  String _statusLabel(String status, bool isVerified) {
    if (isVerified) return 'Verified';
    if (status == 'rejected') return 'Rejected';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final profile = user?.profile;
    final status = profile?.verificationStatus ?? 'pending';
    final isVerified = profile?.isVerified ?? false;
    final verificationId = profile?.verificationId;
    final notes = profile?.verificationNotes;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: topPadding + 12,
                left: 20,
                right: 20,
                bottom: 40,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Organization Verification',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _statusColor(status, isVerified),
                              _statusColor(
                                status,
                                isVerified,
                              ).withValues(alpha: 0.75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusIcon(status, isVerified),
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _statusLabel(status, isVerified),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVerified
                        ? 'Your organization is verified.'
                        : 'Complete verification to unlock features.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Floating Status Card ──
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.deepShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                status,
                                isVerified,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _statusIcon(status, isVerified),
                              size: 28,
                              color: _statusColor(status, isVerified),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isVerified
                                      ? 'Verified'
                                      : (status == 'rejected'
                                            ? 'Rejected'
                                            : 'Pending verification'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.navy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isVerified
                                      ? 'Your organization is verified. You can create donation requests.'
                                      : (status == 'rejected'
                                            ? 'Admin has rejected. Submit a new verification ID if needed.'
                                            : 'Submit your registration or license ID for admin verification.'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF78909C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (notes != null && notes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLightGrey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.note_alt_outlined,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Admin notes: $notes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF78909C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Form / Submitted Info ──
          if (!isVerified &&
                  (verificationId == null || verificationId.isEmpty) ||
              status == 'rejected')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.deepShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification ID',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your official registration or license number.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF78909C),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _verificationIdController,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. registration number, license ID',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF78909C),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F8FA),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primaryTeal,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.statusError,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.statusError,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your verification ID'
                              : null,
                        ),
                        if (_submitError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _submitError!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.statusError,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppTheme.colorShadow(
                              AppTheme.primaryTeal,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _submitting ? null : _submitVerification,
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                child: Center(
                                  child: _submitting
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Submit for Verification',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (!isVerified &&
              verificationId != null &&
              verificationId.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.deepShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submitted Verification ID',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F8FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                verificationId,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'An admin will review and verify your organization. You will be notified once verified.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF78909C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
