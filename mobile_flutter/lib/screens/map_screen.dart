import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;

  static const LatLng _defaultCenter = LatLng(5.6037, -0.1870); // Accra
  static const String _clientsApiUrl = "http://178.62.6.18:4000/api/clients";

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(
        Uri.parse(_clientsApiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to load clients: ${response.statusCode}");
      }

      final body = jsonDecode(response.body);

      List<dynamic> clients;
      if (body is List) {
        clients = body;
      } else if (body is Map<String, dynamic>) {
        if (body["ok"] == false) {
          throw Exception(body["error"] ?? "Failed to load clients");
        }
        clients = body["clients"] as List<dynamic>? ?? [];
      } else {
        throw Exception("Unexpected response format");
      }

      final Set<Marker> loadedMarkers = {};
      LatLng? firstValidLocation;

      for (final client in clients) {
        final latitude = _toDouble(client["latitude"]);
        final longitude = _toDouble(client["longitude"]);

        debugPrint(
          "CLIENT DEBUG: ${client["fullName"]} | $latitude | $longitude",
        );

        if (latitude == null || longitude == null) {
          continue;
        }

        final clientId = (client["id"] ?? "").toString();
        final fullName = (client["fullName"] ?? "Client").toString();
        final phone = (client["phone"] ?? "").toString();
        final zone = (client["zone"] ?? "").toString();
        final townArea = (client["townArea"] ?? "").toString();

        final position = LatLng(latitude, longitude);
        firstValidLocation ??= position;

        final snippetParts = <String>[
          if (phone.isNotEmpty) phone,
          if (townArea.isNotEmpty) townArea,
          if (zone.isNotEmpty) "Zone: $zone",
        ];

        loadedMarkers.add(
          Marker(
            markerId: MarkerId(clientId.isNotEmpty ? clientId : fullName),
            position: position,
            infoWindow: InfoWindow(
              title: fullName,
              snippet: snippetParts.isEmpty ? null : snippetParts.join(" • "),
            ),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _markers
          ..clear()
          ..addAll(loadedMarkers);
        _isLoading = false;
      });

      if (_mapController != null && firstValidLocation != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: firstValidLocation, zoom: 13),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clients Map"),
        actions: [
          IconButton(
            onPressed: _loadClients,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: 11,
            ),
            markers: _markers,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          if (!_isLoading && _markers.isEmpty && _error == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "No clients with latitude/longitude found yet.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}