import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import 'client_detail.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String? token;
  List<dynamic> clients = [];
  bool loading = true;
  String? error;
  final TextEditingController q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? query}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('ecoclean_token');

      if (token == null || token!.isEmpty) {
        setState(() {
          error = 'Missing login token. Please log in again.';
          loading = false;
        });
        return;
      }

      setState(() {
        loading = true;
        error = null;
      });

      final list = await Api.listClients(
        token!,
        q: query,
      );

      if (!mounted) return;

      setState(() {
        clients = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: q,
                    decoration: const InputDecoration(
                      labelText: 'Search name / phone / code',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _load(query: q.text.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _load(query: q.text.trim()),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : clients.isEmpty
                        ? const Center(child: Text('No clients found'))
                        : RefreshIndicator(
                            onRefresh: () => _load(query: q.text.trim()),
                            child: ListView.builder(
                              itemCount: clients.length,
                              itemBuilder: (context, i) {
                                final c = clients[i];

                                final clientCode =
                                    (c['clientCode'] ?? '').toString();
                                final fullName =
                                    (c['fullName'] ?? '').toString();
                                final phone = (c['phone'] ?? '').toString();
                                final zone = (c['zone'] ?? '').toString();
                                final paymentStatus =
                                    (c['paymentStatus'] ?? 'N/A').toString();
                                final clientId = (c['id'] ?? '').toString();

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: ListTile(
                                    title: Text('$clientCode • $fullName'),
                                    subtitle: Text(
                                      '$phone • $zone • $paymentStatus',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: clientId.isEmpty
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ClientDetailScreen(
                                                  clientId: clientId,
                                                ),
                                              ),
                                            );
                                          },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}