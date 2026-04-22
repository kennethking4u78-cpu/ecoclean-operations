import 'package:flutter/material.dart';

import 'clients_screen.dart';
import 'register_client_screen.dart';
import 'driver_pickups_screen.dart';
import 'admin_pickups_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _card({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
    Color? color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color ?? Colors.green,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoClean Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Operations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          _card(
            context: context,
            title: 'Register Client',
            subtitle: 'Add new customer with GPS',
            icon: Icons.person_add,
            screen: const RegisterClientScreen(),
            color: Colors.green,
          ),

          _card(
            context: context,
            title: 'View Clients',
            subtitle: 'Search and manage clients',
            icon: Icons.people,
            screen: const ClientsScreen(),
            color: Colors.blue,
          ),

          const SizedBox(height: 20),

          const Text(
            'Pickups',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          _card(
            context: context,
            title: 'Driver Pickups',
            subtitle: 'For drivers to execute pickups',
            icon: Icons.local_shipping,
            screen: const DriverPickupsScreen(),
            color: Colors.orange,
          ),

          _card(
            context: context,
            title: 'Admin Pickups',
            subtitle: 'Create & manage pickup schedule',
            icon: Icons.admin_panel_settings,
            screen: const AdminPickupsScreen(),
            color: Colors.purple,
          ),

          const SizedBox(height: 30),

          const Divider(),

          const SizedBox(height: 10),

          const Text(
            'System Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Backend Connected'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Client System Active'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Pickup System Ready'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}