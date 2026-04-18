import 'dart:math' show cos, sqrt, asin;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../shared/models/donation_request.dart';
import '../shared/providers/auth_provider.dart';
import '../core/services/sharecare_api_service.dart';
import '../core/utils/network_error_helper.dart';
import '../core/utils/app_routes.dart';
import '../shared/widgets/donation_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationRequest> _requests = [];
  List<DonationRequest> _recommendations = [];
  bool _loading = true;
  String? _error;
  String? _categoryFilter;
  bool _urgentOnly = false;
  Position? _userPosition;
  final double _radiusKm = 10.0;
  final bool _nearbyOnly = false;

  /// Real-time count of completed donations (lives touched).
  int? _livesTouched;

  Future<void> _loadRequests() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _ensureLocation();
      final list = await _api.getRequests(
        authHeaders: auth.authHeaders,
        status: 'open',
      );
      if (mounted) setState(() => _requests = list);
      try {
        final recs = await _api.getRecommendations(auth.authHeaders);
        if (mounted) setState(() => _recommendations = recs);
      } catch (_) {}
      // Load global impact stats (real-time "lives touched").
      try {
        final stats = await _api.getDonationStats(auth.authHeaders);
        if (mounted) {
          final lives = (stats['lives_touched'] as num?)?.toInt() ?? 0;
          setState(() => _livesTouched = lives);
        }
      } catch (_) {
        if (mounted) setState(() => _livesTouched = 0);
      }
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
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DonationRequest> get _filteredRequests {
    var list = _requests;
    if (_categoryFilter != null) {
      list = list.where((r) => r.category == _categoryFilter).toList();
    }
    if (_urgentOnly) {
      list = list.where((r) => r.urgency == 'High').toList();
    }
    if (_userPosition != null) {
      final List<MapEntry<DonationRequest, double>> scored = [];
      for (final r in list) {
        if (r.latitude != null && r.longitude != null) {
          final d = _distanceKm(
            _userPosition!.latitude,
            _userPosition!.longitude,
            r.latitude!,
            r.longitude!,
          );
          if (!_nearbyOnly || d <= _radiusKm) {
            scored.add(MapEntry(r, d));
          }
        } else if (!_nearbyOnly) {
          scored.add(MapEntry(r, double.infinity));
        }
      }
      scored.sort((a, b) => a.value.compareTo(b.value));
      list = scored.map((e) => e.key).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
  }

  /// Distance in km (Haversine) between two lat/lng pairs.
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi/180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _ensureLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) {
        _userPosition = pos;
      }
    } catch (_) {
      // Ignore failures; app still works without nearby sort.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName =
        auth.user?.firstName != null && auth.user!.firstName!.isNotEmpty
        ? auth.user!.firstName!
        : (auth.user?.username ?? 'Guest');
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, displayName, auth),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImpactCard(context),
                  const SizedBox(height: 20),
                  _buildDonateNowButton(context),
                  if (_recommendations.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                      context,
                      'Recommended for You',
                      Icons.auto_awesome_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildRecommendationCards(context),
                  ],
                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    context,
                    'Pick a cause',
                    Icons.grid_view_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildCategoryGrid(context),
                  const SizedBox(height: 28),
                  _buildNearYouHeader(context),
                  const SizedBox(height: 12),
                  _buildFilterChips(context),
                ],
              ),
            ),
          ),
          _buildNearYouList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String displayName,
    AuthProvider auth,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: MediaQuery.of(context).padding.top + 16,
          bottom: 24,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              child: Icon(
                Icons.volunteer_activism_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $displayName!',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Explore campaigns and donate with confidence',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderIconButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.conversations),
                        ),
                        const SizedBox(width: 8),
                        _HeaderIconButton(
                          icon: Icons.notifications_outlined,
                          showBadge: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.notifications),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.primaryTeal.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: AppTheme.deepShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryTeal, AppTheme.primaryTealDark],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.colorShadow(AppTheme.primaryTeal),
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Impact',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.navyLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_livesTouched ?? 0} Lives Touched',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.donationHistory),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateNowButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.colorShadow(AppTheme.accentOrange),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => ShareCareMainShellScope.maybeSwitchToTab?.call(1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                'Donate Now',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryTeal),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.navy,
          ),
        ),
      ],
    );
  }

  static const List<Map<String, dynamic>> _categories = [
    {
      'key': 'food',
      'label': 'Food',
      'icon': Icons.restaurant_rounded,
      'color': AppTheme.categoryFoodIcon,
    },
    {
      'key': 'clothes',
      'label': 'Clothes',
      'icon': Icons.checkroom_rounded,
      'color': AppTheme.categoryClothesIcon,
    },
    {
      'key': 'funds',
      'label': 'Funds',
      'icon': Icons.attach_money_rounded,
      'color': AppTheme.categoryFundsIcon,
    },
    {
      'key': 'blood',
      'label': 'Blood',
      'icon': Icons.water_drop_rounded,
      'color': AppTheme.categoryBloodIcon,
    },
    {
      'key': 'organ',
      'label': 'Organ',
      'icon': Icons.favorite_rounded,
      'color': AppTheme.categoryOrganIcon,
    },
    {
      'key': 'other',
      'label': 'Other',
      'icon': Icons.more_horiz_rounded,
      'color': AppTheme.categoryOtherIcon,
    },
  ];

  Widget _buildCategoryGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      // Slightly taller tiles so text never overflows on smaller devices.
      childAspectRatio: 0.8,
      children: _categories.map((c) {
        final color = c['color'] as Color;
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.categoryRequests,
              arguments: {
                'categoryKey': c['key'] as String,
                'categoryLabel': '${c['label']} Donations',
                'subtitle': '',
              },
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: color.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.colorShadow(color),
                  ),
                  child: Icon(
                    c['icon'] as IconData,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  c['label'] as String,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navy,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNearYouHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: AppTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Near You',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.navy,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.searchFilter),
          child: Text(
            'See All',
            style: GoogleFonts.poppins(
              color: AppTheme.primaryTeal,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipWidget(
          label: 'Food',
          selected: _categoryFilter == 'food',
          onSelected: (v) =>
              setState(() => _categoryFilter = v ? 'food' : null),
          color: AppTheme.categoryFoodIcon,
        ),
        _FilterChipWidget(
          label: 'Clothes',
          selected: _categoryFilter == 'clothes',
          onSelected: (v) =>
              setState(() => _categoryFilter = v ? 'clothes' : null),
          color: AppTheme.categoryClothesIcon,
        ),
        _FilterChipWidget(
          label: 'Urgent',
          selected: _urgentOnly,
          onSelected: (v) => setState(() => _urgentOnly = v),
          color: AppTheme.chipUrgent,
        ),
      ],
    );
  }

  Widget _buildNearYouList(BuildContext context) {
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
        ),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.statusError.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppTheme.statusError,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadRequests,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final list = _filteredRequests;
    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_rounded,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'No open requests near you.',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final r = list[index];
          return ModernDonationCard(
            request: r,
            onTap: () => Navigator.of(context)
                .pushNamed(AppRoutes.requestDetail, arguments: r)
                .then((_) => _loadRequests()),
            distanceKm:
                _userPosition != null &&
                    r.latitude != null &&
                    r.longitude != null
                ? _distanceKm(
                    _userPosition!.latitude,
                    _userPosition!.longitude,
                    r.latitude!,
                    r.longitude!,
                  )
                : null,
          );
        }, childCount: list.length),
      ),
    );
  }

  Widget _buildRecommendationCards(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: _recommendations.take(6).length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final r = _recommendations[index];
          return CompactDonationCard(
            request: r,
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.requestDetail, arguments: r),
          );
        },
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (showBadge)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipWidget extends StatelessWidget {
  const _FilterChipWidget({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.color,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade200),
          boxShadow: selected ? AppTheme.colorShadow(color) : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

void Function(int index)? _mainShellSwitchTab;

void setShareCareMainShellSwitchTab(void Function(int index)? fn) {
  _mainShellSwitchTab = fn;
}

abstract class ShareCareMainShellScope {
  static void Function(int index)? get maybeSwitchToTab => _mainShellSwitchTab;
}
