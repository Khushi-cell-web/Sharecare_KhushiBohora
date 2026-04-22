import 'dart:math' show cos, sqrt, asin;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/network_error_helper.dart';
import '../core/services/sharecare_api_service.dart';
import '../shared/models/donation_request.dart';
import '../shared/providers/auth_provider.dart';

/// Donation map with user location and request markers.
class LeafletDonationMapScreen extends StatefulWidget {
  const LeafletDonationMapScreen({super.key});

  @override
  State<LeafletDonationMapScreen> createState() =>
      _LeafletDonationMapScreenState();
}

class _LeafletDonationMapScreenState extends State<LeafletDonationMapScreen> {
  static const double _defaultLat = 27.7172;
  static const double _defaultLng = 85.3240;
  static const double _defaultZoom = 12.0;

  final ShareCareApiService _api = ShareCareApiService();
  final MapController _mapController = MapController();
  Position? _userPosition;
  List<DonationRequest> _allRequests = [];
  List<DonationRequest> _visibleRequests = [];
  String? _categoryFilter; // null = all
  double _radiusKm = 10.0; // 5 or 10 km for "nearby"
  bool _nearbyOnly = false;
  bool _loading = true;
  String? _error;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _requestLocationAndLoad();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _locationError = 'Location services are disabled');
      }
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _locationError = 'Location permission denied');
      }
      return;
    }
    if (permission == LocationPermission.denied) {
      if (mounted) {
        setState(() => _locationError = 'Location permission denied');
      }
      return;
    }
    if (mounted) setState(() => _locationError = null);
  }

  Future<void> _requestLocationAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
      _locationError = null;
    });
    await _requestLocationPermission();
    if (!mounted) return;
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
      } catch (_) {
        // Keep default map center.
      }
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final list = await _api.getRequests(
        authHeaders: auth.isAuthenticated ? auth.authHeaders : null,
        status: 'open',
      );
      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _allRequests = list
            .where((r) => r.latitude != null && r.longitude != null)
            .toList();
        _applyFilters();
        _loading = false;
      });
      // Center on user first, otherwise first marker.
      if (_userPosition != null) {
        _mapController.move(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          _defaultZoom,
        );
      } else if (_visibleRequests.isNotEmpty) {
        final r = _visibleRequests.first;
        _mapController.move(LatLng(r.latitude!, r.longitude!), _defaultZoom);
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
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    var list = List<DonationRequest>.from(_allRequests);
    if (_categoryFilter != null) {
      list = list.where((r) => r.category == _categoryFilter).toList();
    }
    if (_nearbyOnly && _userPosition != null) {
      list = list.where((r) {
        final d = _distanceKm(
          _userPosition!.latitude,
          _userPosition!.longitude,
          r.latitude!,
          r.longitude!,
        );
        return d <= _radiusKm;
      }).toList();
    }
    setState(() => _visibleRequests = list);
  }

  /// Distance in km using Haversine.
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi/180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2*R*asin...
  }

  Color _colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return AppTheme.primaryPinkDark;
      case 'clothes':
        return Colors.blue;
      case 'funds':
        return Colors.orange;
      case 'blood':
        return Colors.red;
      case 'organ':
        return AppTheme.primaryPinkColor;
      default:
        return Colors.grey;
    }
  }

  List<Marker> get _markers {
    final list = <Marker>[];

    if (_userPosition != null) {
      list.add(
        Marker(
          point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          width: 40.0,
          height: 40.0,
          child: const Tooltip(
            message: 'Your location',
            child: Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 40,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black26,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (final r in _visibleRequests) {
      if (r.latitude == null || r.longitude == null) continue;
      final color = _colorForCategory(r.category);
      list.add(
        Marker(
          point: LatLng(r.latitude!, r.longitude!),
          width: 40.0,
          height: 40.0,
          child: GestureDetector(
            onTap: () => _showDonationBottomSheet(r),
            child: Tooltip(
              message: r.title,
              child: Icon(
                Icons.location_on,
                color: color,
                size: 40,
                shadows: const [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black26,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return list;
  }

  LatLng get _center {
    if (_userPosition != null) {
      return LatLng(_userPosition!.latitude, _userPosition!.longitude);
    }
    if (_visibleRequests.isNotEmpty &&
        _visibleRequests.first.latitude != null) {
      final r = _visibleRequests.first;
      return LatLng(r.latitude!, r.longitude!);
    }
    return const LatLng(_defaultLat, _defaultLng);
  }

  void _showDonationBottomSheet(DonationRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LeafletDonationMapBottomSheet(
        request: request,
        distanceKm:
            _userPosition != null &&
                request.latitude != null &&
                request.longitude != null
            ? _distanceKm(
                _userPosition!.latitude,
                _userPosition!.longitude,
                request.latitude!,
                request.longitude!,
              )
            : null,
        onViewDonation: () {
          Navigator.maybePop(context);
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.requestDetail, arguments: request);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Donation Map',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _requestLocationAndLoad,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppTheme.statusError,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: GoogleFonts.poppins(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _requestLocationAndLoad,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _defaultZoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppTheme.mapTileUrlTemplate,
                      subdomains: AppTheme.mapTileSubdomains,
                      userAgentPackageName: 'com.example.frontendsharecare',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
                // Loading overlay
                if (_loading)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                // Top filter chips
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location error banner
                      if (_locationError != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.statusWarning.withValues(
                              alpha: 0.1,
                            ),
                            border: Border.all(color: AppTheme.statusWarning),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_off,
                                color: AppTheme.statusWarning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _locationError!,
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Filter chips
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Nearby'),
                            selected: _nearbyOnly,
                            onSelected: (v) {
                              setState(() => _nearbyOnly = v);
                              _applyFilters();
                            },
                          ),
                          if (_nearbyOnly)
                            ChoiceChip(
                              label: Text('${_radiusKm.toInt()} km'),
                              selected: true,
                              onSelected: (_) {
                                setState(
                                  () => _radiusKm = _radiusKm == 5 ? 10 : 5,
                                );
                                _applyFilters();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Bottom sheet showing donation details when marker is tapped.
class _LeafletDonationMapBottomSheet extends StatelessWidget {
  const _LeafletDonationMapBottomSheet({
    required this.request,
    this.distanceKm,
    required this.onViewDonation,
  });

  final DonationRequest request;
  final double? distanceKm;
  final VoidCallback onViewDonation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                request.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Category & distance
              Row(
                children: [
                  Chip(
                    label: Text(request.categoryDisplay ?? request.category),
                  ),
                  const SizedBox(width: 8),
                  if (distanceKm != null)
                    Chip(
                      label: Text('${distanceKm!.toStringAsFixed(1)} km away'),
                      avatar: const Icon(Icons.location_on_outlined, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              if (request.description.isNotEmpty)
                Text(
                  request.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.navy,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              // CTAs
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onViewDonation,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View Full Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
