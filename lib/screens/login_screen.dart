import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _username =
      TextEditingController(text: 'driver1');
  final TextEditingController _password =
      TextEditingController(text: '123456');

  bool loading = false;
  bool obscurePassword = true;
  String? error;

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[LoginScreen] $message');
    }
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      error = null;
    });

    try {
      _debugLog('Attempting login for: ${_username.text.trim()}');

      final Map<String, dynamic> data =
          await Api.login(_username.text.trim(), _password.text.trim());

      _debugLog('Raw login response keys: ${data.keys.toList()}');

      final String token = (data['token'] ?? '').toString().trim();

      final Map<String, dynamic> user =
          (data['user'] is Map<String, dynamic>)
              ? data['user'] as Map<String, dynamic>
              : <String, dynamic>{};

      final String role = (user['role'] ?? '').toString().trim();
      final String userName =
          (user['name'] ?? user['username'] ?? '').toString().trim();

      _debugLog('Token length: ${token.length}');
      _debugLog('Role: $role');
      _debugLog('User name: $userName');

      if (token.isEmpty) {
        throw Exception('Token missing from login response');
      }

      if (role.isEmpty) {
        throw Exception('Role missing from login response');
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('ecoclean_token');
      await prefs.remove('ecoclean_user');
      await prefs.remove('ecoclean_role');

      await prefs.setString('ecoclean_token', token);
      await prefs.setString('ecoclean_user', userName);
      await prefs.setString('ecoclean_role', role);

      final savedToken = prefs.getString('ecoclean_token') ?? '';
      final savedRole = prefs.getString('ecoclean_role') ?? '';

      _debugLog('Saved token length: ${savedToken.length}');
      _debugLog('Saved role: $savedRole');

      if (savedToken.trim().isEmpty) {
        throw Exception('Failed to save login token locally');
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/bootstrap');
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');
      _debugLog('Login error: $message');

      setState(() {
        error = message.contains('timed out')
            ? 'Login request timed out. Check your backend server and network.'
            : message;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/ecoclean_logo.png',
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.recycling,
                            size: 110,
                            color: Colors.green,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'EcoClean Ghana Operations',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _username,
                        textInputAction: TextInputAction.next,
                        enabled: !loading,
                        decoration: _inputDecoration(
                          label: 'Username',
                          prefixIcon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _password,
                        enabled: !loading,
                        obscureText: obscurePassword,
                        onSubmitted: (_) {
                          if (!loading) {
                            submit();
                          }
                        },
                        decoration: _inputDecoration(
                          label: 'Password',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            onPressed: loading
                                ? null
                                : () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: loading ? null : submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF14854F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}