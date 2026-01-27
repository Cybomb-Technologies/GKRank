import 'package:flutter/material.dart';
import '../../../../core/api.dart';
import '../../../../core/widgets/premium_card.dart';
import 'user_results_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await _apiService.getAllUsers();
      setState(() {
        _users = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Failed to load users");
    }
  }

  Future<void> _deleteUser(String id) async {
    try {
      await _apiService.deleteUser(id);
      _showSnackBar("User deleted successfully");
      _fetchUsers(); // Refresh list
    } catch (e) {
      _showSnackBar("Error deleting user");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final String userId = user['_id'];
        final bool isAdmin = user['role'] == 'admin';
        final colorScheme = Theme.of(context).colorScheme;

        return PremiumCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          title: '',
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            onTap: () {
              // Use casting and toString() to be 100% safe
              final dynamic rawId = user['_id'];
              String userIdStr = "";

              if (rawId is Map && rawId.containsKey('\$oid')) {
                userIdStr = rawId['\$oid'].toString();
              } else {
                userIdStr = rawId.toString();
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserResultsScreen(
                    userId: userIdStr,
                    userName: user['name']?.toString() ?? "User",
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: isAdmin ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
              child: Icon(
                isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                color: isAdmin ? colorScheme.primary : colorScheme.secondary,
              ),
            ),
            title: Text(
              user['name'] ?? 'No Name',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email'] ?? ""),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isAdmin ? colorScheme.primary : colorScheme.secondary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user['role']?.toUpperCase() ?? "USER",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAdmin ? colorScheme.primary : colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            trailing: isAdmin
                ? Icon(Icons.verified_rounded, color: colorScheme.primary)
                : IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                    onPressed: () => _confirmDelete(userId),
                  ),
          ),
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme
            .of(context)
            .colorScheme;
        return AlertDialog(
          title: const Text("Delete User?"),
          content: const Text("This action cannot be undone."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteUser(id);
              },
              child: const Text(
                  "Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }
}
