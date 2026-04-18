import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

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

  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  LatLng? _point;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLatitude ?? _defaultLat;
    final lng = widget.initialLongitude ?? _defaultLng;
    _point = LatLng(lat, lng);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _confirm() {
    final p = _point;
    if (p == null) return;
    Navigator.maybePop(
      context,
      PickupLocationPickerResult(
        latitude: p.latitude,
        longitude: p.longitude,
        address: _addressController.text.trim(),
      ),
    );
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
                      labelText: 'Address / landmark (optional)',
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
