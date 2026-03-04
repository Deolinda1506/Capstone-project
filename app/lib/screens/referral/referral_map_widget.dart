import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/map_constants.dart';

/// Map widget showing Gasabo District Hospital
/// Uses OpenStreetMap via flutter_map - no API key required
class ReferralMapWidget extends StatelessWidget {
  final double height;

  const ReferralMapWidget({super.key, this.height = 200});

  static final LatLng _hospitalPosition = LatLng(
    MapConstants.gasaboHospitalLat,
    MapConstants.gasaboHospitalLng,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _hospitalPosition,
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.carotidcheck.carotid_check',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _hospitalPosition,
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens Google Maps for directions to a hospital
Future<void> openDirectionsToHospital({double? lat, double? lng}) async {
  final destLat = lat ?? MapConstants.gasaboHospitalLat;
  final destLng = lng ?? MapConstants.gasaboHospitalLng;
  final url = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng',
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
