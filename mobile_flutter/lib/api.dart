import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  // Android emulator: 10.0.2.2 points to your PC localhost
  static const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:4000');

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw Exception(data['error']?.toString() ?? 'Login failed');
    return data;
  }

  static Future<List<dynamic>> listClients(String token, {String? q}) async {
    final uri = Uri.parse('$baseUrl/api/clients').replace(queryParameters: (q == null || q.isEmpty) ? null : {'q': q});
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw Exception(data['error']?.toString() ?? 'Failed');
    return (data['clients'] as List<dynamic>);
  }
}
