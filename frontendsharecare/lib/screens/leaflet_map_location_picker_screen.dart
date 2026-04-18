import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';

import '../core/theme/app_theme.dart';
import '../shared/models/picked_location.dart';

/// Full-screen map picker with tap, search, and current location.
class LeafletMapLocationPickerScreen extends StatefulWidget {
  const LeafletMapLocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  @override
  State<LeafletMapLocationPickerScreen> createState() =>
      _LeafletMapLocationPickerScreenState();
}

class _LeafletMapLocationPickerScreenState
    extends State<LeafletMapLocationPickerScreen> {
  static const double _defaultLat = 27.7172;
  static const double _defaultLng = 85.3240;
  static const double _defaultZoom = 14.0;

  final MapController _mapController = MapController();
  LatLng? _selectedPosition;
  String _selectedAddress = '';
  bool _loadingAddress = false;
  bool _loadingCurrentLocation = false;
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const Map<String, String> _nominatimHeaders = {
    'User-Agent': 'ShareCare/1.0 (frontendsharecare)',
    'Accept': 'application/json',
    'Accept-Language': 'en',
  };

  double get _initialLat => widget.initialLat ?? _defaultLat;
  double get _initialLng => widget.initialLng ?? _defaultLng;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPosition = LatLng(widget.initialLat!, widget.initialLng!);
      _selectedAddress = widget.initialAddress ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied'),
          ),
        );
      }
      return;
    }
    if (permission == LocationPermission.denied) return;
  }

  Future<void> _useCurrentLocation() async {
    await _requestLocationPermission();
    if (!mounted) return;
    setState(() => _loadingCurrentLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      _selectedPosition = latLng;
      _mapController.move(latLng, _defaultZoom);
      await _reverseGeocode(latLng.latitude, latLng.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingCurrentLocation = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _loadingAddress = true);
    try {
      final uri = Uri.parse(
        '$_nominatimBaseUrl/reverse?format=jsonv2&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http
          .get(uri, headers: _nominatimHeaders)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Reverse geocode failed (${response.statusCode})');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      final displayName = (data['display_name'] as String?)?.trim() ?? '';
      setState(() {
        _selectedAddress = displayName;
        if (_selectedAddress.isEmpty) _selectedAddress = '$lat, $lng';
        _loadingAddress = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress =
              '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
          _loadingAddress = false;
        });
      }
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _searching = true);
    try {
      final encoded = Uri.encodeQueryComponent(query);
      final uri = Uri.parse(
        '$_nominatimBaseUrl/search?format=jsonv2&q=$encoded&limit=1&addressdetails=1',
      );
      final response = await http
          .get(uri, headers: _nominatimHeaders)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Search failed (${response.statusCode})');
      }
      final results = jsonDecode(response.body) as List<dynamic>;
      if (!mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Address not found')));
        setState(() => _searching = false);
        return;
      }
      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse((first['lat'] as String?) ?? '');
      final lon = double.tryParse((first['lon'] as String?) ?? '');
      if (lat == null || lon == null) {
        throw Exception('Invalid coordinate data');
      }
      final latLng = LatLng(lat, lon);
      setState(() {
        _selectedPosition = latLng;
      });
      _mapController.move(latLng, _defaultZoom);
      final displayName = (first['display_name'] as String?)?.trim() ?? '';
      if (displayName.isNotEmpty) {
        setState(() => _selectedAddress = displayName);
      } else {
        await _reverseGeocode(latLng.latitude, latLng.longitude);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onMapTap(LatLng position) {
    setState(() => _selectedPosition = position);
    _reverseGeocode(position.latitude, position.longitude);
  }

  void _confirm() {
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tap on the map or use current location to select a place',
          ),
        ),
      );
      return;
    }
    final address = _selectedAddress.isEmpty
        ? '${_selectedPosition!.latitude.toStringAsFixed(5)}, ${_selectedPosition!.longitude.toStringAsFixed(5)}'
        : _selectedAddress;
    Navigator.maybePop(
      context,
      PickedLocation(
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        address: address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Pick pickup location',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search address',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryTeal,
                ),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: _searching ? null : _searchAddress,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                filled: true,
                fillColor: AppTheme.surfaceWhite,
              ),
              onSubmitted: (_) => _searchAddress(),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _selectedPosition ?? LatLng(_initialLat, _initialLng),
                    initialZoom: _defaultZoom,
                    onTap: (tapPosition, latLng) => _onMapTap(latLng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppTheme.mapTileUrlTemplate,
                      subdomains: AppTheme.mapTileSubdomains,
                      userAgentPackageName: 'com.example.frontendsharecare',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                    if (_selectedPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPosition!,
                            width: 40.0,
                            height: 40.0,
                            child: const Icon(
                              Icons.location_on,
                              color: AppTheme.primaryTeal,
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
                        ],
                      ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.primaryTeal.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                            left: BorderSide(
                              color: AppTheme.primaryTeal.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                            right: BorderSide(
                              color: AppTheme.primaryTeal.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                            bottom: BorderSide(
                              color: AppTheme.primaryTeal.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AppTheme.spaceMd,
                  bottom: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'current_loc',
                        backgroundColor: AppTheme.surfaceWhite,
                        onPressed: _loadingCurrentLocation
                            ? null
                            : _useCurrentLocation,
                        child: _loadingCurrentLocation
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                color: AppTheme.primaryTeal,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loadingAddress)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_selectedAddress.isNotEmpty)
                  Text(
                    _selectedAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.navy,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _selectedPosition == null ? null : _confirm,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text('Use this location'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
