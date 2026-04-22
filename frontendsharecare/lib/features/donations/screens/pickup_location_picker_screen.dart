import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';

import '../../../core/theme/app_theme.dart';

/// OpenStreetMap: tap to place pickup marker; confirm lat/lng (and optional address).
class PickupLocationPickerScreen extends StatefulWidget {
  const PickupLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.title = 'Select pickup location',
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final String title;

  @override
  State<PickupLocationPickerScreen> createState() =>
      _PickupLocationPickerScreenState();
}

class PickupLocationPickerResult {
  const PickupLocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}

class _PickupLocationPickerScreenState
    extends State<PickupLocationPickerScreen> {
  static const double _defaultLat = 27.7172;
  static const double _defaultLng = 85.3240;
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const Map<String, String> _nominatimHeaders = {
    'User-Agent': 'ShareCare/1.0 (frontendsharecare)',
    'Accept': 'application/json',
    'Accept-Language': 'en',
  };

  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  LatLng? _point;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLatitude ?? _defaultLat;
    final lng = widget.initialLongitude ?? _defaultLng;
    _point = LatLng(lat, lng);
    _reverseGeocode(lat, lng);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _confirm() {
    final p = _point;
    if (p == null) return;
    final resolvedAddress = _addressController.text.trim().isEmpty
        ? '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}'
        : _addressController.text.trim();
    Navigator.maybePop(
      context,
      PickupLocationPickerResult(
        latitude: p.latitude,
        longitude: p.longitude,
        address: resolvedAddress,
      ),
    );
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    if (!mounted) return;
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
      final displayName = (data['display_name'] as String?)?.trim() ?? '';
      if (!mounted) return;
      final text = displayName.isEmpty
          ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
          : displayName;
      _addressController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } catch (_) {
      if (!mounted) return;
      final fallback = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
      _addressController.value = TextEditingValue(
        text: fallback,
        selection: TextSelection.collapsed(offset: fallback.length),
      );
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _point ?? LatLng(_defaultLat, _defaultLng);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
                onTap: (tapPosition, latlng) {
                  setState(() => _point = latlng);
                  _reverseGeocode(latlng.latitude, latlng.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: AppTheme.mapTileUrlTemplate,
                  subdomains: AppTheme.mapTileSubdomains,
                  userAgentPackageName: 'com.example.frontendsharecare',
                  tileProvider: CancellableNetworkTileProvider(),
                ),
                if (_point != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _point!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.place,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tap the map to place the marker. Add a short address label if you like.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address / landmark',
                      helperText:
                          'Auto-filled from map pin; you can edit if needed',
                      suffixIcon: _loadingAddress
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _point != null
                        ? 'Lat: ${_point!.latitude.toStringAsFixed(5)}, Lng: ${_point!.longitude.toStringAsFixed(5)}'
                        : 'No point selected',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _point == null ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Use this pickup location'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
