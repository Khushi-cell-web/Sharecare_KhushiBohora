import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/services/sharecare_api_service.dart';
import '../core/theme/app_theme.dart';
import '../shared/providers/auth_provider.dart';
import '../core/utils/network_error_helper.dart';
import '../features/donations/screens/pickup_location_picker_screen.dart';

class ItemDonationScreen extends StatefulWidget {
  const ItemDonationScreen({super.key});

  @override
  State<ItemDonationScreen> createState() => _ItemDonationScreenState();
}

class _ItemDonationScreenState extends State<ItemDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ShareCareApiService _api = ShareCareApiService();

  String _category = 'food';
  final _qtyController = TextEditingController(text: '1');
  final _descController = TextEditingController();
  DateTime? _expiryDate;
  DateTime? _validUntil;

  String _fulfillment = 'self_dropoff';
  String? _pickAddress;
  double? _pickLat;
  double? _pickLng;

  bool _loading = false;
  String? _error;

  static const _categories = [
    ('food', 'Food'),
    ('clothes', 'Clothes'),
    ('books', 'Books'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _qtyController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _openMap() async {
    final res = await Navigator.of(context).push<PickupLocationPickerResult>(
      MaterialPageRoute(
        builder: (_) =>
            const PickupLocationPickerScreen(title: 'Select Pickup Location'),
      ),
    );
    if (res != null && mounted) {
      setState(() {
        _pickLat = res.latitude;
        _pickLng = res.longitude;
        _pickAddress = res.address;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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

    if (_fulfillment == 'volunteer_pickup') {
      if (_pickLat == null || _pickLng == null) {
        setState(() => _error = 'Please select a pickup location on the map.');
        return;
      }
    }

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() => _error = 'Please log in to donate.');
      return;
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
        donationType: 'material',
        quantity: qty > 0 ? qty : 1,
        description: _descController.text.trim(),
        expiryDate: _category == 'food' ? _expiryDate : null,
        validUntil: _category == 'food' ? (_validUntil ?? _expiryDate) : null,
        fulfillmentType: _fulfillment,
        pickupLocation: _pickAddress,
        pickupLatitude: _pickLat,
        pickupLongitude: _pickLng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Donation submitted successfully! Thanks for your help.',
            ),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
        Navigator.maybePop(context);
      }
    } on ShareCareApiException catch (e) {
      setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      setState(() => _error = 'Error submitting donation: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate Items'),
        backgroundColor: AppTheme.primaryTeal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you donating?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
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
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter quantity';
                  if (int.tryParse(val) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (val) => val != null && val.isEmpty
                    ? 'Describe your items briefly'
                    : null,
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

              const SizedBox(height: 32),
              Text(
                'Delivery Method',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How will these items reach the NGO/Hospital?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _fulfillment,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                    value: 'self_dropoff',
                    child: Text('Self Delivery (Drop off at NGO later)'),
                  ),
                  DropdownMenuItem(
                    value: 'volunteer_pickup',
                    child: Text('Volunteer Pickup'),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _fulfillment = v ?? 'self_dropoff';
                  _error =
                      null; // Clear map validation errors when changing type
                }),
              ),

              if (_fulfillment == 'self_dropoff') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The NGO/Hospital will provide drop location details after they accept your donation.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_fulfillment == 'volunteer_pickup') ...[
                const SizedBox(height: 16),
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
                      _pickAddress ?? 'Location selected',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red[800], fontSize: 14),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
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
                      : const Text('Submit Donation'),
                ),
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
