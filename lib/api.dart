import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static const String baseUrl = 'http://192.168.1.67:4000';
  static const Duration _timeout = Duration(seconds: 20);

  static Map<String, String> _jsonHeaders([String? token]) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decode(http.Response response) {
    if (response.body.trim().isEmpty) return {};

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return {
        'ok': false,
        'error': 'Invalid server response',
      };
    }
  }

  static Exception _errorFromResponse(
    http.Response response,
    dynamic data,
    String fallback,
  ) {
    if (data is Map<String, dynamic>) {
      final message =
          data['error']?.toString() ??
          data['message']?.toString() ??
          fallback;
      return Exception(message);
    }

    return Exception(fallback);
  }

  static Future<void> saveAuthSession({
    required String token,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ecoclean_token', token);

    if (role != null && role.trim().isNotEmpty) {
      await prefs.setString('ecoclean_role', role.trim());
    }
  }

  static Future<String> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ecoclean_token') ?? '';
  }

  static Future<String> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ecoclean_role') ?? '';
  }

  static Future<void> clearSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ecoclean_token');
    await prefs.remove('ecoclean_role');
  }

  static Future<dynamic> _get(
    String path, {
    String? token,
    String fallbackError = 'Request failed',
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: _jsonHeaders(token),
          )
          .timeout(_timeout);

      final data = _decode(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      throw _errorFromResponse(response, data, fallbackError);
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(fallbackError);
    }
  }

  static Future<dynamic> _post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
    String fallbackError = 'Request failed',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _jsonHeaders(token),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_timeout);

      final data = _decode(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      throw _errorFromResponse(response, data, fallbackError);
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(fallbackError);
    }
  }

  static Future<dynamic> _patch(
    String path, {
    String? token,
    Map<String, dynamic>? body,
    String fallbackError = 'Request failed',
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: _jsonHeaders(token),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_timeout);

      final data = _decode(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      throw _errorFromResponse(response, data, fallbackError);
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(fallbackError);
    }
  }

  static Future<dynamic> _delete(
    String path, {
    String? token,
    String fallbackError = 'Request failed',
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: _jsonHeaders(token),
          )
          .timeout(_timeout);

      final data = _decode(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      throw _errorFromResponse(response, data, fallbackError);
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(fallbackError);
    }
  }

  /* =========================
     AUTH
  ========================= */

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final data = await _post(
      '/api/auth/login',
      body: {
        'username': username,
        'password': password,
      },
      fallbackError: 'Login failed',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Login failed');
  }

  /* =========================
     USERS
  ========================= */

  static Future<List<dynamic>> listUsers(
    String token, {
    String? role,
    String? q,
  }) async {
    String path = '/api/users';
    final List<String> params = [];

    if (role != null && role.trim().isNotEmpty) {
      params.add('role=${Uri.encodeComponent(role)}');
    }

    if (q != null && q.trim().isNotEmpty) {
      params.add('q=${Uri.encodeComponent(q)}');
    }

    if (params.isNotEmpty) {
      path = '$path?${params.join('&')}';
    }

    final data = await _get(
      path,
      token: token,
      fallbackError: 'Failed to load users',
    );

    if (data is Map<String, dynamic>) {
      return (data['users'] as List?) ?? [];
    }

    return [];
  }

  static Future<List<dynamic>> listDrivers(String token) async {
    return listUsers(token, role: 'DRIVER');
  }

  static Future<Map<String, dynamic>> createUser(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final data = await _post(
      '/api/users',
      token: token,
      body: payload,
      fallbackError: 'Failed to create user',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to create user');
  }

  static Future<Map<String, dynamic>> getUserById(
    String token,
    String id,
  ) async {
    final data = await _get(
      '/api/users/$id',
      token: token,
      fallbackError: 'Failed to load user',
    );

    if (data is Map<String, dynamic>) {
      return (data['user'] as Map<String, dynamic>?) ?? {};
    }

    return {};
  }

  static Future<Map<String, dynamic>> updateUser(
    String token,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data = await _patch(
      '/api/users/$id',
      token: token,
      body: payload,
      fallbackError: 'Failed to update user',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to update user');
  }

  static Future<Map<String, dynamic>> deleteUser(
    String token,
    String id,
  ) async {
    final data = await _delete(
      '/api/users/$id',
      token: token,
      fallbackError: 'Failed to delete user',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {
      'ok': true,
      'message': 'User deleted successfully',
    };
  }

  /* =========================
     CLIENTS
  ========================= */

  static Future<List<dynamic>> listClients(
    String token, {
    String? q,
  }) async {
    final query = Uri.encodeComponent(q ?? '');
    final data = await _get(
      '/api/clients?q=$query',
      token: token,
      fallbackError: 'Failed to load clients',
    );

    if (data is Map<String, dynamic>) {
      return (data['clients'] as List?) ?? [];
    }

    return [];
  }

  static Future<Map<String, dynamic>> getClientById(
    String token,
    String id,
  ) async {
    final data = await _get(
      '/api/clients/$id',
      token: token,
      fallbackError: 'Failed to load client',
    );

    if (data is Map<String, dynamic>) {
      return (data['client'] as Map<String, dynamic>?) ?? {};
    }

    return {};
  }

  static Future<Map<String, dynamic>> registerClient(
    String token,
    Map<String, dynamic> payload, {
    String? imagePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/clients'),
      );

      if (token.trim().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      payload.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      if (imagePath != null && imagePath.trim().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'buildingPhoto',
            imagePath,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = _decode(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        return {
          'ok': true,
          'message': 'Client registered successfully',
        };
      }

      throw _errorFromResponse(
        response,
        data,
        'Failed to register client',
      );
    } on TimeoutException {
      throw Exception('Request timed out');
    } on http.ClientException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to register client');
    }
  }

  static Future<Map<String, dynamic>> updateClient(
    String token,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data = await _patch(
      '/api/clients/$id',
      token: token,
      body: payload,
      fallbackError: 'Failed to update client',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to update client');
  }

  static Future<Map<String, dynamic>> deleteClient(
    String token,
    String id,
  ) async {
    final data = await _delete(
      '/api/clients/$id',
      token: token,
      fallbackError: 'Failed to delete client',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {
      'ok': true,
      'message': 'Client deleted successfully',
    };
  }

  /* =========================
     PICKUPS
  ========================= */

  static Future<List<dynamic>> listPickups(
    String token, {
    String? status,
  }) async {
    String path = '/api/pickups';

    if (status != null && status.trim().isNotEmpty) {
      path = '/api/pickups?status=${Uri.encodeComponent(status)}';
    }

    final data = await _get(
      path,
      token: token,
      fallbackError: 'Failed to load pickups',
    );

    if (data is Map<String, dynamic>) {
      return (data['pickups'] as List?) ?? [];
    }

    return [];
  }

  static Future<Map<String, dynamic>> createPickup(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final data = await _post(
      '/api/pickups',
      token: token,
      body: payload,
      fallbackError: 'Failed to create pickup',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to create pickup');
  }

  static Future<Map<String, dynamic>> updatePickup(
    String token,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data = await _patch(
      '/api/pickups/$id',
      token: token,
      body: payload,
      fallbackError: 'Failed to update pickup',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to update pickup');
  }

  static Future<Map<String, dynamic>> collectPickup(
    String token,
    String id, {
    String? notes,
  }) async {
    final data = await _patch(
      '/api/driver/pickup/$id/collect',
      token: token,
      body: {
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes,
      },
      fallbackError: 'Failed to mark pickup as collected',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to mark pickup as collected');
  }

  static Future<Map<String, dynamic>> missPickup(
    String token,
    String id, {
    String? notes,
  }) async {
    final data = await _patch(
      '/api/driver/pickup/$id/miss',
      token: token,
      body: {
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes,
      },
      fallbackError: 'Failed to mark pickup as missed',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to mark pickup as missed');
  }

  static Future<Map<String, dynamic>> generateTodayPickups(
    String token, {
    String? assignedToId,
    String? truckId,
    bool paidOnly = false,
  }) async {
    final Map<String, dynamic> payload = {
      'paidOnly': paidOnly,
    };

    if (assignedToId != null && assignedToId.trim().isNotEmpty) {
      payload['assignedToId'] = assignedToId;
    }

    if (truckId != null && truckId.trim().isNotEmpty) {
      payload['truckId'] = truckId;
    }

    final data = await _post(
      '/api/pickups/generate-today',
      token: token,
      body: payload,
      fallbackError: 'Failed to generate today pickups',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to generate today pickups');
  }

  /* =========================
     DRIVER
  ========================= */

  static Future<Map<String, dynamic>> driverToday(String token) async {
    final data = await _get(
      '/api/driver/today',
      token: token,
      fallbackError: 'Failed to load driver pickups',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to load driver pickups');
  }

  /* =========================
     DASHBOARD
  ========================= */

  static Future<Map<String, dynamic>> dashboardSummary(String token) async {
    final data = await _get(
      '/api/dashboard/summary',
      token: token,
      fallbackError: 'Failed to load dashboard summary',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to load dashboard summary');
  }

  static Future<Map<String, dynamic>> dashboardOptions(String token) async {
    final data = await _get(
      '/api/dashboard/options',
      token: token,
      fallbackError: 'Failed to load dashboard options',
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Failed to load dashboard options');
  }
}