import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

class AdminPickupsScreen extends StatefulWidget {
  const AdminPickupsScreen({super.key});

  @override
  State<AdminPickupsScreen> createState() => _AdminPickupsScreenState();
}

class _AdminPickupsScreenState extends State<AdminPickupsScreen> {
  List<dynamic> clients = [];
  List<dynamic> pickups = [];

  bool loadingClients = true;
  bool loadingPickups = true;
  bool saving = false;
  String? error;

  String? selectedClientId;
  DateTime? scheduledDate;
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ecoclean_token');
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadClients(),
      _loadPickups(),
    ]);
  }

  Future<void> _loadClients() async {
    try {
      setState(() {
        loadingClients = true;
        error = null;
      });

      final token = await _getToken();
      if (token == null) {
        setState(() {
          loadingClients = false;
          error = 'Not logged in';
        });
        return;
      }

      final res = await http.get(
        Uri.parse('${Api.baseUrl}/api/clients'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode >= 400) {
        setState(() {
          loadingClients = false;
          error = data['error']?.toString() ?? 'Failed to load clients';
        });
        return;
      }

      setState(() {
        clients = (data['clients'] as List?) ?? [];
        loadingClients = false;
      });
    } catch (e) {
      setState(() {
        loadingClients = false;
        error = 'Failed to load clients: $e';
      });
    }
  }

  Future<void> _loadPickups() async {
    try {
      setState(() {
        loadingPickups = true;
        error = null;
      });

      final token = await _getToken();
      if (token == null) {
        setState(() {
          loadingPickups = false;
          error = 'Not logged in';
        });
        return;
      }

      final res = await http.get(
        Uri.parse('${Api.baseUrl}/api/pickups'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode >= 400) {
        setState(() {
          loadingPickups = false;
          error = data['error']?.toString() ?? 'Failed to load pickups';
        });
        return;
      }

      setState(() {
        pickups = (data['pickups'] as List?) ?? [];
        loadingPickups = false;
      });
    } catch (e) {
      setState(() {
        loadingPickups = false;
        error = 'Failed to load pickups: $e';
      });
    }
  }

  String _text(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _clientLabel(dynamic c) {
    final code = _text(c['clientCode'], fallback: '');
    final name = _text(c['fullName'], fallback: 'No Name');
    final zone = _text(c['zone'], fallback: '');

    if (code.isNotEmpty && zone.isNotEmpty) {
      return '$code • $name • $zone';
    }
    if (code.isNotEmpty) {
      return '$code • $name';
    }
    return name;
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('EEE, d MMM yyyy • h:mm a').format(dt);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'MISSED':
        return Colors.red;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'ASSIGNED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: scheduledDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduledDate ?? now),
    );

    if (pickedTime == null) return;

    setState(() {
      scheduledDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _createPickup() async {
    if (selectedClientId == null || selectedClientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    if (scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose pickup date and time')),
      );
      return;
    }

    try {
      setState(() {
        saving = true;
        error = null;
      });

      final token = await _getToken();
      if (token == null) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in')),
        );
        return;
      }

      final res = await http.post(
        Uri.parse('${Api.baseUrl}/api/pickups'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'clientId': selectedClientId,
          'scheduledDate': scheduledDate!.toIso8601String(),
          'notes': notes.text.trim(),
        }),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode >= 400) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error']?.toString() ?? 'Failed to create pickup',
            ),
          ),
        );
        return;
      }

      setState(() {
        saving = false;
        selectedClientId = null;
        scheduledDate = null;
        notes.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup created successfully')),
      );

      await _loadPickups();
    } catch (e) {
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    }
  }

  Future<void> _deletePickup(String pickupId) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final res = await http.delete(
        Uri.parse('${Api.baseUrl}/api/pickups/$pickupId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode >= 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error']?.toString() ?? 'Failed to delete pickup',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup deleted')),
      );

      await _loadPickups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _pickupCard(dynamic pickup) {
    final client = (pickup['client'] as Map<String, dynamic>?) ?? {};
    final pickupId = _text(pickup['id'], fallback: '');
    final code = _text(client['clientCode'], fallback: 'No Code');
    final name = _text(client['fullName'], fallback: 'No Name');
    final zone = _text(client['zone']);
    final phone = _text(client['phone']);
    final landmark = _text(client['landmark']);
    final status = _text(pickup['status'], fallback: 'PENDING');
    final scheduled = pickup['scheduledDate']?.toString();

    String scheduledText = 'Not scheduled';
    if (scheduled != null && scheduled.isNotEmpty) {
      final dt = DateTime.tryParse(scheduled);
      if (dt != null) {
        scheduledText = _formatDateTime(dt.toLocal());
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$code • $name',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text('Phone: $phone'),
            Text('Zone: $zone'),
            Text('Landmark: $landmark'),
            Text('Scheduled: $scheduledText'),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: pickupId.isEmpty ? null : () => _deletePickup(pickupId),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = loadingClients || loadingPickups;
    final total = pickups.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Pickups'),
        actions: [
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedClientId,
                                items: clients.map<DropdownMenuItem<String>>((c) {
                                  final id = c['id']?.toString() ?? '';
                                  return DropdownMenuItem<String>(
                                    value: id,
                                    child: Text(
                                      _clientLabel(c),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedClientId = v;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Select client',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _pickDateTime,
                                  icon: const Icon(Icons.calendar_month),
                                  label: Text(
                                    scheduledDate == null
                                        ? 'Choose pickup date & time'
                                        : _formatDateTime(scheduledDate!),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: notes,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Notes (optional)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: saving ? null : _createPickup,
                                  child: Text(
                                    saving ? 'Saving...' : 'Create Pickup',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Total pickups: $total',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (pickups.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 30),
                          child: Center(
                            child: Text('No pickups created yet'),
                          ),
                        )
                      else
                        ...pickups.map(_pickupCard),
                    ],
                  ),
                ),
    );
  }
}