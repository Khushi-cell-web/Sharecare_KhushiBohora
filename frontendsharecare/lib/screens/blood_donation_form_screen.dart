import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/services/sharecare_api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/network_error_helper.dart';
import '../shared/providers/auth_provider.dart';

const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

/// Full blood donation registration form; submits to POST /api/blood/register/.
class BloodDonationFormScreen extends StatefulWidget {
  const BloodDonationFormScreen({
    super.key,
    this.initialFullName,
    this.initialPhone,
    this.onSuccess,
  });

  final String? initialFullName;
  final String? initialPhone;
  final VoidCallback? onSuccess;

  @override
  State<BloodDonationFormScreen> createState() =>
      _BloodDonationFormScreenState();
}

class _BloodDonationFormScreenState extends State<BloodDonationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _api = ShareCareApiService();

  String? _bloodGroup;
  bool _firstTimeDonor = false;
  DateTime? _lastDonationDate;
  bool _healthIllness = false;
  bool _healthMedication = false;
  bool _healthWeight = false;
  bool _consent = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFullName != null) {
      _nameCtrl.text = widget.initialFullName!;
    }
    if (widget.initialPhone != null) {
      _contactCtrl.text = widget.initialPhone!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  bool get _formReady {
    final age = int.tryParse(_ageCtrl.text.trim());
    final base =
        _nameCtrl.text.trim().isNotEmpty &&
        age != null &&
        age >= 18 &&
        _contactCtrl.text.trim().isNotEmpty &&
        _bloodGroup != null &&
        _healthIllness &&
        _healthMedication &&
        _healthWeight &&
        _consent;
    if (_firstTimeDonor) return base;
    return base && _lastDonationDate != null;
  }

  Future<void> _pickLastDonation() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365)),
      firstDate: DateTime(1970),
      lastDate: now,
    );
    if (picked != null) setState(() => _lastDonationDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_formReady) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to register.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final body = <String, dynamic>{
      'full_name': _nameCtrl.text.trim(),
      'age': int.parse(_ageCtrl.text.trim()),
      'blood_group': _bloodGroup,
      'contact_number': _contactCtrl.text.trim(),
      'first_time_donor': _firstTimeDonor,
      'last_donation_date': _firstTimeDonor
          ? null
          : DateFormat('yyyy-MM-dd').format(_lastDonationDate!),
      'health_no_illness': _healthIllness,
      'health_not_on_medication': _healthMedication,
      'health_meets_weight_requirements': _healthWeight,
      'consent_information_correct': _consent,
    };

    try {
      final res = await _api.submitLifeBloodDonation(auth.authHeaders, body);
      if (!mounted) return;
      widget.onSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Registration successful.',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.maybePop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = NetworkErrorHelper.toUserMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.statusError),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Blood donation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Complete all sections accurately. Submission is checked against the 90-day donation rule.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _card(
              title: 'Your details',
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _decoration('Full name'),
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.poppins(color: AppTheme.accentDark),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageCtrl,
                  decoration: _decoration('Age'),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: AppTheme.accentDark),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null) return 'Enter a valid age';
                    if (n < 18) return 'Donors must be 18 or older';
                    if (n > 120) return 'Enter a valid age';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_bloodGroup ?? '__blood__'),
                  initialValue: _bloodGroup,
                  decoration: _decoration('Blood group'),
                  items: _bloodGroups
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _bloodGroup = v),
                  validator: (v) => v == null ? 'Select blood group' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactCtrl,
                  decoration: _decoration('Contact number'),
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(color: AppTheme.accentDark),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _card(
              title: 'Donation history',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'I am a first-time blood donor',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.accentDark,
                    ),
                  ),
                  value: _firstTimeDonor,
                  activeThumbColor: AppTheme.primaryGreen,
                  onChanged: (v) => setState(() {
                    _firstTimeDonor = v;
                    if (v) _lastDonationDate = null;
                  }),
                ),
                if (!_firstTimeDonor) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Last blood donation date',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    subtitle: Text(
                      _lastDonationDate == null
                          ? 'Tap to select'
                          : DateFormat.yMMMd().format(_lastDonationDate!),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentDark,
                      ),
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: _pickLastDonation,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _card(
              title: 'Health declaration',
              subtitle: 'Confirm each statement applies to you today.',
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'I am not currently ill (fever, infection, or symptoms that would defer donation)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.accentDark,
                    ),
                  ),
                  value: _healthIllness,
                  checkColor: Colors.white,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryGreen;
                    }
                    return null;
                  }),
                  onChanged: (v) => setState(() => _healthIllness = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'I am not under medication that defers blood donation (as per medical advice)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.accentDark,
                    ),
                  ),
                  value: _healthMedication,
                  checkColor: Colors.white,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryGreen;
                    }
                    return null;
                  }),
                  onChanged: (v) =>
                      setState(() => _healthMedication = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'I meet minimum weight and general eligibility for donation',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.accentDark,
                    ),
                  ),
                  value: _healthWeight,
                  checkColor: Colors.white,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryGreen;
                    }
                    return null;
                  }),
                  onChanged: (v) => setState(() => _healthWeight = v ?? false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _card(
              title: 'Consent',
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'I confirm that the information provided is correct and I am eligible to donate blood.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.accentDark,
                      height: 1.35,
                    ),
                  ),
                  value: _consent,
                  checkColor: Colors.white,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryGreen;
                    }
                    return null;
                  }),
                  onChanged: (v) => setState(() => _consent = v ?? false),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: (!_formReady || _submitting) ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit registration',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _card({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentDark,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
