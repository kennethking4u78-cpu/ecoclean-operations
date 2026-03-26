import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_home.dart';
import 'screens/agent_home.dart';
import 'screens/client_home.dart';
import 'screens/driver_home_screen.dart';
import 'screens/create_pickup_screen.dart';
import 'screens/create_client_screen.dart';
import 'screens/view_clients_screen.dart';
import 'screens/manage_users_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EcoCleanApp());
}

class EcoCleanApp extends StatelessWidget {
  const EcoCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoClean Ghana',
      theme: ecoTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        // Core
        '/bootstrap': (context) => const Bootstrap(),
        '/login': (context) => const LoginScreen(),

        // Admin
        '/admin': (context) => const AdminHome(),
        '/admin/home': (context) => const AdminHome(),
        '/admin/create-client': (context) => const CreateClientScreen(),
        '/admin/create-pickup': (context) => const CreatePickupScreen(),
        '/admin/clients': (context) => const ViewClientsScreen(),
        '/admin/users': (context) => const ManageUsersScreen(),
        '/admin/map': (context) =>
            const _PlaceholderScreen(title: 'Live Driver Map'),
        '/admin/routes': (context) =>
            const _PlaceholderScreen(title: 'View Routes'),
        '/admin/payments': (context) =>
            const _PlaceholderScreen(title: 'Payments'),

        // Agent
        '/agent/home': (context) => const AgentHome(),
        '/agent/clients': (context) =>
            const _PlaceholderScreen(title: 'Agent Clients'),
        '/agent/pickups': (context) =>
            const _PlaceholderScreen(title: 'Assign Pickups'),
        '/agent/routes': (context) =>
            const _PlaceholderScreen(title: 'Agent Routes'),

        // Client
        '/client/home': (context) => const ClientHome(),
        '/client/profile': (context) =>
            const _PlaceholderScreen(title: 'My Profile'),
        '/client/schedule': (context) =>
            const _PlaceholderScreen(title: 'Pickup Schedule'),
        '/client/payments': (context) =>
            const _PlaceholderScreen(title: 'Client Payments'),
      },
      onUnknownRoute: (_) {
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      },
    );
  }
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  String? token;
  String? role;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedToken = prefs.getString('ecoclean_token');
      final savedRole = prefs.getString('ecoclean_role');

      if (!mounted) return;

      setState(() {
        token = savedToken;
        role = savedRole;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        token = null;
        role = null;
        loading = false;
      });
    }
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

    if (token == null || token!.trim().isEmpty) {
      return const LoginScreen();
    }

    switch ((role ?? '').trim().toUpperCase()) {
      case 'ADMIN':
      case 'SUPERVISOR':
        return const AdminHome();

      case 'DRIVER':
        return DriverHomeScreen(token: token!);

      case 'AGENT':
        return const AgentHome();

      case 'CLIENT':
        return const ClientHome();

      default:
        return const LoginScreen();
    }
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title screen',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}