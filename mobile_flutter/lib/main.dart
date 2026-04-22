import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/map_screen.dart';

void main() {
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
      home: const Bootstrap(),
      routes: {
        '/map': (_) => const MapScreen(),
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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      token = prefs.getString('ecoclean_token');
      loading = false;
    });
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

    return token == null
        ? LoginScreen(onLoggedIn: _load)
        : HomeScreen(onLogout: _load);
  }
}