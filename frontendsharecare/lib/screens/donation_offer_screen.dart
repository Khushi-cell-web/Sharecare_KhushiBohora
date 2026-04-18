import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../shared/models/donation_request.dart';
import '../features/donations/models/donation_request.dart' as feat;
import '../features/donations/screens/payment_screen.dart';

class DonationOfferScreen extends StatefulWidget {
  const DonationOfferScreen({super.key});

  @override
  State<DonationOfferScreen> createState() => _DonationOfferScreenState();
}

class _DonationOfferScreenState extends State<DonationOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _messageController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  String _type = 'material';

  /// True when a volunteer should pick up from donor location.
  bool _volunteerPickup = true;
  bool _loading = false;
  String? _error;
  bool _initializedFromRequest = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _messageController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  Future<void> _submit(DonationRequest request) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (_type == 'material' && _volunteerPickup) {
      final p = _pickupLocationController.text.trim();
      if (p.isEmpty) {
        setState(
          () => _error =
              'Enter the pickup address where a volunteer should collect items.',
        );
        return;
      }
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (!mounted) return;
    final requestModel = feat.DonationRequestModel.fromDonationRequest(request);
    setState(() => _loading = false);
    final fulfillment = _type == 'material'
        ? (_volunteerPickup ? 'volunteer_pickup' : 'self_dropoff')
        : null;
    final pickup = _type == 'material' && _volunteerPickup
        ? _pickupLocationController.text.trim()
        : null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PaymentScreen(
          request: requestModel,
          amount: quantity,
          donationType: _type == 'money' ? 'money' : 'goods',
          fulfillmentType: fulfillment,
          pickupLocation: pickup,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! DonationRequest) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('Offer Donation'),
          backgroundColor: AppTheme.primaryTeal,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Something went wrong opening this request.\nPlease go back and try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppTheme.statusError),
          ),
        ),
      );
    }
    final request = args;

    // Set initial values once from the selected request.
    if (!_initializedFromRequest) {
      _initializedFromRequest = true;
      _type = request.category.toLowerCase() == 'funds' ? 'money' : 'material';
      final needed = request.quantityNeeded;
      if (needed > 0) {
        _quantityController.text = needed.toString();
      }
      if (_type == 'material' && request.location.isNotEmpty) {
        _pickupLocationController.text = request.location;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildGradientHeader(context)),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: _buildFormCard(context, request),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 60,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Offer Donation',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fill in the details to make your contribution',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, DonationRequest request) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.deepShadow,
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism,
                        color: Color(0xFFFF6D00),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${request.categoryDisplay ?? request.category} • ${request.location}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF78909C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.statusError.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.statusError.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.statusError,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.statusError,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Donation Type',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F8FA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.navy),
                controller: TextEditingController(
                  text: _type == 'money' ? 'Money' : 'Goods',
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Quantity',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  hintText:
                      'Enter quantity (needed: ${request.quantityNeeded})',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF78909C),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F8FA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryTeal,
                      width: 2,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.navy),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null || int.parse(v) < 1) {
                    return 'Enter a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Message (optional)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Add a message for the requester...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF78909C),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F8FA),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryTeal,
                      width: 2,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.navy),
                maxLines: 3,
              ),
              if (_type == 'material') ...[
                const SizedBox(height: 20),
                Text(
                  'How will items reach the organization?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 10),
                _FulfillmentOptionTile(
                  title: 'I will drop off myself',
                  subtitle: 'You deliver items directly (no volunteer pickup).',
                  icon: Icons.storefront_rounded,
                  selected: !_volunteerPickup,
                  onTap: () => setState(() => _volunteerPickup = false),
                ),
                const SizedBox(height: 8),
                _FulfillmentOptionTile(
                  title: 'Request volunteer pickup',
                  subtitle: 'A volunteer can claim pickup from your address.',
                  icon: Icons.local_shipping_rounded,
                  selected: _volunteerPickup,
                  onTap: () => setState(() => _volunteerPickup = true),
                ),
                if (_volunteerPickup) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Pickup location',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pickupLocationController,
                    decoration: InputDecoration(
                      hintText: 'Street, area, city — where to collect items',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF78909C),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F8FA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryTeal,
                          width: 2,
                        ),
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.navy,
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.colorShadow(const Color(0xFFFF9800)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _loading ? null : () => _submit(request),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Submit Offer',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
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
    );
  }
}

class _FulfillmentOptionTile extends StatelessWidget {
  const _FulfillmentOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryTeal.withValues(alpha: 0.08)
                : const Color(0xFFF5F8FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.primaryTeal : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? AppTheme.primaryTeal
                    : const Color(0xFF78909C),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.navy,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal),
            ],
          ),
        ),
      ),
    );
  }
}
