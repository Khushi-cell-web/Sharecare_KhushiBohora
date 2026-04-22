import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/services/sharecare_api_service.dart';
import '../core/utils/network_error_helper.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/models/donation_request.dart' as shared;
import '../features/donations/models/donation_request.dart';
import '../features/donations/screens/donation_details_screen.dart';
import '../features/donations/widgets/donation_card.dart';
import '../widgets/empty_error_state.dart';

/// Search & Filter: category, urgency, location filters + results from API.
class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<shared.DonationRequest> _requests = [];
  bool _loading = true;
  String? _error;
  String? _categoryFilter;
  String? _urgencyFilter;
  String _locationQuery = '';
  DateTime? _dateFrom;
  final _locationController = TextEditingController();

  static const List<Map<String, String>> _categories = [
    {'value': 'food', 'label': 'Food'},
    {'value': 'clothes', 'label': 'Clothes'},
    {'value': 'funds', 'label': 'Funds'},
    {'value': 'blood', 'label': 'Blood'},
    {'value': 'organ', 'label': 'Organ'},
    {'value': 'other', 'label': 'Other'},
  ];

  static const List<Map<String, String>> _urgencyLevels = [
    {'value': 'low', 'label': 'Low'},
    {'value': 'medium', 'label': 'Medium'},
    {'value': 'high', 'label': 'High'},
    {'value': 'urgent', 'label': 'Urgent'},
  ];

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
          _error = 'Please log in to search requests.';
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String? urgency = _urgencyFilter;
      if (urgency == 'urgent') urgency = 'High';
      if (urgency == 'low') urgency = 'Low';
      if (urgency == 'medium') urgency = 'Medium';
      if (urgency == 'high') urgency = 'High';
      final list = await _api.getRequests(
        authHeaders: auth.authHeaders,
        status: 'open',
        category: _categoryFilter,
        urgency: urgency,
      );
      if (mounted) {
        setState(() {
          _requests = list;
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

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  List<DonationRequestModel> get _filteredRequests {
    var list = _requests
        .map((r) => DonationRequestModel.fromDonationRequest(r))
        .toList();
    if (_locationQuery.trim().isNotEmpty) {
      final q = _locationQuery.trim().toLowerCase();
      list = list.where((r) => r.location.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> _pickDateFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _dateFrom = d);
  }

  void _clearAllFilters() {
    setState(() {
      _categoryFilter = null;
      _urgencyFilter = null;
      _locationQuery = '';
      _locationController.clear();
      _dateFrom = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRequests;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient header ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 28,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Search & Filter',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearAllFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Clear',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white24, Colors.white10],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loading
                        ? 'Searching…'
                        : _error != null
                        ? 'Something went wrong'
                        : '${filtered.length} ${filtered.length == 1 ? 'result' : 'results'} found',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _locationController,
                    onChanged: (v) => setState(() => _locationQuery = v),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Filter by location…',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.12),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Filter chips ──
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd,
                vertical: 14,
              ),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Category',
                    value: _categoryFilter == null
                        ? 'All'
                        : (_categories.firstWhere(
                                (c) => c['value'] == _categoryFilter,
                                orElse: () => {'label': _categoryFilter!},
                              ))['label'] ??
                              _categoryFilter!,
                    selected: _categoryFilter != null,
                    onTap: () async {
                      final v = await showModalBottomSheet<String?>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text(
                                  'All',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () => Navigator.maybePop(ctx, null),
                              ),
                              ..._categories.map(
                                (c) => ListTile(
                                  title: Text(c['label']!),
                                  onTap: () =>
                                      Navigator.maybePop(ctx, c['value']),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (v != null && mounted) {
                        setState(() => _categoryFilter = v);
                        _load();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Urgency',
                    value: _urgencyFilter == null
                        ? 'All'
                        : (_urgencyLevels.firstWhere(
                                (u) => u['value'] == _urgencyFilter,
                                orElse: () => {'label': _urgencyFilter!},
                              ))['label'] ??
                              _urgencyFilter!,
                    selected: _urgencyFilter != null,
                    onTap: () async {
                      final v = await showModalBottomSheet<String?>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text(
                                  'All',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () => Navigator.maybePop(ctx, null),
                              ),
                              ..._urgencyLevels.map(
                                (u) => ListTile(
                                  title: Text(u['label']!),
                                  onTap: () =>
                                      Navigator.maybePop(ctx, u['value']),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (v != null && mounted) {
                        setState(() => _urgencyFilter = v);
                        _load();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Date',
                    value: _dateFrom != null
                        ? '${_dateFrom!.day}/${_dateFrom!.month}'
                        : 'Any',
                    selected: _dateFrom != null,
                    onTap: _pickDateFrom,
                  ),
                ],
              ),
            ),
          ),

          // ── Results count ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: Text(
                '${filtered.length} result(s)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Content ──
          if (_loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
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
              ),
            )
          else if (filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                title: 'No requests match your filters',
                subtitle: 'Try adjusting category, urgency, or location',
                icon: Icons.filter_list_rounded,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd,
                vertical: 8,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final r = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DonationCard(
                      request: r,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DonationDetailsScreen(request: r),
                        ),
                      ),
                    ),
                  );
                }, childCount: filtered.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryTeal : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: selected ? AppTheme.primaryTeal : AppTheme.textTertiary,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: selected ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.primaryTeal,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: selected ? Colors.white : AppTheme.primaryTeal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
