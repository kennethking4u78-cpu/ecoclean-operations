import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  Map<String, dynamic>? client;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ecoclean_token');

      if (token == null) {
        setState(() {
          loading = false;
          error = 'Not logged in';
        });
        return;
      }

      final res = await http.get(
        Uri.parse('${Api.baseUrl}/api/clients/${widget.clientId}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      if (res.statusCode >= 400) {
        setState(() {
          loading = false;
          error = data['error']?.toString() ?? 'Failed to load client';
        });
        return;
      }

      setState(() {
        client = data['client'] as Map<String, dynamic>?;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Failed to load client: $e';
      });
    }
  }

  String _textValue(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _moneyValue(dynamic value) {
    final numValue = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'GHS ${numValue.toStringAsFixed(2)}';
  }

  String _mapsUrl(Map<String, dynamic> c) {
    final lat = c['latitude'];
    final lng = c['longitude'];

    if (lat != null && lng != null) {
      return 'https://maps.google.com/?q=$lat,$lng';
    }

    return '';
  }

  Future<void> _openMaps(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Widget _infoCard(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Client Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (client == null) {
      return const Scaffold(
        body: Center(
          child: Text('Client not found'),
        ),
      );
    }

    final c = client!;
    final clientCode = _textValue(c['clientCode'], fallback: 'No Code');
    final fullName = _textValue(c['fullName'], fallback: 'No Name');
    final phone = _textValue(c['phone']);
    final zone = _textValue(c['zone']);
    final townArea = _textValue(c['townArea']);
    final landmark = _textValue(c['landmark']);
    final propertyType = _textValue(c['propertyType']);
    final prelaunchStatus = _textValue(c['prelaunchStatus']);
    final paymentStatus = _textValue(c['paymentStatus']);
    final monthlyFeeGhs = _moneyValue(c['monthlyFeeGhs']);
    final latitude = _textValue(c['latitude']);
    final longitude = _textValue(c['longitude']);
    final notes = _textValue(c['notes']);
    final mapsUrl = _mapsUrl(c);

    return Scaffold(
      appBar: AppBar(
        title: Text('Client $clientCode'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$phone • $zone',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            _infoCard('Client Code', clientCode),
            _infoCard('Town / Area', townArea),
            _infoCard('Landmark', landmark),
            _infoCard('Property Type', propertyType),
            _infoCard('Prelaunch Status', prelaunchStatus),
            _infoCard('Payment Status', paymentStatus),
            _infoCard('Monthly Fee (GHS)', monthlyFeeGhs),
            _infoCard('Latitude', latitude),
            _infoCard('Longitude', longitude),
            _infoCard('Notes', notes),
            if (mapsUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openMaps(mapsUrl),
                icon: const Icon(Icons.map),
                label: const Text('Open in Google Maps'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}