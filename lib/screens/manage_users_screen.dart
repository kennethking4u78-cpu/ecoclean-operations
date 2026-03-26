import 'package:flutter/material.dart';

import '../api.dart';
import 'create_user_screen.dart';
import 'user_details_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  bool loading = true;
  String? error;

  final TextEditingController searchController = TextEditingController();

  List<dynamic> users = [];
  String selectedRole = 'ALL';

  final List<String> roles = const [
    'ALL',
    'ADMIN',
    'SUPERVISOR',
    'AGENT',
    'DRIVER',
    'CLIENT',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  Future<void> _loadUsers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await Api.getSavedToken();

      if (token.trim().isEmpty) {
        throw Exception('Missing login token');
      }

      final loadedUsers = await Api.listUsers(
        token,
        role: selectedRole == 'ALL' ? null : selectedRole,
        q: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        users = loadedUsers;
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

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    await _loadUsers();
  }

  Future<void> _clearSearch() async {
    searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
    await _loadUsers();
  }

  Future<void> _openCreateUser() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateUserScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      _showSuccess('User created successfully');
      await _loadUsers();
    }
  }

  Future<void> _openUserDetails(dynamic user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailsScreen(
          user: Map<String, dynamic>.from(user as Map),
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadUsers();
    }
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

  Widget _userCard(dynamic user) {
    final name = (user['name'] ?? 'Unknown User').toString();
    final username = (user['username'] ?? '').toString();
    final role = (user['role'] ?? 'UNKNOWN').toString().toUpperCase();
    final id = (user['id'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openUserDetails(user),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _roleColor(role).withOpacity(0.12),
                child: Icon(
                  Icons.person,
                  color: _roleColor(role),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@$username',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    if (id.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        id,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _roleColor(role).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    color: _roleColor(role),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (users.isEmpty) {
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
                'No users found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        itemCount: users.length,
        itemBuilder: (context, index) {
          return _userCard(users[index]);
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
          title: const Text('Manage Users'),
          actions: [
            IconButton(
              onPressed: loading ? null : _loadUsers,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateUser,
          icon: const Icon(Icons.person_add),
          label: const Text('Add User'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search by name or username...',
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Filter by role',
                      border: OutlineInputBorder(),
                    ),
                    items: roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: loading
                        ? null
                        : (value) async {
                            if (value == null) return;

                            setState(() {
                              selectedRole = value;
                            });

                            await _loadUsers();
                          },
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