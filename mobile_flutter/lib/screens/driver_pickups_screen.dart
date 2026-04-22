import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';

class DriverPickupsScreen extends StatefulWidget {
  const DriverPickupsScreen({super.key});

  @override
  State<DriverPickupsScreen> createState() => _DriverPickupsScreenState();
}

class _DriverPickupsScreenState extends State<DriverPickupsScreen> {
  List<dynamic> pickups = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ecoclean_token');
  }

  Future<void> _load() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final token = await _getToken();
      if (token == null) {
        setState(() {
          loading = false;
          error = 'Not logged in';
        });
        return;
      }

      final res = await http.get(
        Uri.parse('${Api.baseUrl}/api/pickups'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode >= 400) {
        setState(() {
          loading = false;
          error = data['error']?.toString() ?? 'Failed to load pickups';
        });
        return;
      }

      setState(() {
        pickups = (data['pickups'] as List?) ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Failed to load pickups: $e';
      });
    }
  }

  String _text(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _statusText(dynamic value) {
    final raw = _text(value, fallback: 'PENDING');
    return raw.replaceAll('_', ' ');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'MISSED':
        return Colors.red;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'ASSIGNED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _mapsUrl(Map<String, dynamic> client) {
    final lat = client['latitude'];
    final lng = client['longitude'];

    if (lat != null && lng != null) {
      return 'https://maps.google.com/?q=$lat,$lng';
    }

    return '';
  }

  Future<void> _openMaps(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callClient(String phone) async {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) return;

    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _updateStatus(String pickupId, String status) async {
    try {
      final token = await _getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in')),
        );
        return;
      }

      final res = await http.patch(
        Uri.parse('${Api.baseUrl}/api/pickups/$pickupId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode >= 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error']?.toString() ?? 'Failed to update pickup status',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pickup marked ${status.replaceAll('_', ' ')}')),
      );

      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: backgroundColor == null
              ? null
              : FilledButton.styleFrom(
                  backgroundColor: backgroundColor,
                ),
        ),
      ),
    );
  }

  Widget _pickupCard(dynamic pickup) {
    final client = (pickup['client'] as Map<String, dynamic>?) ?? {};
    final pickupId = _text(pickup['id'], fallback: '');
    final clientCode = _text(client['clientCode'], fallback: 'No Code');
    final fullName = _text(client['fullName'], fallback: 'No Name');
    final phone = _text(client['phone']);
    final zone = _text(client['zone']);
    final townArea = _text(client['townArea']);
    final landmark = _text(client['landmark']);
    final propertyType = _text(client['propertyType']);
    final paymentStatus = _text(client['paymentStatus']);
    final statusRaw = _text(pickup['status'], fallback: 'PENDING');
    final statusDisplay = _statusText(statusRaw);
    final mapsUrl = _mapsUrl(client);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$clientCode • $fullName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(statusRaw).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusDisplay,
                    style: TextStyle(
                      color: _statusColor(statusRaw),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Phone: $phone'),
            Text('Zone: $zone'),
            Text('Town / Area: $townArea'),
            Text('Landmark: $landmark'),
            Text('Property Type: $propertyType'),
            Text('Payment Status: $paymentStatus'),
            const SizedBox(height: 14),
            Row(
              children: [
                _actionButton(
                  icon: Icons.call,
                  label: 'Call',
                  onPressed: () => _callClient(phone),
                ),
                _actionButton(
                  icon: Icons.map,
                  label: 'Map',
                  onPressed: mapsUrl.isEmpty ? () {} : () => _openMaps(mapsUrl),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _actionButton(
                  icon: Icons.play_arrow,
                  label: 'Start',
                  backgroundColor: Colors.orange,
                  onPressed: pickupId.isEmpty
                      ? () {}
                      : () => _updateStatus(pickupId, 'IN_PROGRESS'),
                ),
                _actionButton(
                  icon: Icons.check_circle,
                  label: 'Done',
                  backgroundColor: Colors.green,
                  onPressed: pickupId.isEmpty
                      ? () {}
                      : () => _updateStatus(pickupId, 'COMPLETED'),
                ),
                _actionButton(
                  icon: Icons.cancel,
                  label: 'Missed',
                  backgroundColor: Colors.red,
                  onPressed: pickupId.isEmpty
                      ? () {}
                      : () => _updateStatus(pickupId, 'MISSED'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = pickups.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Pickups'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Total pickups: $total',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (pickups.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text('No pickups assigned'),
                          ),
                        )
                      else
                        ...pickups.map(_pickupCard),
                    ],
                  ),
                ),
    );
  }
}