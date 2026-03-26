import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController(text: 'admin');
  final _password = TextEditingController(text: 'Admin@1234');
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await Api.login(_username.text.trim(), _password.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ecoclean_token', data['token']);
      await prefs.setString('ecoclean_user', (data['user']['name'] ?? '').toString());
      await prefs.setString('ecoclean_role', (data['user']['role'] ?? '').toString());
      widget.onLoggedIn();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Image.asset('assets/ecoclean_logo.png', height: 90),
                const SizedBox(height: 18),
                const Text('EcoClean Ghana Operations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 22),
                TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
                const SizedBox(height: 12),
                TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                const SizedBox(height: 16),
                if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : submit,
                    child: Text(loading ? 'Logging in...' : 'Login'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
