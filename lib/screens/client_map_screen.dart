import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';

class ClientMapScreen extends StatefulWidget {
  const ClientMapScreen({super.key});

  @override
  State<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends State<ClientMapScreen> {

  GoogleMapController? mapController;

  bool loading = true;

  final Set<Marker> markers = {};

  static const CameraPosition initialPosition = CameraPosition(
    target: LatLng(5.6698, -0.0166), // Tema default
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  Future<void> loadClients() async {

    try {

      setState(() {
        loading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ecoclean_token');

      final res = await http.get(
        Uri.parse("${Api.baseUrl}/api/clients"),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      final data = jsonDecode(res.body);

      if (!data["ok"]) {
        setState(() => loading = false);
        return;
      }

      markers.clear();

      for (var client in data["clients"]) {

        final latRaw = client["lat"];
        final lngRaw = client["lng"];

        if (latRaw == null || lngRaw == null) continue;

        final double? lat = double.tryParse(latRaw.toString());
        final double? lng = double.tryParse(lngRaw.toString());

        if (lat == null || lng == null) continue;

        markers.add(
          Marker(
            markerId: MarkerId(client["id"].toString()),
            position: LatLng(lat, lng),

            infoWindow: InfoWindow(
              title: client["fullName"] ?? "Client",
              snippet: client["zone"] ?? "",

              onTap: () {
                openNavigation(lat, lng);
              },
            ),
          ),
        );
      }

      setState(() {
        loading = false;
      });

    } catch (e) {

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

    }

  }

  Future<void> openNavigation(double lat, double lng) async {

    final url =
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";

    final uri = Uri.parse(url);

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw Exception("Could not open navigation");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("EcoClean Client Map"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadClients,
          )
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: initialPosition,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,

              onMapCreated: (controller) {
                mapController = controller;
              },
            ),

    );

  }
}