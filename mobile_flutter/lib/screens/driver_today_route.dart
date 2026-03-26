import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';

class DriverTodayRouteScreen extends StatefulWidget {
  const DriverTodayRouteScreen({super.key});

  @override
  State<DriverTodayRouteScreen> createState() => _DriverTodayRouteScreenState();
}

class _DriverTodayRouteScreenState extends State<DriverTodayRouteScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? route;
  List<dynamic> checklist = [];
  String day = "";

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ecoclean_token');
      final res = await http.get(
        Uri.parse('${Api.baseUrl}/api/routes/today/assigned'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      setState(() {
        day = data['day']?.toString() ?? '';
        route = data['route'];
        checklist = data['checklist'] ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> openMaps(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> mark(String clientId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('ecoclean_token');
    final res = await http.post(
      Uri.parse('${Api.baseUrl}/api/pickups'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'clientId': clientId, 'status': status}),
    );
    if (res.statusCode >= 400) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.body}')));
      return;
    }
    await load();
  }

  Color statusColor(String s) {
    switch (s) {
      case "COLLECTED": return Colors.green;
      case "MISSED": return Colors.orange;
      case "NO_ACCESS": return Colors.purple;
      case "NOT_PAID": return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Today's Checklist")),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: Colors.red))))
          : (route == null)
            ? Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("No assigned route for $day.\n\nAdmin should create a route in the web dashboard and assign it to you.",
                  textAlign: TextAlign.center),
              ))
            : RefreshIndicator(
                onRefresh: load,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Card(
                      child: ListTile(
                        title: Text('${route!['code']} • ${route!['pickupDay']}'),
                        subtitle: Text('Stops: ${checklist.length}'),
                        trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: load),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...checklist.map((s) {
                      final statusToday = s['statusToday']?.toString() ?? "PENDING";
                      return Card(
                        child: ListTile(
                          title: Text('${s['stopOrder']}. ${s['clientCode']} • ${s['name']}'),
                          subtitle: Text('${s['zone']} • ${s['phone']}'),
                          leading: CircleAvatar(backgroundColor: statusColor(statusToday), child: const Icon(Icons.flag, color: Colors.white)),
                          onTap: () => openMaps(s['mapsLink']),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => mark(s['clientId'], v),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: "COLLECTED", child: Text("Mark Collected")),
                              PopupMenuItem(value: "MISSED", child: Text("Mark Missed")),
                              PopupMenuItem(value: "NO_ACCESS", child: Text("No Access")),
                              PopupMenuItem(value: "NOT_PAID", child: Text("Not Paid")),
                            ],
                            child: Chip(label: Text(statusToday)),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    const Text("Tip: Tap a stop to open Google Maps. Use the status menu to mark each pickup.", textAlign: TextAlign.center),
                  ],
                ),
              ),
    );
  }
}
