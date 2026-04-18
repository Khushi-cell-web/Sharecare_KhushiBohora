import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_routes.dart';
import '../shared/models/donation_request.dart';
import '../shared/providers/auth_provider.dart';
import '../core/services/sharecare_api_service.dart';
import '../core/utils/network_error_helper.dart';
import '../features/donations/widgets/donation_form_components.dart';
import '../shared/widgets/modern_button.dart';
import '../shared/widgets/error_notification.dart';

/// Donation screen with request list and request form modes.
class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  /// True shows request list, false shows request form.
  bool _wantToDonate = true;

  // Request form state
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  String _category = 'food';
  String _urgency = 'medium';
  DateTime? _expectedFulfillmentDate;
  double? _pickupLat;
  double? _pickupLng;
  bool _formLoading = false;
  String? _formError;

  // Request list state
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationRequest> _requests = [];
  bool _listLoading = true;
  String? _listError;

  static const List<Map<String, dynamic>> _categories = [
    {'value': 'food', 'label': 'Food', 'icon': Icons.restaurant_rounded},
    {'value': 'clothes', 'label': 'Clothes', 'icon': Icons.checkroom_rounded},
    {
      'value': 'medicine',
      'label': 'Medicine',
      'icon': Icons.medication_rounded,
    },
    {'value': 'blood', 'label': 'Blood', 'icon': Icons.water_drop_rounded},
    {'value': 'funds', 'label': 'Money', 'icon': Icons.attach_money_rounded},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  static const List<Map<String, dynamic>> _urgencyLevels = [
    {'value': 'low', 'label': 'Low', 'color': AppTheme.statusSuccess},
    {'value': 'medium', 'label': 'Medium', 'color': AppTheme.statusWarning},
    {'value': 'high', 'label': 'High', 'color': AppTheme.chipUrgent},
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  /// Small progress header used in form mode.
  Widget _buildStepProgress(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step 1 of 3',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const Spacer(),
              Text(
                'Basic → Location → Timeline',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1.0,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExpectedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expectedFulfillmentDate ??
          DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _expectedFulfillmentDate = picked);
    }
  }

  Future<void> _loadRequests() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() {
        _listLoading = false;
        _listError = 'Please log in to view requests.';
      });
      return;
    }
    setState(() {
      _listLoading = true;
      _listError = null;
    });
    try {
      final list = await _api.getRequests(
        authHeaders: auth.authHeaders,
        status: 'open',
      );
      if (mounted) setState(() => _requests = list);
    } on ShareCareApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        final refreshed = await auth.tryRefreshToken();
        if (refreshed) {
          _loadRequests();
          return;
        }
        await auth.logout();
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
        }
        return;
      }
      if (mounted) {
        setState(() => _listError = NetworkErrorHelper.toUserMessage(e));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _listError = NetworkErrorHelper.toUserMessage(e));
      }
    } finally {
      if (mounted) setState(() => _listLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _formLoading = true;
      _formError = null;
    });
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (mounted) {
        setState(() => _formError = 'Please log in to create a request');
        setState(() => _formLoading = false);
      }
      return;
    }
    try {
      await _api.createRequest(
        auth.authHeaders,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        quantityNeeded: int.tryParse(_quantityController.text) ?? 1,
        location: _locationController.text.trim(),
        latitude: _pickupLat,
        longitude: _pickupLng,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request created')));
        Navigator.maybePop(context);
      }
    } on ShareCareApiException catch (e) {
      if (mounted) {
        setState(() => _formError = NetworkErrorHelper.toUserMessage(e));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _formError = NetworkErrorHelper.toUserMessage(e));
      }
    } finally {
      if (mounted) setState(() => _formLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 40,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: MediaQuery.of(context).padding.top + 12,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 16),
                        Text(
                          'Create Donation',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share kindness with those in need',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Builder(
                builder: (context) {
                  final auth = context.watch<AuthProvider>();
                  final user = auth.user;
                  final isNgo = user?.isNgo ?? false;
                  return Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.deepShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ToggleChip(
                            label: 'I Want to Donate',
                            selected: _wantToDonate,
                            onTap: () => setState(() => _wantToDonate = true),
                          ),
                        ),
                        if (isNgo) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: _ToggleChip(
                              label: 'I Need Help',
                              selected: !_wantToDonate,
                              onTap: () =>
                                  setState(() => _wantToDonate = false),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_wantToDonate) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Select a request to donate to',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navy,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.user?.isNgo == true) {
                      return const SizedBox.shrink();
                    }
                    return OutlinedButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.standaloneDonation),
                      icon: const Icon(Icons.volunteer_activism_outlined),
                      label: const Text(
                        'Or donate freely (no specific request)',
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_listLoading)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
              )
            else if (_listError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(_listError!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadRequests,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_requests.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No open requests. Check back later or create a request under "I Need Help".',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final r = _requests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(r.title),
                        subtitle: Text(
                          '${r.categoryDisplay ?? r.category} • ${r.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.offerDonation, arguments: r)
                            .then((_) => _loadRequests()),
                      ),
                    );
                  }, childCount: _requests.length),
                ),
              ),
          ] else ...[
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final auth = context.watch<AuthProvider>();
                  final user = auth.user;
                  final isNgo = user?.isNgo ?? false;
                  final isVerifiedNgo =
                      isNgo && (user?.profile?.isVerified ?? false);
                  if (isNgo && !isVerifiedNgo) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spaceLg,
                        0,
                        AppTheme.spaceLg,
                        AppTheme.spaceMd,
                      ),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          side: BorderSide(
                            color: AppTheme.ctaOrange.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 48,
                                color: AppTheme.ctaOrange,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Verify your organization to create donation requests',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'NGOs and hospitals must submit a verification ID (e.g. registration or license number) and be approved by an admin before creating requests.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.ngoVerification),
                                icon: const Icon(
                                  Icons.badge_outlined,
                                  size: 20,
                                ),
                                label: const Text('Go to Verification Portal'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceLg,
                      0,
                      AppTheme.spaceLg,
                      AppTheme.spaceMd,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.deepShadow,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Step progress: 3 steps (Basic, Location, Timeline)
                            _buildStepProgress(context),
                            const SizedBox(height: AppTheme.spaceLg),
                            if (_formError != null) ...[
                              InlineErrorMessage(message: _formError!),
                              const SizedBox(height: AppTheme.spaceMd),
                            ],
                            Text(
                              'Category of Donation *',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: InputDecoration(
                                hintText: 'Select category',
                                filled: true,
                                fillColor: AppTheme.surfaceLightGrey,
                              ),
                              items: _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c['value'] as String,
                                      child: Row(
                                        children: [
                                          Icon(
                                            c['icon'] as IconData,
                                            size: 20,
                                            color: AppTheme.primaryTeal,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            c['label'] as String,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _category = v ?? 'food'),
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            Text(
                              'Request Title *',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                hintText:
                                    'e.g., Emergency Food Support for Flood Victims',
                                filled: true,
                                fillColor: Color(0xFFF5F8FA),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Request Description *',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                hintText:
                                    'Why donation is needed, who will benefit, urgency...',
                                filled: true,
                                fillColor: Color(0xFFF5F8FA),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 4,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Quantity Needed *',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                hintText:
                                    'Number of items/units, or amount for money',
                                filled: true,
                                fillColor: Color(0xFFF5F8FA),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (int.tryParse(v) == null ||
                                    int.parse(v) < 1) {
                                  return 'Enter a positive number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            Text(
                              'Urgency Level *',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _urgencyLevels.map((u) {
                                final value = u['value'] as String;
                                final selected = _urgency == value;
                                final color = u['color'] as Color;
                                return Material(
                                  color: selected
                                      ? color.withValues(alpha: 0.15)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _urgency = value),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSm,
                                        ),
                                        border: Border.all(
                                          color: selected
                                              ? color
                                              : Colors.grey.shade300,
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        u['label'] as String,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selected
                                              ? color
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppTheme.spaceLg),
                            Text(
                              'Location & Contact',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreenDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Location of Need *',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            PickupLocationField(
                              controller: _locationController,
                              hintText: 'Tap to pick on map or search address',
                              initialLat: _pickupLat,
                              initialLng: _pickupLng,
                              onLocationPicked: (lat, lng, _) => setState(() {
                                _pickupLat = lat;
                                _pickupLng = lng;
                              }),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Contact Person Name',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _contactPersonController,
                              decoration: const InputDecoration(
                                hintText:
                                    'Name of contact for donors/volunteers',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                                filled: true,
                                fillColor: Color(0xFFF5F8FA),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Contact Phone Number',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _contactPhoneController,
                              decoration: const InputDecoration(
                                hintText: 'Phone number for coordination',
                                prefixIcon: Icon(Icons.phone_outlined),
                                filled: true,
                                fillColor: Color(0xFFF5F8FA),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: AppTheme.spaceLg),
                            Text(
                              'Timeline',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreenDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Expected Fulfillment Date',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                              onPressed: _pickExpectedDate,
                              icon: Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: AppTheme.primaryTeal,
                              ),
                              label: Text(
                                _expectedFulfillmentDate != null
                                    ? '${_expectedFulfillmentDate!.day}/${_expectedFulfillmentDate!.month}/${_expectedFulfillmentDate!.year}'
                                    : 'Select date',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryGreenDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                side: const BorderSide(
                                  color: AppTheme.primaryTeal,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spaceMd,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceXl),
                            ModernButton(
                              label: 'Submit Request',
                              onPressed: _formLoading ? null : _submitRequest,
                              isLoading: _formLoading,
                              icon: Icons.check_rounded,
                              size: ButtonSize.large,
                              fullWidth: true,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.headerGradientWarm : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
