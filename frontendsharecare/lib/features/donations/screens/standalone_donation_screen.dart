import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/services/sharecare_api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import 'pickup_location_picker_screen.dart';

/// Create a donation that is not tied to a specific request.
class StandaloneDonationScreen extends StatefulWidget {
  const StandaloneDonationScreen({super.key});

  @override
  State<StandaloneDonationScreen> createState() =>
      _StandaloneDonationScreenState();
}

class _StandaloneDonationScreenState extends State<StandaloneDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController(text: '1');
  final _descController = TextEditingController();
  final _deliveryController = TextEditingController();

  final ShareCareApiService _api = ShareCareApiService();

  String _category = 'food';
  String _donationType = 'material';
  String _fulfillment = 'self_dropoff';
  DateTime? _expiryDate;
  DateTime? _validUntil;
  double? _pickLat;
  double? _pickLng;
  String _pickAddress = '';
  bool _loading = false;
  String? _error;

  static const _categories = [
    ('food', 'Food'),
    ('clothes', 'Clothes'),
    ('funds', 'Funds'),
    ('blood', 'Blood'),
    ('organ', 'Organ'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _qtyController.dispose();
    _descController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  Future<void> _openMap() async {
    final res = await Navigator.of(context).push<PickupLocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => PickupLocationPickerScreen(
          initialLatitude: _pickLat,
          initialLongitude: _pickLng,
          title: 'Volunteer pickup location',
        ),
      ),
    );
    if (res != null && mounted) {
      setState(() {
        _pickLat = res.latitude;
        _pickLng = res.longitude;
        _pickAddress = res.address.isNotEmpty
            ? res.address
            : '${res.latitude.toStringAsFixed(4)}, ${res.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() => _error = 'Please log in.');
      return;
    }

    if (_category == 'food') {
      final now = DateTime.now();
      final expiry = _expiryDate;
      final validUntil = _validUntil ?? _expiryDate;

      if (expiry == null) {
        setState(() => _error = 'Expiry date is required for food donations.');
        return;
      }
      if (!expiry.isAfter(now)) {
        setState(() => _error = 'Expiry date must be in the future.');
        return;
      }
      if (validUntil == null || !validUntil.isAfter(now)) {
        setState(() => _error = 'Valid until must be in the future.');
        return;
      }
      if (validUntil.isBefore(expiry)) {
        setState(() => _error = 'Valid until must be on or after expiry date.');
        return;
      }
    }

    if (_category == 'blood') {
      try {
        final el = await _api.getBloodDonationEligibility(auth.authHeaders);
        final ok = el['eligible'] == true;
        if (!ok) {
          final msg =
              el['message'] as String? ??
              'You can donate blood only after 3 months from your last donation';
          setState(() => _error = msg);
          return;
        }
      } catch (e) {
        setState(() => _error = NetworkErrorHelper.toUserMessage(e));
        return;
      }
    }

    if (_donationType == 'material' && _fulfillment == 'volunteer_pickup') {
      if (_pickLat == null || _pickLng == null) {
        setState(
          () => _error =
              'Select pickup location on the map for volunteer delivery.',
        );
        return;
      }
      if (_deliveryController.text.trim().isEmpty) {
        setState(
          () => _error = 'Enter delivery / drop-off address for the volunteer.',
        );
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final qty = int.tryParse(_qtyController.text) ?? 1;
      await _api.createDonationRecord(
        auth.authHeaders,
        category: _category,
        donationType: _donationType == 'money' ? 'money' : 'material',
        quantity: qty,
        description: _descController.text.trim(),
        expiryDate: _category == 'food' ? _expiryDate : null,
        validUntil: _category == 'food' ? (_validUntil ?? _expiryDate) : null,
        fulfillmentType: _donationType == 'material'
            ? _fulfillment
            : 'self_dropoff',
        pickupLocation: _pickAddress.isNotEmpty ? _pickAddress : null,
        pickupLatitude: _pickLat,
        pickupLongitude: _pickLng,
        deliveryLocation: _fulfillment == 'volunteer_pickup'
            ? _deliveryController.text.trim()
            : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you! Your donation is now pending NGO acceptance.'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.of(context).pushReplacementNamed(AppRoutes.myDonationRecords);
    } catch (e) {
      if (mounted) {
        setState(() => _error = NetworkErrorHelper.toUserMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final material = _donationType != 'money';
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Donate freely'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a general donation (not tied to a specific request). '
                'It will first wait in the NGO review queue before any volunteer pickup is assigned.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _category = v ?? 'food';
                  _error = null;
                  if (_category != 'food') {
                    _expiryDate = null;
                    _validUntil = null;
                  }
                }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _donationType,
                decoration: const InputDecoration(
                  labelText: 'Donation type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'material',
                    child: Text('Material / in-kind'),
                  ),
                  DropdownMenuItem(
                    value: 'money',
                    child: Text('Money (record pledge)'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _donationType = v ?? 'material'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyController,
                decoration: InputDecoration(
                  labelText: _donationType == 'money'
                      ? 'Amount (units)'
                      : 'Quantity',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              if (_category == 'food') ...[
                const SizedBox(height: 16),
                _buildFoodDatePickerField(
                  label: 'Expiry Date',
                  value: _expiryDate,
                  requiredField: true,
                  onTap: () => _pickFoodDate(isValidUntil: false),
                ),
                const SizedBox(height: 12),
                _buildFoodDatePickerField(
                  label: 'Valid Until',
                  value: _validUntil,
                  hint: 'Optional (defaults to expiry date)',
                  onTap: () => _pickFoodDate(isValidUntil: true),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _expiryDate == null
                        ? null
                        : () => setState(() => _validUntil = _expiryDate),
                    child: const Text('Use Expiry Date'),
                  ),
                ),
              ],
              if (material) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _fulfillment,
                  decoration: const InputDecoration(
                    labelText: 'Fulfillment',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'self_dropoff',
                      child: Text('I will drop off myself'),
                    ),
                    DropdownMenuItem(
                      value: 'volunteer_pickup',
                      child: Text('Volunteer delivery (pickup from map)'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _fulfillment = v ?? 'self_dropoff'),
                ),
                if (_fulfillment == 'volunteer_pickup') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openMap,
                    icon: const Icon(Icons.map_rounded),
                    label: Text(
                      _pickLat != null
                          ? 'Change pickup on map'
                          : 'Select pickup location (map)',
                    ),
                  ),
                  if (_pickLat != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _pickAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deliveryController,
                    decoration: const InputDecoration(
                      labelText:
                          'Delivery address (where volunteer brings items)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red[800], fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit donation'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _toEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '${value.year}-$mm-$dd';
  }

  Future<void> _pickFoodDate({required bool isValidUntil}) async {
    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final current = isValidUntil ? _validUntil : _expiryDate;
    final initialDate = current != null && current.isAfter(tomorrow)
        ? current
        : tomorrow;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: isValidUntil ? 'Select Valid Until' : 'Select Expiry Date',
    );

    if (picked != null && mounted) {
      final selected = _toEndOfDay(picked);
      setState(() {
        if (isValidUntil) {
          _validUntil = selected;
        } else {
          _expiryDate = selected;
          if (_validUntil != null && _validUntil!.isBefore(selected)) {
            _validUntil = selected;
          }
        }
        _error = null;
      });
    }
  }

  Widget _buildFoodDatePickerField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool requiredField = false,
    String? hint,
  }) {
    final text = _formatDate(value);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: requiredField ? '$label *' : label,
          hintText: hint,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          text.isEmpty ? 'Select date' : text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: text.isEmpty ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
