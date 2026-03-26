import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class OptimizedDriverMapScreen extends StatefulWidget {
  final List<dynamic> pickups;

  const OptimizedDriverMapScreen({
    super.key,
    required this.pickups,
  });

  @override
  State<OptimizedDriverMapScreen> createState() =>
      _OptimizedDriverMapScreenState();
}

class _OptimizedDriverMapScreenState extends State<OptimizedDriverMapScreen> {
  GoogleMapController? mapController;

  bool loading = true;
  String? error;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  LatLng? driverLatLng;
  final List<LatLng> stops = [];

  String distanceText = '';
  String durationText = '';

  static const String googleMapsApiKey =
      "AIzaSyCfDFU5SH7YP73M5iF6nbnIHekd00EMQg4";

  @override
  void initState() {
    super.initState();
    loadMapData();
  }

  Future<void> loadMapData() async {
    setState(() {
      loading = true;
      error = null;
      markers.clear();
      polylines.clear();
      stops.clear();
      distanceText = '';
      durationText = '';
    });

    try {
      final position = await _getCurrentLocation();
      driverLatLng = LatLng(position.latitude, position.longitude);

      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLatLng!,
          infoWindow: const InfoWindow(title: 'You'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );

      for (int i = 0; i < widget.pickups.length; i++) {
        final pickup = widget.pickups[i];
        final client = (pickup["client"] ?? {}) as Map<String, dynamic>;

        final dynamic latRaw = client["lat"];
        final dynamic lngRaw = client["lng"];

        if (latRaw == null || lngRaw == null) continue;

        final LatLng point = LatLng(
          (latRaw as num).toDouble(),
          (lngRaw as num).toDouble(),
        );

        stops.add(point);

        markers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: point,
            infoWindow: InfoWindow(
              title: client["fullName"]?.toString() ?? 'Stop ${i + 1}',
              snippet: _clientAddress(client),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0 ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      if (stops.isEmpty) {
        throw Exception('No valid stops with coordinates');
      }

      await _buildRoute();

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      await Future.delayed(const Duration(milliseconds: 400));
      _fitBounds();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location service is turned off');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _buildRoute() async {
    if (driverLatLng == null || stops.isEmpty) return;

    final LatLng destination = stops.last;
    final List<LatLng> waypointList =
        stops.length > 1 ? stops.sublist(0, stops.length - 1) : [];

    String waypoints = '';
    if (waypointList.isNotEmpty) {
      waypoints =
          '&waypoints=optimize:true|${waypointList.map((p) => '${p.latitude},${p.longitude}').join('|')}';
    }

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${driverLatLng!.latitude},${driverLatLng!.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '$waypoints'
        '&mode=driving'
        '&key=$googleMapsApiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route');
    }

    if (data["status"] != "OK") {
      throw Exception(data["error_message"] ?? 'Route error');
    }

    final route = data["routes"][0];
    final String polyline = route["overview_polyline"]["points"];
    final List<LatLng> points = _decodePolyline(polyline);

    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        width: 6,
        color: Colors.green,
      ),
    );

    double totalDistance = 0;
    double totalDuration = 0;

    for (final leg in route["legs"]) {
      totalDistance += (leg["distance"]["value"] as num).toDouble();
      totalDuration += (leg["duration"]["value"] as num).toDouble();
    }

    distanceText = _formatDistance(totalDistance);
    durationText = _formatDuration(totalDuration);
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      while (true) {
        final int b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
        if (b < 32) break;
      }

      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;

      while (true) {
        final int b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
        if (b < 32) break;
      }

      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return poly;
  }

  void _fitBounds() {
    if (mapController == null || driverLatLng == null || stops.isEmpty) return;

    final allPoints = [driverLatLng!, ...stops];

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (final point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  String _clientAddress(Map<String, dynamic> client) {
    return [
      (client["townArea"] ?? "").toString(),
      (client["landmark"] ?? "").toString(),
      (client["zone"] ?? "").toString(),
    ].where((e) => e.trim().isNotEmpty).join(' / ');
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatDuration(double seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} min';
  }

  Future<void> openExternalMaps() async {
    if (driverLatLng == null || stops.isEmpty) return;

    final LatLng destination = stops.last;

    final String waypoints = stops.length > 1
        ? '&waypoints=${stops.sublist(0, stops.length - 1).map((p) => '${p.latitude},${p.longitude}').join('|')}'
        : '';

    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${driverLatLng!.latitude},${driverLatLng!.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '$waypoints'
      '&travelmode=driving',
    );

    final opened = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> nextClient = widget.pickups.isNotEmpty
        ? ((widget.pickups.first["client"] ?? {}) as Map<String, dynamic>)
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
        actions: [
          IconButton(
            onPressed: loadMapData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: driverLatLng ?? const LatLng(5.6037, -0.1870),
                        zoom: 10,
                      ),
                      markers: markers,
                      polylines: polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) {
                        mapController = controller;
                        _fitBounds();
                      },
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next: ${nextClient["fullName"]?.toString() ?? "Stop"}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _clientAddress(nextClient).isEmpty
                                    ? 'No address available'
                                    : _clientAddress(nextClient),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'Stops',
                                      value: '${widget.pickups.length}',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'Distance',
                                      value: distanceText.isEmpty
                                          ? '--'
                                          : distanceText,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'ETA',
                                      value: durationText.isEmpty
                                          ? '--'
                                          : durationText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: openExternalMaps,
                                  icon: const Icon(Icons.navigation),
                                  label: const Text('Open in Google Maps'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}