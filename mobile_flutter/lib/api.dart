import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  // Live DigitalOcean backend
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://178.62.6.18:4000',
  );

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw Exception(data['error']?.toString() ?? 'Login failed');
    }

    return data;
  }

  static Future<List<dynamic>> listClients(
    String token, {
    String? q,
  }) async {
    final uri = Uri.parse('$baseUrl/api/clients').replace(
      queryParameters: (q == null || q.isEmpty) ? null : {'q': q},
    );

    final res = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw Exception(data['error']?.toString() ?? 'Failed to load clients');
    }

    return (data['clients'] as List<dynamic>? ?? []);
  }

  static Future<Map<String, dynamic>> getClientsRaw(String token) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/api/clients'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw Exception(data['error']?.toString() ?? 'Failed to load clients');
    }

    return data;
  }
}