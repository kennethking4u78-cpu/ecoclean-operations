import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  Map<String, dynamic>? client;
  String? token;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('ecoclean_token');
    final res = await http.get(
      Uri.parse('${Api.baseUrl}/api/clients/${widget.clientId}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(res.body);
    setState(() => client = data['client']);
  }

  Future<void> openMaps(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (client == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final c = client!;
    return Scaffold(
      appBar: AppBar(title: Text('Client ${c['clientCode']}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(c['fullName'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('${c['phone']} • ${c['zone']}'),
            const SizedBox(height: 12),
            Card(child: ListTile(title: const Text('Pickup Day'), subtitle: Text((c['pickupDay'] ?? '-').toString()))),
            Card(child: ListTile(title: const Text('Payment Status'), subtitle: Text((c['paymentStatus'] ?? '-').toString()))),
            Card(child: ListTile(title: const Text('Bin Count'), subtitle: Text((c['binCount'] ?? 1).toString()))),
            Card(child: ListTile(title: const Text('Landmark'), subtitle: Text((c['landmark'] ?? '-').toString()))),
            if (c['googleMapsLink'] != null) ...[
              const SizedBox(height: 10),
              FilledButton.icon(onPressed: () => openMaps(c['googleMapsLink']), icon: const Icon(Icons.map), label: const Text('Open in Google Maps'))
            ],
          ],
        ),
      ),
    );
  }
}
