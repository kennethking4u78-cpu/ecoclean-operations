import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import 'client_details_screen.dart';
import 'create_client_screen.dart';

class ViewClientsScreen extends StatefulWidget {
  const ViewClientsScreen({super.key});

  @override
  State<ViewClientsScreen> createState() => _ViewClientsScreenState();
}

class _ViewClientsScreenState extends State<ViewClientsScreen> {
  bool loading = true;
  String? error;

  final TextEditingController searchController = TextEditingController();
  List<dynamic> clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[ViewClientsScreen] $message');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _loadClients({String? q}) async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      _debugLog('Loading clients...');
      final token = await Api.getSavedToken();
      _debugLog('Token length: ${token.length}');

      if (token.trim().isEmpty) {
        throw Exception('Missing login token. Please log in again.');
      }

      final loadedClients = await Api.listClients(token, q: q);
      _debugLog('Clients loaded: ${loadedClients.length}');

      if (!mounted) return;

      setState(() {
        clients = loadedClients;
      });
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');
      _debugLog('Load error: $message');

      setState(() {
        error = message.contains('timed out')
            ? 'Request timed out. Check that your backend is running and your phone is on the same network.'
            : message;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    await _loadClients(q: searchController.text.trim());
  }

  Future<void> _clearSearch() async {
    searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
    await _loadClients();
  }

  Future<void> _openCreateClient() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateClientScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      _showSuccess('Client created successfully');
      await _loadClients(q: searchController.text.trim());
    }
  }

  Future<void> _openMap(String? link) async {
    if (link == null || link.trim().isEmpty) return;

    final uri = Uri.parse(link);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError('Could not open map link');
    }
  }

  Future<void> _openClientDetails(dynamic client) async {
    final clientId = client['id']?.toString();

    if (clientId == null || clientId.trim().isEmpty) {
      _showError('Client ID is missing');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailsScreen(clientId: clientId),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadClients(q: searchController.text.trim());
    }
  }

  Color _paymentColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'PART_PAID':
        return Colors.orange;
      case 'DEPOSIT_PAID':
        return Colors.blue;
      case 'OVERDUE':
        return Colors.red;
      case 'UNPAID':
      default:
        return Colors.red;
    }
  }

  String _imageUrl(String raw) {
    final value = raw.trim();

    if (value.isEmpty) return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '${Api.baseUrl}$value';
    }

    return '${Api.baseUrl}/$value';
  }

  Widget _clientAvatar(dynamic client) {
    final rawImage = (client['buildingPhotoUrl'] ?? '').toString().trim();

    if (rawImage.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _imageUrl(rawImage),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.green,
              ),
            );
          },
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.green,
      ),
    );
  }

  Widget _clientCard(dynamic client) {
    final fullName = (client['fullName'] ?? 'Unknown Client').toString();
    final phone = (client['phone'] ?? '').toString();
    final zone = (client['zone'] ?? '').toString();
    final townArea = (client['townArea'] ?? '').toString();
    final landmark = (client['landmark'] ?? '').toString();
    final pickupDay = (client['pickupDay'] ?? '').toString();
    final paymentStatus =
        (client['paymentStatus'] ?? 'UNPAID').toString().toUpperCase();
    final mapLink = client['googleMapsLink']?.toString();
    final imageUrl = client['buildingPhotoUrl']?.toString().trim() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.green.withOpacity(0.08),
        onTap: () => _openClientDetails(client),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    _imageUrl(imageUrl),
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: 170,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 42,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _clientAvatar(client),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            phone,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _paymentColor(paymentStatus).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      paymentStatus,
                      style: TextStyle(
                        color: _paymentColor(paymentStatus),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (zone.isNotEmpty)
                Text(
                  'Zone: $zone',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              if (townArea.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Town/Area: $townArea'),
              ],
              if (landmark.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Landmark: $landmark'),
              ],
              if (pickupDay.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Pickup Day: $pickupDay'),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (mapLink != null && mapLink.trim().isNotEmpty)
                      ? () => _openMap(mapLink)
                      : null,
                  icon: const Icon(Icons.map),
                  label: Text(
                    (mapLink != null && mapLink.trim().isNotEmpty)
                        ? 'Open Map'
                        : 'No Map',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _loadClients,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (clients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              const Text(
                'No clients found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _loadClients,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadClients(q: searchController.text.trim()),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          return _clientCard(clients[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSearchText = searchController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('View Clients'),
          actions: [
            IconButton(
              onPressed: loading
                  ? null
                  : () => _loadClients(q: searchController.text.trim()),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateClient,
          icon: const Icon(Icons.add),
          label: const Text('Add Client'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, zone...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: hasSearchText
                            ? IconButton(
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : _search,
                      child: const Text('Search'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }
}