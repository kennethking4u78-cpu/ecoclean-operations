import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import 'edit_client_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailsScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  bool loading = true;
  bool deleting = false;
  String? error;
  Map<String, dynamic>? client;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  Future<void> _loadClient() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await Api.getSavedToken();

      if (token.trim().isEmpty) {
        throw Exception('Missing login token');
      }

      final data = await Api.getClientById(token, widget.clientId);

      if (!mounted) return;

      if (data.isEmpty) {
        throw Exception('Client not found');
      }

      setState(() {
        client = data;
      });
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        error = message.contains('timed out')
            ? 'Request timed out. Check your backend and network connection.'
            : message;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _openEditScreen() async {
    if (loading || client == null) return;

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditClientScreen(client: client!),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadClient();
    }
  }

  Future<void> _deleteClient() async {
    if (deleting || client == null) return;

    final fullName = _stringValue(client?['fullName']);
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Client'),
              content: Text(
                fullName.isEmpty
                    ? 'Are you sure you want to delete this client?'
                    : 'Are you sure you want to delete $fullName?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) return;

    setState(() {
      deleting = true;
    });

    try {
      final token = await Api.getSavedToken();

      if (token.trim().isEmpty) {
        throw Exception('Missing login token');
      }

      final result = await Api.deleteClient(token, widget.clientId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Client deleted successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        deleting = false;
      });
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
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return '${Api.baseUrl}$raw';
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  Future<void> _openUrl(
    String? link, {
    String errorMessage = 'Could not open link',
  }) async {
    if (link == null || link.trim().isEmpty) return;

    final uri = Uri.parse(link);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
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
                onPressed: _loadClient,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = client ?? <String, dynamic>{};

    final fullName = _stringValue(data['fullName']).isEmpty
        ? 'Unknown Client'
        : _stringValue(data['fullName']);
    final phone = _stringValue(data['phone']);
    final zone = _stringValue(data['zone']);
    final townArea = _stringValue(data['townArea']);
    final landmark = _stringValue(data['landmark']);
    final pickupDay = _stringValue(data['pickupDay']);
    final paymentStatus = _stringValue(data['paymentStatus']).isEmpty
        ? 'UNPAID'
        : _stringValue(data['paymentStatus']).toUpperCase();
    final imageUrl = _stringValue(data['buildingPhotoUrl']);
    final mapLink = _stringValue(data['googleMapsLink']);
    final lat = _stringValue(data['lat']);
    final lng = _stringValue(data['lng']);
    final clientCode = _stringValue(data['clientCode']);
    final propertyType = _stringValue(data['propertyType']);
    final binCount = _stringValue(data['binCount']);
    final wasteVolume = _stringValue(data['wasteVolume']);
    final pickupFrequency = _stringValue(data['pickupFrequency']);
    final notes = _stringValue(data['notes']);
    final monthlyFeeGhs = _stringValue(data['monthlyFeeGhs']);
    final prelaunchStatus = _stringValue(data['prelaunchStatus']);
    final binId = _stringValue(data['binId']);

    final createdBy = data['createdBy'] is Map<String, dynamic>
        ? data['createdBy'] as Map<String, dynamic>
        : null;
    final createdByName = _stringValue(createdBy?['name']);
    final createdByRole = _stringValue(createdBy?['role']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                _imageUrl(imageUrl),
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person,
                size: 56,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (clientCode.isNotEmpty)
                        Chip(
                          label: Text(clientCode),
                        ),
                      Chip(
                        backgroundColor:
                            _paymentColor(paymentStatus).withOpacity(0.12),
                        label: Text(
                          paymentStatus,
                          style: TextStyle(
                            color: _paymentColor(paymentStatus),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (prelaunchStatus.isNotEmpty)
                        Chip(
                          label: Text(prelaunchStatus),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoTile(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: phone,
                  ),
                  _infoTile(
                    icon: Icons.location_city,
                    label: 'Zone',
                    value: zone,
                  ),
                  _infoTile(
                    icon: Icons.place,
                    label: 'Town / Area',
                    value: townArea,
                  ),
                  _infoTile(
                    icon: Icons.pin_drop,
                    label: 'Landmark',
                    value: landmark,
                  ),
                  _infoTile(
                    icon: Icons.calendar_today,
                    label: 'Pickup Day',
                    value: pickupDay,
                  ),
                  _infoTile(
                    icon: Icons.home_work,
                    label: 'Property Type',
                    value: propertyType,
                  ),
                  _infoTile(
                    icon: Icons.delete_outline,
                    label: 'Bin Count',
                    value: binCount,
                  ),
                  _infoTile(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Bin ID',
                    value: binId,
                  ),
                  _infoTile(
                    icon: Icons.scale,
                    label: 'Waste Volume',
                    value: wasteVolume,
                  ),
                  _infoTile(
                    icon: Icons.repeat,
                    label: 'Pickup Frequency',
                    value: pickupFrequency,
                  ),
                  _infoTile(
                    icon: Icons.payments_outlined,
                    label: 'Monthly Fee (GHS)',
                    value: monthlyFeeGhs,
                  ),
                  _infoTile(
                    icon: Icons.my_location,
                    label: 'Latitude',
                    value: lat,
                  ),
                  _infoTile(
                    icon: Icons.explore,
                    label: 'Longitude',
                    value: lng,
                  ),
                  _infoTile(
                    icon: Icons.note_alt_outlined,
                    label: 'Notes',
                    value: notes,
                  ),
                  if (createdByName.isNotEmpty || createdByRole.isNotEmpty)
                    _infoTile(
                      icon: Icons.person_outline,
                      label: 'Created By',
                      value: [
                        if (createdByName.isNotEmpty) createdByName,
                        if (createdByRole.isNotEmpty) '($createdByRole)',
                      ].join(' '),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (mapLink.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _openUrl(
                mapLink,
                errorMessage: 'Could not open map',
              ),
              icon: const Icon(Icons.map),
              label: const Text('Open Google Map'),
            ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openUrl(
                'tel:$phone',
                errorMessage: 'Could not open dialer',
              ),
              icon: const Icon(Icons.call),
              label: const Text('Call Client'),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: deleting || loading ? null : _deleteClient,
              icon: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete),
              label: Text(
                deleting ? 'Deleting...' : 'Delete Client',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
        actions: [
          IconButton(
            onPressed: loading ? null : _loadClient,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: loading || client == null ? null : _openEditScreen,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}