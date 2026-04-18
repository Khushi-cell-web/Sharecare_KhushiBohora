import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/sharecare_api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/donation_request.dart';
import 'payment_screen.dart';
import 'pickup_location_picker_screen.dart';

class OfferDonationScreen extends StatefulWidget {
  const OfferDonationScreen({super.key, required this.request});
  final DonationRequestModel request;

  @override
  State<OfferDonationScreen> createState() => _OfferDonationScreenState();
}

class _OfferDonationScreenState extends State<OfferDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  final ShareCareApiService _api = ShareCareApiService();

  String _donationType = 'goods';

  /// Material: volunteer picks up vs self drop-off
  bool _volunteerDelivery = true;
  double? _pickLat;
  double? _pickLng;
  String _pickAddress = '';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final res = await Navigator.of(context).push<PickupLocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => PickupLocationPickerScreen(
          initialLatitude: _pickLat,
          initialLongitude: _pickLng,
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

    if (widget.request.isBloodRequest) {
      try {
        final el = await _api.getBloodDonationEligibility(auth.authHeaders);
        if (el['eligible'] != true) {
          setState(() {
            _error =
                el['message'] as String? ??
                'You can donate blood only after 3 months from your last donation';
          });
          return;
        }
      } catch (e) {
        setState(() => _error = NetworkErrorHelper.toUserMessage(e));
        return;
      }
    }

    final isGoods = _donationType == 'goods';
    if (isGoods && _volunteerDelivery) {
      if (_pickLat == null || _pickLng == null) {
        setState(
          () => _error =
              'Select pickup location on the map for volunteer delivery.',
        );
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final fulfillment = isGoods
        ? (_volunteerDelivery ? 'volunteer_pickup' : 'self_dropoff')
        : null;
    final pickup = isGoods && _volunteerDelivery ? _pickAddress : null;

    setState(() => _submitting = false);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentScreen(
          request: widget.request,
          amount: int.tryParse(_quantityController.text) ?? 1,
          donationType: _donationType,
          fulfillmentType: fulfillment,
          pickupLocation: pickup,
          pickupLatitude: _pickLat,
          pickupLongitude: _pickLng,
          offerMessage: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGoods = _donationType == 'goods';
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Offer donation'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(widget.request.title),
                  subtitle: Text(
                    '${widget.request.requestedByLabel ?? widget.request.category} • ${widget.request.location}',
                  ),
                ),
              ),
              if (widget.request.isBloodRequest)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Blood donations are allowed only once every 3 months. Eligibility is checked when you continue.',
                    style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                  ),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: _donationType == 'money'
                      ? 'Amount (USD)'
                      : 'Quantity to donate',
                  hintText: _donationType == 'money' ? 'e.g. 25' : 'e.g. 5',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Donation type',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _donationType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'money', child: Text('Money')),
                  DropdownMenuItem(
                    value: 'goods',
                    child: Text('Goods / material'),
                  ),
                ],
                onChanged: (v) => setState(() => _donationType = v ?? 'goods'),
              ),
              if (isGoods) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Volunteer delivery'),
                  subtitle: const Text(
                    'A volunteer picks up from your map location and delivers to the organization.',
                  ),
                  value: _volunteerDelivery,
                  activeThumbColor: AppTheme.primaryGreen,
                  onChanged: (v) => setState(() => _volunteerDelivery = v),
                ),
                if (_volunteerDelivery) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickOnMap,
                    icon: const Icon(Icons.map_rounded),
                    label: Text(
                      _pickLat != null
                          ? 'Change pickup on map'
                          : 'Select pickup location (map)',
                    ),
                  ),
                  if (_pickAddress.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _pickAddress,
                        style: const TextStyle(color: AppTheme.primaryTeal),
                      ),
                    ),
                ],
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Add a message...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Colors.red[800])),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue to payment / submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
