import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/volunteer_task.dart';

/// Map view for a volunteer task.
class LeafletVolunteerTaskMapScreen extends StatefulWidget {
  const LeafletVolunteerTaskMapScreen({super.key, required this.task});

  final VolunteerTask task;

  @override
  State<LeafletVolunteerTaskMapScreen> createState() =>
      _LeafletVolunteerTaskMapScreenState();
}

class _LeafletVolunteerTaskMapScreenState
    extends State<LeafletVolunteerTaskMapScreen> {
  final MapController _mapController = MapController();
  static const double _defaultZoom = 13.0;

  List<Marker> get _markers {
    final List<Marker> m = [];
    if (widget.task.pickupLatitude != null &&
        widget.task.pickupLongitude != null) {
      m.add(
        Marker(
          point: LatLng(
            widget.task.pickupLatitude!,
            widget.task.pickupLongitude!,
          ),
          width: 40,
          height: 40,
          child: Tooltip(
            message: 'Pickup: ${widget.task.pickupLocation}',
            child: const Icon(
              Icons.flag_rounded,
              color: Colors.orange,
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

    if (widget.task.deliveryLatitude != null &&
        widget.task.deliveryLongitude != null) {
      m.add(
        Marker(
          point: LatLng(
            widget.task.deliveryLatitude!,
            widget.task.deliveryLongitude!,
          ),
          width: 40.0,
          height: 40.0,
          child: Tooltip(
            message: 'Delivery: ${widget.task.deliveryLocation}',
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
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

    return m;
  }

  LatLng get _center {
    if (widget.task.pickupLatitude != null &&
        widget.task.pickupLongitude != null) {
      return LatLng(widget.task.pickupLatitude!, widget.task.pickupLongitude!);
    }
    if (widget.task.deliveryLatitude != null &&
        widget.task.deliveryLongitude != null) {
      return LatLng(
        widget.task.deliveryLatitude!,
        widget.task.deliveryLongitude!,
      );
    }
    return const LatLng(27.7172, 85.3240);
  }

  Future<void> _openInGoogleMaps({bool toDelivery = true}) async {
    final lat = toDelivery ? widget.task.deliveryLatitude : null;
    final lng = toDelivery ? widget.task.deliveryLongitude : null;
    final dest = lat != null && lng != null
        ? '$lat,$lng'
        : Uri.encodeComponent(
            toDelivery
                ? widget.task.deliveryLocation
                : widget.task.pickupLocation,
          );
    final origin = Uri.encodeComponent(widget.task.pickupLocation);
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task.donationRequestTitle ?? 'Task Map',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => _openInGoogleMaps(),
            icon: const Icon(
              Icons.directions_rounded,
              size: 20,
              color: Colors.white,
            ),
            label: const Text(
              'Directions',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
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
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.task.pickupLocation,
                      style: GoogleFonts.poppins(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Delivery',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.task.deliveryLocation,
                      style: GoogleFonts.poppins(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openInGoogleMaps(),
                        icon: const Icon(Icons.directions_rounded, size: 20),
                        label: const Text('Open in Google Maps'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
