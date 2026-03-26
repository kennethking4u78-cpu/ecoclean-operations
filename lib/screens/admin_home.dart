import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import 'login_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool generating = false;

  Future<void> _go(BuildContext context, String route) async {
    await Navigator.pushNamed(context, route);

    if (!mounted) return;
    setState(() {});
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('ecoclean_token');
    await prefs.remove('ecoclean_role');
    await prefs.remove('ecoclean_user');

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout) return;

    await _logout(context);
  }

  Future<void> _generateTodayPickups() async {
    if (generating) return;

    setState(() {
      generating = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ecoclean_token') ?? '';

      if (token.trim().isEmpty) {
        throw Exception('Missing login token');
      }

      final result = await Api.generateTodayPickups(token);

      if (!mounted) return;

      _showSuccess(
        result['message']?.toString() ?? 'Today pickups generated',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        generating = false;
      });
    }
  }

  Future<void> _openCreateClient() async {
    final created = await Navigator.pushNamed(context, '/admin/create-client');

    if (!mounted) return;

    if (created == true) {
      _showSuccess('Client created successfully');
      setState(() {});
    }
  }

  Future<void> _openCreatePickup() async {
    final created = await Navigator.pushNamed(context, '/admin/create-pickup');

    if (!mounted) return;

    if (created == true) {
      _showSuccess('Pickup created successfully');
      setState(() {});
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color color = Colors.green,
    Widget? trailing,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label coming soon'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _showSuccess('Dashboard ready');
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Admin',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'EcoClean Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage users, pickups, routes, payments, and operations.',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _sectionTitle('Quick Actions'),
              _actionCard(
                icon: Icons.person_add_alt_1,
                title: 'Create Client',
                subtitle: 'Register a new client directly from the app.',
                onTap: _openCreateClient,
                color: Colors.green,
              ),
              _actionCard(
                icon: Icons.add_box_rounded,
                title: 'Create Pickup',
                subtitle: 'Create and assign a pickup directly from the app.',
                onTap: _openCreatePickup,
                color: Colors.teal,
              ),
              _actionCard(
                icon: Icons.auto_fix_high,
                title: generating
                    ? 'Generating Pickups...'
                    : 'Generate Today Pickups',
                subtitle: generating
                    ? 'Please wait while pickup jobs are being created.'
                    : 'Create today’s pickup jobs for scheduled clients.',
                onTap: generating ? null : _generateTodayPickups,
                color: Colors.orange,
                trailing: generating
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Icon(Icons.chevron_right),
              ),

              const SizedBox(height: 8),
              _sectionTitle('Operations'),
              _actionCard(
                icon: Icons.people_alt_rounded,
                title: 'View Clients',
                subtitle: 'Browse, search, and open saved client records.',
                onTap: () => _go(context, '/admin/clients'),
                color: Colors.indigo,
              ),
              _actionCard(
                icon: Icons.people,
                title: 'Manage Users',
                subtitle:
                    'View and manage admin, agent, client, and driver accounts.',
                onTap: () => _go(context, '/admin/users'),
              ),
              _actionCard(
                icon: Icons.location_on,
                title: 'Live Driver Map',
                subtitle:
                    'Track active drivers and view their current positions.',
                onTap: () => _go(context, '/admin/map'),
                color: Colors.red,
              ),
              _actionCard(
                icon: Icons.route,
                title: 'View Routes',
                subtitle:
                    'Review daily pickup routes and operational planning.',
                onTap: () => _go(context, '/admin/routes'),
                color: Colors.blue,
              ),
              _actionCard(
                icon: Icons.payment,
                title: 'Payments',
                subtitle: 'Check client payment status and payment activity.',
                onTap: () => _go(context, '/admin/payments'),
                color: Colors.purple,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showComingSoon(context, 'Reports'),
                child: const Text('More admin tools coming soon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}