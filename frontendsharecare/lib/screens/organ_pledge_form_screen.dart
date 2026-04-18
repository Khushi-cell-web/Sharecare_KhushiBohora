import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/services/sharecare_api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/network_error_helper.dart';
import '../shared/providers/auth_provider.dart';

/// Must match backend apps.users.serializers_life.ALLOWED_ORGANS
const _organOptions = [
  'Heart',
  'Kidney',
  'Liver',
  'Lungs',
  'Pancreas',
  'Eyes',
  'Skin',
  'Tissue',
  'Intestines',
];

const _genders = [
  ('male', 'Male'),
  ('female', 'Female'),
  ('other', 'Other'),
  ('prefer_not_say', 'Prefer not to say'),
];

class OrganPledgeFormScreen extends StatefulWidget {
  const OrganPledgeFormScreen({
    super.key,
    this.initialFullName,
    this.initialEmail,
    this.initialPhone,
    this.onSuccess,
  });

  final String? initialFullName;
  final String? initialEmail;
  final String? initialPhone;
  final VoidCallback? onSuccess;

  @override
  State<OrganPledgeFormScreen> createState() => _OrganPledgeFormScreenState();
}

class _OrganPledgeFormScreenState extends State<OrganPledgeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _medicalNotesCtrl = TextEditingController();
  final _api = ShareCareApiService();

  DateTime? _dob;
  String? _gender;
  final Set<String> _organs = {};
  bool _consent = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFullName != null) {
      _nameCtrl.text = widget.initialFullName!;
    }
    if (widget.initialEmail != null) {
      _emailCtrl.text = widget.initialEmail!;
    }
    if (widget.initialPhone != null) {
      _contactCtrl.text = widget.initialPhone!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _medicalNotesCtrl.dispose();
    super.dispose();
  }

  bool get _formReady {
    return _nameCtrl.text.trim().isNotEmpty &&
        _dob != null &&
        _gender != null &&
        _addressCtrl.text.trim().isNotEmpty &&
        _contactCtrl.text.trim().isNotEmpty &&
        _emailCtrl.text.trim().isNotEmpty &&
        _organs.isNotEmpty &&
        _emergencyNameCtrl.text.trim().isNotEmpty &&
        _emergencyPhoneCtrl.text.trim().isNotEmpty &&
        _consent;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_formReady) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit your pledge.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final body = <String, dynamic>{
      'full_name': _nameCtrl.text.trim(),
      'date_of_birth': DateFormat('yyyy-MM-dd').format(_dob!),
      'gender': _gender,
      'address': _addressCtrl.text.trim(),
      'contact_number': _contactCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'organs': _organs.toList(),
      'emergency_contact_name': _emergencyNameCtrl.text.trim(),
      'emergency_contact_phone': _emergencyPhoneCtrl.text.trim(),
      'medical_notes': _medicalNotesCtrl.text.trim(),
      'consent_organ_donation': _consent,
    };

    try {
      final res = await _api.submitLifeOrganPledge(auth.authHeaders, body);
      if (!mounted) return;
      widget.onSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ??
                'Thank you for your organ donation pledge.',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.maybePop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(NetworkErrorHelper.toUserMessage(e)),
          backgroundColor: AppTheme.statusError,
        ),
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
          'Organ donation pledge',
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
              'Complete this pledge voluntarily. You can update your pledge later by submitting again.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _section('Personal information', [
              TextFormField(
                controller: _nameCtrl,
                decoration: _dec('Full name'),
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.poppins(color: AppTheme.accentDark),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Date of birth',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
                subtitle: Text(
                  _dob == null
                      ? 'Tap to select'
                      : DateFormat.yMMMd().format(_dob!),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentDark,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: _pickDob,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey(_gender ?? '__gender__'),
                initialValue: _gender,
                decoration: _dec('Gender'),
                items: _genders
                    .map(
                      (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: _dec('Address'),
                maxLines: 3,
                style: GoogleFonts.poppins(color: AppTheme.accentDark),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactCtrl,
                decoration: _dec('Contact number'),
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(color: AppTheme.accentDark),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: _dec('Email'),
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(color: AppTheme.accentDark),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ]),
            const SizedBox(height: 16),
            _section('Organs you are willing to donate', [
              Text(
                'Select all that apply',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _organOptions.map((o) {
                  final sel = _organs.contains(o);
                  return FilterChip(
                    label: Text(o),
                    selected: sel,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _organs.add(o);
                        } else {
                          _organs.remove(o);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.25,
                    ),
                    checkmarkColor: AppTheme.primaryGreen,
                  );
                }).toList(),
              ),
              if (_organs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Select at least one organ',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.statusError,
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            _section('Emergency contact', [
              TextFormField(
                controller: _emergencyNameCtrl,
                decoration: _dec('Emergency contact name'),
                style: GoogleFonts.poppins(color: AppTheme.accentDark),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyPhoneCtrl,
                decoration: _dec('Emergency contact phone'),
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(color: AppTheme.accentDark),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
            ]),
            const SizedBox(height: 16),
            _section('Medical notes (optional)', [
              TextFormField(
                controller: _medicalNotesCtrl,
                decoration: _dec('Allergies, conditions, or other notes'),
                maxLines: 4,
                style: GoogleFonts.poppins(color: AppTheme.accentDark),
              ),
            ]),
            const SizedBox(height: 16),
            _section('Legal consent', [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I voluntarily agree to donate my organs and understand the terms and conditions.',
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
            ]),
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
                      'Submit pledge',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _section(String title, List<Widget> children) {
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
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
