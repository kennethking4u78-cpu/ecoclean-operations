import 'package:ecoclean_mobile/api.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailsScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late Map<String, dynamic> user;
  bool deleting = false;

  @override
  void initState() {
    super.initState();
    user = Map<String, dynamic>.from(widget.user);
  }

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.red;
      case 'SUPERVISOR':
        return Colors.deepOrange;
      case 'AGENT':
        return Colors.blue;
      case 'DRIVER':
        return Colors.green;
      case 'CLIENT':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _value(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  Future<void> _openUrl(
    BuildContext context,
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

  Future<void> _deleteUser() async {
    if (deleting) return;

    final userId = _value(user['id']);
    final name = _value(user['name']);

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete User'),
              content: Text(
                name.isEmpty
                    ? 'Are you sure you want to delete this user?'
                    : 'Are you sure you want to delete $name?',
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

      final result = await Api.deleteUser(token, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'User deleted successfully',
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

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();

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

  @override
  Widget build(BuildContext context) {
    final id = _value(user['id']);
    final name =
        _value(user['name']).isEmpty ? 'Unknown User' : _value(user['name']);
    final username = _value(user['username']);
    final role = _value(user['role']).isEmpty
        ? 'UNKNOWN'
        : _value(user['role']).toUpperCase();
    final phone = _value(user['phone']);
    final email = _value(user['email']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: _roleColor(role).withOpacity(0.12),
                      child: Icon(
                        Icons.person,
                        size: 36,
                        color: _roleColor(role),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Chip(
                      backgroundColor: _roleColor(role).withOpacity(0.12),
                      label: Text(
                        role,
                        style: TextStyle(
                          color: _roleColor(role),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  children: [
                    _infoTile(
                      icon: Icons.badge_outlined,
                      label: 'ID',
                      value: id,
                    ),
                    _infoTile(
                      icon: Icons.person_outline,
                      label: 'Username',
                      value: username,
                    ),
                    _infoTile(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: phone,
                    ),
                    _infoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                    ),
                    _infoTile(
                      icon: Icons.security,
                      label: 'Role',
                      value: role,
                    ),
                  ],
                ),
              ),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openUrl(
                    context,
                    'tel:$phone',
                    errorMessage: 'Could not open dialer',
                  ),
                  icon: const Icon(Icons.call),
                  label: const Text('Call User'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: deleting ? null : _deleteUser,
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
                  deleting ? 'Deleting...' : 'Delete User',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}