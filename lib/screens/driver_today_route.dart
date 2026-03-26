import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';

class DriverTodayRouteScreen extends StatefulWidget {
  const DriverTodayRouteScreen({super.key});

  @override
  State<DriverTodayRouteScreen> createState() =>
      _DriverTodayRouteScreenState();
}

class _DriverTodayRouteScreenState extends State<DriverTodayRouteScreen> {

  bool loading = true;
  String? error;
  List<dynamic> pickups = [];
  String day = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  /*
  =============================
  LOAD DRIVER ROUTE
  =============================
  */

  Future<void> load() async {

    try {

      setState(() {
        loading = true;
        error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ecoclean_token');

      if (token == null || token.isEmpty) {
        setState(() {
          error = 'Missing login token. Please log in again.';
          loading = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse('${Api.baseUrl}/api/driver/today'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final dynamic data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw Exception(
          data is Map<String, dynamic>
              ? (data['error'] ?? 'Failed to fetch pickups')
              : 'Failed to fetch pickups',
        );
      }

      if (!mounted) return;

      setState(() {

        if (data is Map<String, dynamic>) {

          day = (data['day'] ?? '').toString();

          if (data['pickups'] is List) {
            pickups = data['pickups'];
          } else {
            pickups = [];
          }

        } else if (data is List) {

          pickups = data;

        } else {

          pickups = [];

        }

        /*
        =================================
        SIMPLE DISTANCE OPTIMIZATION
        =================================
        */

        pickups.sort((a, b) {

          final aLat = a['lat'] ?? 0;
          final aLng = a['lng'] ?? 0;

          final bLat = b['lat'] ?? 0;
          final bLng = b['lng'] ?? 0;

          final aScore = (aLat.abs() + aLng.abs());
          final bScore = (bLat.abs() + bLng.abs());

          return aScore.compareTo(bScore);

        });

        loading = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });

    }

  }

  /*
  =============================
  GOOGLE MAPS NAVIGATION
  =============================
  */

  Future<void> openMaps(dynamic pickup) async {

    try {

      final mapsLink = (pickup['mapsLink'] ?? '').toString().trim();
      final latRaw = pickup['lat'];
      final lngRaw = pickup['lng'];

      String url = '';

      if (mapsLink.isNotEmpty) {

        url = mapsLink;

      } else if (latRaw != null && lngRaw != null) {

        final lat = latRaw.toString();
        final lng = lngRaw.toString();

        url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

      }

      if (url.isEmpty) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No location found for this client'),
          ),
        );

        return;

      }

      final uri = Uri.parse(url);

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
          ),
        );

      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

    }

  }

  /*
  =============================
  UPDATE PICKUP STATUS
  =============================
  */

  Future<void> updatePickupStatus(String pickupId, String status) async {

    try {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ecoclean_token');

      if (token == null) return;

      await http.patch(
        Uri.parse('${Api.baseUrl}/api/driver/pickup/$pickupId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pickup marked as $status')),
      );

      await load();

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

    }

  }

  /*
  =============================
  STATUS UI HELPERS
  =============================
  */

  Color statusColor(String status) {

    switch (status.toUpperCase()) {

      case 'COLLECTED':
        return Colors.green;

      case 'MISSED':
        return Colors.orange;

      case 'NO_ACCESS':
        return Colors.purple;

      case 'NOT_PAID':
        return Colors.red;

      default:
        return Colors.grey;

    }

  }

  IconData statusIcon(String status) {

    switch (status.toUpperCase()) {

      case 'COLLECTED':
        return Icons.check_circle;

      case 'MISSED':
        return Icons.warning_amber_rounded;

      case 'NO_ACCESS':
        return Icons.block;

      case 'NOT_PAID':
        return Icons.money_off;

      default:
        return Icons.delete;

    }

  }

  /*
  =============================
  TEXT HELPERS
  =============================
  */

  String pickupTitle(dynamic pickup) {

    final code = (pickup['clientCode'] ?? '').toString();
    final name = (pickup['name'] ?? 'Unknown client').toString();

    if (code.isNotEmpty) {
      return '$code • $name';
    }

    return name;

  }

  String pickupSubtitle(dynamic pickup) {

    final zone = (pickup['zone'] ?? '-').toString();
    final phone = (pickup['phone'] ?? '-').toString();
    final pickupDay = (pickup['pickupDay'] ?? '-').toString();

    return '$zone • $phone\nPickup Day: $pickupDay';

  }

  /*
  =============================
  UI
  =============================
  */

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Driver Route"),
      ),

      body: loading

          ? const Center(child: CircularProgressIndicator())

          : error != null

              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )

              : RefreshIndicator(

                  onRefresh: load,

                  child: ListView(

                    padding: const EdgeInsets.all(12),

                    children: [

                      Card(
                        child: ListTile(
                          title: const Text('Driver Checklist'),
                          subtitle: Text(
                            day.isNotEmpty
                                ? 'Stops for $day: ${pickups.length}'
                                : 'Stops today: ${pickups.length}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: load,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      ...pickups.map((pickup) {

                        final status =
                            (pickup['status'] ?? 'PENDING').toString();

                        return Card(

                          child: Padding(

                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                ListTile(

                                  leading: CircleAvatar(
                                    backgroundColor:
                                        statusColor(status),
                                    child: Icon(
                                      statusIcon(status),
                                      color: Colors.white,
                                    ),
                                  ),

                                  title: Text(pickupTitle(pickup)),

                                  subtitle:
                                      Text(pickupSubtitle(pickup)),

                                  isThreeLine: true,

                                  trailing:
                                      Chip(label: Text(status)),

                                ),

                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12, right: 12, bottom: 12),
                                  child: Wrap(
                                    spacing: 8,
                                    children: [

                                      FilledButton.icon(
                                        onPressed: () =>
                                            openMaps(pickup),
                                        icon: const Icon(
                                            Icons.navigation),
                                        label:
                                            const Text('Navigate'),
                                      ),

                                      OutlinedButton(
                                        onPressed: () =>
                                            updatePickupStatus(
                                                pickup['id']
                                                    .toString(),
                                                'COLLECTED'),
                                        child:
                                            const Text('Collected'),
                                      ),

                                      OutlinedButton(
                                        onPressed: () =>
                                            updatePickupStatus(
                                                pickup['id']
                                                    .toString(),
                                                'MISSED'),
                                        child:
                                            const Text('Missed'),
                                      ),

                                      OutlinedButton(
                                        onPressed: () =>
                                            updatePickupStatus(
                                                pickup['id']
                                                    .toString(),
                                                'NO_ACCESS'),
                                        child:
                                            const Text('No Access'),
                                      ),

                                      OutlinedButton(
                                        onPressed: () =>
                                            updatePickupStatus(
                                                pickup['id']
                                                    .toString(),
                                                'NOT_PAID'),
                                        child:
                                            const Text('Not Paid'),
                                      ),

                                    ],
                                  ),
                                )

                              ],
                            ),
                          ),
                        );

                      }).toList(),

                    ],

                  ),
                ),
    );
  }
}