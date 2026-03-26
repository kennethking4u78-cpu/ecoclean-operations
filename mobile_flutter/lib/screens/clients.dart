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
  final q = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load({String? query}) async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('ecoclean_token');
    setState(() => loading = true);
    final list = await Api.listClients(token!, q: query);
    setState(() { clients = list; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: TextField(controller: q, decoration: const InputDecoration(labelText: 'Search name/phone/code'))),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => _load(query: q.text.trim()), child: const Text('Search'))
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (_, i) {
                      final c = clients[i];
                      return ListTile(
                        title: Text('${c['clientCode']} • ${c['fullName']}'),
                        subtitle: Text('${c['phone']} • ${c['zone']} • ${c['paymentStatus']}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: c['id']))),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
