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
  final q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? query}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('ecoclean_token');

      if (token == null) {
        setState(() {
          loading = false;
          error = 'Not logged in';
          clients = [];
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
        loading = false;
        error = e.toString();
      });
    }
  }

  String _titleForClient(dynamic c) {
    final clientCode = (c['clientCode'] ?? '').toString().trim();
    final fullName = (c['fullName'] ?? '').toString().trim();
    final safeName = fullName.isEmpty ? 'No Name' : fullName;

    if (clientCode.isNotEmpty) {
      return '$clientCode • $safeName';
    }

    return safeName;
  }

  String _subtitleForClient(dynamic c) {
    final phone = (c['phone'] ?? '').toString().trim();
    final zone = (c['zone'] ?? '').toString().trim();
    final paymentStatus = (c['paymentStatus'] ?? '').toString().trim();

    final parts = <String>[
      if (phone.isNotEmpty) phone,
      if (zone.isNotEmpty) zone,
      if (paymentStatus.isNotEmpty) paymentStatus,
    ];

    return parts.isEmpty ? 'No details available' : parts.join(' • ');
  }

  Future<void> _openClient(dynamic c) async {
    final clientId = c['id']?.toString();

    if (clientId == null || clientId.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(clientId: clientId),
      ),
    );

    if (!mounted) return;

    await _load(
      query: q.text.trim().isEmpty ? null : q.text.trim(),
    );
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
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(
                      query: q.text.trim().isEmpty ? null : q.text.trim(),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Search name/phone/code',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _load(
                    query: q.text.trim().isEmpty ? null : q.text.trim(),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
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
                    : clients.isEmpty
                        ? const Center(
                            child: Text('No clients found'),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _load(
                              query: q.text.trim().isEmpty
                                  ? null
                                  : q.text.trim(),
                            ),
                            child: ListView.separated(
                              itemCount: clients.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final c = clients[i];
                                final fullName =
                                    (c['fullName'] ?? '').toString().trim();
                                final initial = fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : 'N';

                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(initial),
                                  ),
                                  title: Text(
                                    _titleForClient(c),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(_subtitleForClient(c)),
                                  trailing:
                                      const Icon(Icons.chevron_right),
                                  onTap: () => _openClient(c),
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