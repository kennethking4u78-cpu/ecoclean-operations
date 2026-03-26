import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'create_client_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;

  const AdminDashboardScreen({
    super.key,
    required this.token,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool isLoading = true;
  bool isGenerating = false;
  String? error;

  Map<String, dynamic>? summary;
  List<dynamic> recentPickups = [];
  List<dynamic> drivers = [];
  List<dynamic> trucks = [];

  final String baseUrl = "http://localhost:4000";

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse("$baseUrl/api/dashboard/summary"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${widget.token}",
          },
        ),
        http.get(
          Uri.parse("$baseUrl/api/dashboard/options"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${widget.token}",
          },
        ),
      ]);

      final summaryResponse = responses[0];
      final optionsResponse = responses[1];

      final summaryData = jsonDecode(summaryResponse.body);
      final optionsData = jsonDecode(optionsResponse.body);

      if (summaryResponse.statusCode >= 200 &&
          summaryResponse.statusCode < 300 &&
          summaryData["ok"] == true &&
          optionsResponse.statusCode >= 200 &&
          optionsResponse.statusCode < 300 &&
          optionsData["ok"] == true) {
        setState(() {
          summary = summaryData["summary"];
          recentPickups = summaryData["recentPickups"] ?? [];
          drivers = optionsData["drivers"] ?? [];
          trucks = optionsData["trucks"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = summaryData["error"] ??
              optionsData["error"] ??
              "Failed to load dashboard";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> openCreateClientScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateClientScreen(token: widget.token),
      ),
    );

    if (result == true) {
      await loadAll();
    }
  }

  Future<void> generatePickups() async {
    setState(() {
      isGenerating = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/pickups/generate-today"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({}),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Pickups generated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        await loadAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["error"] ?? "Failed to generate pickups"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  Future<void> updatePickup(
    String pickupId, {
    String? status,
    String? assignedToId,
    String? truckId,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (status != null) body["status"] = status;
      if (assignedToId != null) body["assignedToId"] = assignedToId;
      if (truckId != null) body["truckId"] = truckId;

      final response = await http.patch(
        Uri.parse("$baseUrl/api/pickups/$pickupId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Pickup updated"),
            backgroundColor: Colors.green,
          ),
        );
        await loadAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["error"] ?? "Failed to update pickup"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void openAssignDialog(dynamic pickup) {
    String? selectedDriverId = pickup["assignedTo"]?["id"];
    String? selectedTruckId = pickup["truck"]?["id"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Assign Driver / Truck"),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedDriverId,
                    decoration: const InputDecoration(
                      labelText: "Driver",
                      border: OutlineInputBorder(),
                    ),
                    items: drivers.map<DropdownMenuItem<String>>((driver) {
                      return DropdownMenuItem<String>(
                        value: driver["id"],
                        child: Text(
                          driver["name"] ??
                              driver["username"] ??
                              "Unknown Driver",
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedDriverId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedTruckId,
                    decoration: const InputDecoration(
                      labelText: "Truck",
                      border: OutlineInputBorder(),
                    ),
                    items: trucks.map<DropdownMenuItem<String>>((truck) {
                      return DropdownMenuItem<String>(
                        value: truck["id"],
                        child: Text(
                          "${truck["plateNumber"] ?? "No Plate"}"
                          "${truck["model"] != null ? " • ${truck["model"]}" : ""}",
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedTruckId = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await updatePickup(
                  pickup["id"],
                  assignedToId: selectedDriverId,
                  truckId: selectedTruckId,
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "PENDING":
        return Colors.orange;
      case "COLLECTED":
        return Colors.green;
      case "MISSED":
      case "NO_ACCESS":
      case "NOT_PAID":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            onPressed: loadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateClientScreen,
        icon: const Icon(Icons.person_add),
        label: const Text("Add Client"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isGenerating ? null : generatePickups,
                          icon: isGenerating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.playlist_add_check),
                          label: Text(
                            isGenerating
                                ? "Generating Pickups..."
                                : "Generate Today's Pickups",
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: openCreateClientScreen,
                          icon: const Icon(Icons.person_add),
                          label: const Text("Add New Client"),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatCard(
                            title: "Clients",
                            value: "${summary?["totalClients"] ?? 0}",
                            color: Colors.blue,
                          ),
                          _StatCard(
                            title: "Drivers",
                            value: "${summary?["totalDrivers"] ?? 0}",
                            color: Colors.orange,
                          ),
                          _StatCard(
                            title: "Trucks",
                            value: "${summary?["totalTrucks"] ?? 0}",
                            color: Colors.indigo,
                          ),
                          _StatCard(
                            title: "Today's Pickups",
                            value: "${summary?["todayPickups"] ?? 0}",
                            color: Colors.green,
                          ),
                          _StatCard(
                            title: "Pending",
                            value: "${summary?["pendingToday"] ?? 0}",
                            color: Colors.amber,
                          ),
                          _StatCard(
                            title: "Collected",
                            value: "${summary?["completedToday"] ?? 0}",
                            color: Colors.teal,
                          ),
                          _StatCard(
                            title: "Missed",
                            value: "${summary?["missedToday"] ?? 0}",
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Recent Pickups",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (recentPickups.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("No pickups found for today"),
                          ),
                        ),
                      ...recentPickups.map((pickup) {
                        final client = pickup["client"];
                        final driver = pickup["assignedTo"];
                        final truck = pickup["truck"];
                        final status = pickup["status"] ?? "UNKNOWN";

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    client?["fullName"] ?? "Unknown Client",
                                  ),
                                  subtitle: Text(
                                    "${client?["townArea"] ?? ""}\n"
                                    "Driver: ${driver?["username"] ?? "Unassigned"}\n"
                                    "Truck: ${truck?["plateNumber"] ?? "Unassigned"}",
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: _statusColor(status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => openAssignDialog(pickup),
                                        icon: const Icon(Icons.person_add_alt_1),
                                        label: const Text("Assign"),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => updatePickup(
                                          pickup["id"],
                                          status: "COLLECTED",
                                        ),
                                        icon: const Icon(Icons.check_circle),
                                        label: const Text("Collected"),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => updatePickup(
                                          pickup["id"],
                                          status: "MISSED",
                                        ),
                                        icon: const Icon(Icons.cancel),
                                        label: const Text("Missed"),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}