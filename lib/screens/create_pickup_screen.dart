import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

class CreatePickupScreen extends StatefulWidget {
  const CreatePickupScreen({super.key});

  @override
  State<CreatePickupScreen> createState() => _CreatePickupScreenState();
}

class _CreatePickupScreenState extends State<CreatePickupScreen> {
  bool loading = true;
  bool saving = false;

  String? error;
  String? token;

  List<dynamic> clients = [];
  List<dynamic> drivers = [];

  String? selectedClientId;
  String? selectedDriverId;
  String status = 'PENDING';

  final TextEditingController stopOrderController =
      TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    stopOrderController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('ecoclean_token') ?? '';

      if (savedToken.trim().isEmpty) {
        throw Exception('Missing login token');
      }

      final results = await Future.wait([
        Api.listClients(savedToken),
        Api.listDrivers(savedToken),
      ]);

      final loadedClients = results[0] as List<dynamic>;
      final loadedDrivers = results[1] as List<dynamic>;

      if (!mounted) return;

      setState(() {
        token = savedToken;
        clients = loadedClients;
        drivers = loadedDrivers;

        selectedClientId = loadedClients.isNotEmpty
            ? loadedClients.first['id']?.toString()
            : null;

        selectedDriverId = loadedDrivers.isNotEmpty
            ? loadedDrivers.first['id']?.toString()
            : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _createPickup() async {
    if (saving) return;

    if (token == null || token!.trim().isEmpty) {
      _showError('Missing login token');
      return;
    }

    if (selectedClientId == null || selectedClientId!.trim().isEmpty) {
      _showError('Please select a client');
      return;
    }

    if (selectedDriverId == null || selectedDriverId!.trim().isEmpty) {
      _showError('Please select a driver');
      return;
    }

    final stopOrder = int.tryParse(stopOrderController.text.trim());
    if (stopOrder == null || stopOrder < 1) {
      _showError('Stop order must be 1 or more');
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final result = await Api.createPickup(
        token!,
        {
          'clientId': selectedClientId,
          'assignedToId': selectedDriverId,
          'status': status,
          'stopOrder': stopOrder,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Pickup created successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _clientLabel(dynamic client) {
    final fullName = (client['fullName'] ?? 'Unknown Client').toString();
    final townArea = (client['townArea'] ?? '').toString();
    final landmark = (client['landmark'] ?? '').toString();
    final zone = (client['zone'] ?? '').toString();

    final extra = [townArea, landmark, zone]
        .where((e) => e.trim().isNotEmpty)
        .join(' / ');

    if (extra.isEmpty) return fullName;
    return '$fullName • $extra';
  }

  String _driverLabel(dynamic user) {
    final name =
        (user['name'] ?? user['fullName'] ?? 'Unknown Driver').toString();
    final username = (user['username'] ?? '').toString();

    if (username.trim().isEmpty) return name;
    return '$name (@$username)';
  }

  @override
  Widget build(BuildContext context) {
    final bool noClients = clients.isEmpty;
    final bool noDrivers = drivers.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Pickup'),
        actions: [
          IconButton(
            onPressed: loading || saving ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Pickup',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create and assign pickup',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Select a client, assign a driver, and save the route stop.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (noClients)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No clients found. Create a client first.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedClientId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Client',
                            border: OutlineInputBorder(),
                          ),
                          items: clients.map((client) {
                            final id = client['id']?.toString() ?? '';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                _clientLabel(client),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedClientId = value;
                                  });
                                },
                        ),
                      const SizedBox(height: 16),
                      if (noDrivers)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No drivers found. Create a driver first.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedDriverId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Driver',
                            border: OutlineInputBorder(),
                          ),
                          items: drivers.map((driver) {
                            final id = driver['id']?.toString() ?? '';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                _driverLabel(driver),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedDriverId = value;
                                  });
                                },
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PENDING',
                            child: Text('PENDING'),
                          ),
                          DropdownMenuItem(
                            value: 'COLLECTED',
                            child: Text('COLLECTED'),
                          ),
                          DropdownMenuItem(
                            value: 'MISSED',
                            child: Text('MISSED'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  status = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: stopOrderController,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stop Order',
                          border: OutlineInputBorder(),
                          hintText: '1',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: (saving || noClients || noDrivers)
                              ? null
                              : _createPickup,
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            saving ? 'Creating...' : 'Create Pickup',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}