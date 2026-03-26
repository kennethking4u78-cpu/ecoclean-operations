import 'package:flutter/material.dart';
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

      if (token == null || token.isEmpty) {
        setState(() {
          error = 'Missing login token. Please log in again.';
          loading = false;
        });
        return;
      }

      final data = await Api.getClientById(token, widget.clientId);

      if (!mounted) return;

      setState(() {
        client = data;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> openMaps(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps link')),
      );
    }
  }

  Widget infoCard(String title, dynamic value) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text((value ?? '-').toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client Details')),
        body: const Center(child: Text('Client not found')),
      );
    }

    final c = client!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Client ${c['clientCode'] ?? ''}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              (c['fullName'] ?? '').toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(c['phone'] ?? '-').toString()} • ${(c['zone'] ?? '-').toString()}',
            ),
            const SizedBox(height: 12),
            infoCard('Pickup Day', c['pickupDay']),
            infoCard('Payment Status', c['paymentStatus']),
            infoCard('Bin Count', c['binCount'] ?? 1),
            infoCard('Landmark', c['landmark']),
            infoCard('Town Area', c['townArea']),
            infoCard('Property Type', c['propertyType']),
            if (c['googleMapsLink'] != null &&
                c['googleMapsLink'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => openMaps(c['googleMapsLink'].toString()),
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