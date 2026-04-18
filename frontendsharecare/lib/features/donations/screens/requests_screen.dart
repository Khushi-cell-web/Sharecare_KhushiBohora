import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../core/utils/app_routes.dart';
import '../../../shared/models/donation_request.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/request_model.dart';
import '../widgets/request_card.dart';

/// Requests page: all donation requests from NGOs/Hospitals (from API).
/// Shared by Donor and Volunteer roles.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationRequest> _apiRequests = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _filterCategory;
  String? _filterUrgency;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() {
        _loading = false;
        _error = 'Please log in to view donation requests.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getRequests(
        authHeaders: auth.authHeaders,
        status: 'open',
      );
      if (mounted) {
        setState(() {
          _apiRequests = list;
          _error = null;
        });
      }
    } on ShareCareApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        final refreshed = await auth.tryRefreshToken();
        if (refreshed) {
          _load();
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
        final msg = NetworkErrorHelper.toUserMessage(e);
        setState(
          () => _error = msg.contains('Given token')
              ? 'Session expired. Please log in again.'
              : msg,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const List<String> _categories = [
    'Food',
    'Clothes',
    'Funds',
    'Blood',
    'Organ',
    'Other',
  ];

  static const List<String> _urgencyLevels = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<RequestModel> get _filteredRequests {
    var list = _apiRequests
        .map(
          (r) => RequestModel(
            id: r.id.toString(),
            title: r.title,
            description: r.description,
            category: r.categoryDisplay ?? r.category,
            quantityNeeded: r.quantityNeeded,
            urgency: r.urgency ?? 'Medium',
            organizationName: r.organization ?? r.createdByUsername ?? 'NGO',
            location: r.location,
          ),
        )
        .toList();

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((r) {
        return r.title.toLowerCase().contains(q) ||
            r.category.toLowerCase().contains(q) ||
            r.organizationName.toLowerCase().contains(q);
      }).toList();
    }

    if (_filterCategory != null) {
      list = list.where((r) => r.category == _filterCategory).toList();
    }

    if (_filterUrgency != null) {
      list = list.where((r) => r.urgency == _filterUrgency).toList();
    }

    return list;
  }

  Future<void> _showFilterBottomSheet() async {
    String? category = _filterCategory;
    String? urgency = _filterUrgency;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spaceMd,
          right: AppTheme.spaceMd,
          top: AppTheme.spaceMd,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreenDark,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All categories'),
                ),
                ..._categories.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (v) => category = v,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            DropdownButtonFormField<String>(
              initialValue: urgency,
              decoration: const InputDecoration(
                labelText: 'Urgency',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any urgency')),
                ..._urgencyLevels.map(
                  (u) => DropdownMenuItem(value: u, child: Text(u)),
                ),
              ],
              onChanged: (v) => urgency = v,
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    category = null;
                    urgency = null;
                    Navigator.maybePop(context);
                    setState(() {
                      _filterCategory = null;
                      _filterUrgency = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.maybePop(context);
                      setState(() {
                        _filterCategory = category;
                        _filterUrgency = urgency;
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredRequests;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Requests'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _searchFocusNode.requestFocus(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by title, category, or organization...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryTeal,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                filled: true,
                fillColor: AppTheme.surfaceWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
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
                : list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 72,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        Text(
                          'No requests available yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreenDark,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceMd,
                      0,
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) =>
                        RequestCard(request: list[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
