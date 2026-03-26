import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../api.dart';

class AdminLiveMap extends StatefulWidget {
  const AdminLiveMap({super.key});

  @override
  State<AdminLiveMap> createState() => _AdminLiveMapState();
}

class _AdminLiveMapState extends State<AdminLiveMap> {

  GoogleMapController? mapController;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {}; // ✅ ROUTE STORAGE

  static const CameraPosition initialPosition = CameraPosition(
    target: LatLng(5.6037, -0.1870),
    zoom: 12,
  );

  Timer? timer;

  @override
  void initState() {
    super.initState();
    loadDrivers();

    timer = Timer.periodic(const Duration(seconds: 5), (t) {
      loadDrivers();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // 🔥 DRAW ROUTE FUNCTION
  Future<void> drawRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {

    PolylinePoints polylinePoints = PolylinePoints();

    // ===============================
    // 🔴 🔴 🔴 PUT YOUR API KEY HERE 🔴 🔴 🔴
    // ===============================
    PolylineResult result =
        await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyCfDFU5SH7YP73M5iF6nbnIHekd00EMQg4", // 
      PointLatLng(startLat, startLng),
      PointLatLng(endLat, endLng),
    );
    // ===============================

    if (result.points.isNotEmpty) {

      List<LatLng> routePoints = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      setState(() {
        polylines.clear();

        polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            points: routePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
      });
    }
  }

  Future<void> loadDrivers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ecoclean_token');

      final res = await http.get(
        Uri.parse("${Api.baseUrl}/api/users"),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      final data = jsonDecode(res.body);

      if (!data["ok"]) return;

      final Set<Marker> newMarkers = {};

      for (var user in data["users"]) {

        if (user["role"] != "DRIVER") continue;

        final lat = user["currentLat"];
        final lng = user["currentLng"];

        if (lat == null || lng == null) continue;

        newMarkers.add(
          Marker(
            markerId: MarkerId(user["id"]),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: user["username"],
              snippet: "Driver location",
            ),
          ),
        );

        // 🔥 DRAW ROUTE (Driver → Destination)
        await drawRoute(
          lat,
          lng,
          5.6037,   // 🔁 replace later with real client location
          -0.1870,
        );

        break; // only one route for now
      }

      setState(() {
        markers = newMarkers;
      });

    } catch (e) {
      print("Error loading drivers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Live Driver Tracking"),
      ),

      body: GoogleMap(
        initialCameraPosition: initialPosition,
        markers: markers,
        polylines: polylines, // 🔥 SHOW ROUTE LINE
        myLocationEnabled: true,
        zoomControlsEnabled: true,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),

    );
  }
}