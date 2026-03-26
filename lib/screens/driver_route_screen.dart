import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import 'login_screen.dart';
import 'optimized_driver_map.dart';

class DriverRouteScreen extends StatefulWidget {
  final String token;

  const DriverRouteScreen({
    super.key,
    required this.token,
  });

  @override
  State<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends State<DriverRouteScreen> {
  bool loading = true;
  bool updating = false;
  String? error;
  List<dynamic> pickups = [];

  @override
  void initState() {
    super.initState();
    loadRoute();
  }

  Future<void> loadRoute({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        loading = true;
        error = null;
      });
    } else {
      setState(() {
        error = null;
      });
    }

    try {
      final data = await Api.driverToday(widget.token);

      final List<dynamic> rawPickups = (data['pickups'] as List?) ?? [];

      final List<dynamic> pendingPickups = rawPickups.where((pickup) {
        final status = (pickup['status'] ?? '').toString().toUpperCase();
        return status == 'PENDING';
      }).toList();

      if (!mounted) return;

      setState(() {
        pickups = pendingPickups;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      if (showLoader) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('ecoclean_token');
    await prefs.remove('ecoclean_role');
    await prefs.remove('ecoclean_user');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> goBackSafely() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> openMapScreen() async {
    final validPickups = pickups.where((pickup) {
      final client = (pickup['client'] ?? {}) as Map<String, dynamic>;
      return client['lat'] != null && client['lng'] != null;
    }).toList();

    if (validPickups.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pickups with lat/lng available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OptimizedDriverMapScreen(
          pickups: validPickups,
        ),
      ),
    );
  }

  Future<void> updatePickupStatus(String pickupId, String status) async {
    if (updating) return;

    setState(() {
      updating = true;
    });

    try {
      if (widget.token.trim().isEmpty) {
        throw Exception('Token is empty');
      }

      Map<String, dynamic> data;

      if (status.toUpperCase() == 'COLLECTED') {
        data = await Api.collectPickup(widget.token, pickupId);
      } else if (status.toUpperCase() == 'MISSED') {
        data = await Api.missPickup(widget.token, pickupId);
      } else {
        throw Exception('Unsupported pickup status');
      }

      if (!mounted) return;

      setState(() {
        pickups = pickups.where((pickup) {
          return pickup['id'].toString() != pickupId;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']?.toString() ?? 'Pickup updated'),
          backgroundColor: Colors.green,
        ),
      );

      await loadRoute(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        updating = false;
      });
    }
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'COLLECTED':
        return Colors.green;
      case 'MISSED':
      case 'NO_ACCESS':
      case 'NOT_PAID':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamic nextPickup = pickups.isNotEmpty ? pickups.first : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goBackSafely,
        ),
        title: const Text('Driver Route'),
        actions: [
          IconButton(
            onPressed: updating ? null : () => loadRoute(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
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
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : pickups.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.route_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No pending pickups',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You have no remaining assigned stops right now.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: loadRoute,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Today's Route",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${pickups.length} assigned stop${pickups.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your full route is ready.',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: openMapScreen,
                                  icon: const Icon(Icons.map),
                                  label: const Text('Open Full Route Map'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.green,
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
                        const SizedBox(height: 18),
                        if (nextPickup != null) _pickupCard(nextPickup, true),
                        const SizedBox(height: 12),
                        ...pickups.skip(1).map((pickup) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _pickupCard(pickup, false),
                          );
                        }).toList(),
                      ],
                    ),
    );
  }

  Widget _pickupCard(dynamic pickup, bool isNext) {
    final client = (pickup['client'] ?? {}) as Map<String, dynamic>;
    final String status = (pickup['status'] ?? 'UNKNOWN').toString();

    final String fullName = (client['fullName'] ?? 'No name').toString();
    final String townArea = (client['townArea'] ?? '').toString();
    final String landmark = (client['landmark'] ?? '').toString();
    final String zone = (client['zone'] ?? '').toString();

    final String address = [townArea, landmark, zone]
        .where((e) => e.trim().isNotEmpty)
        .join(' / ');

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(
                    isNext ? Icons.flag : Icons.location_on,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isNext)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NEXT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address.isEmpty ? 'No address available' : address,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: updating
                        ? null
                        : () => updatePickupStatus(
                              pickup['id'].toString(),
                              'COLLECTED',
                            ),
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text('Collected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: updating
                        ? null
                        : () => updatePickupStatus(
                              pickup['id'].toString(),
                              'MISSED',
                            ),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Missed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
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