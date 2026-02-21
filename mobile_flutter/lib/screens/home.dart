import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'clients.dart';
import 'register_client.dart';
import 'driver_today_route.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.onLogout});

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ecoclean_token');
    onLogout();
  }

  Future<String?> _role() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ecoclean_role');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoClean Ghana'),
        actions: [IconButton(onPressed: () => logout(), icon: const Icon(Icons.logout))],
      ),
      body: FutureBuilder<String?>(
        future: _role(),
        builder: (context, snap) {
          final role = snap.data ?? '';
          return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Image.asset('assets/ecoclean_logo.png', height: 34),
                title: const Text('Operations', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Register clients, track routes, pickups & payments'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterClientScreen())),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Register Client'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen())),
              icon: const Icon(Icons.people),
              label: const Text('View Clients'),
            ),
            if (role == 'DRIVER') ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverTodayRouteScreen())),
                icon: const Icon(Icons.checklist),
                label: const Text("Today's Route Checklist"),
              ),
            ],
          ],
        );
        },
      ),
    );
  }
}
