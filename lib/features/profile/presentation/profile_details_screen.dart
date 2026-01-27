import 'package:flutter/material.dart';
import '../../../core/data_repository.dart';
import '../../../core/api.dart';
import '../../auth/user_login.dart';
import 'change_password_screen.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final String userName;
  final String? userId;

  const ProfileDetailsScreen({super.key, required this.userName, this.userId});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final DataRepository _repo = DataRepository();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _repo.getUserSession();
    if (data != null) {
      setState(() => _userData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Your Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoTile(context, Icons.person_outline, "Name", widget.userName),
          if (widget.userId != null)
            _buildInfoTile(context, Icons.info_outline, "User ID", widget.userId!),
          if (_userData?['email'] != null)
            _buildInfoTile(context, Icons.email_outlined, "Email", _userData!['email']),
          if (_userData?['signupSource'] != null)
            _buildInfoTile(
              context, 
              _userData!['signupSource'] == 'google' ? Icons.g_mobiledata : Icons.login,
              "Signup Source", 
              _userData!['signupSource'].toString().toUpperCase()
            ),
          const SizedBox(height: 24),
          Text(
            "Account Security", 
            style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.password, color: Colors.blue),
            title: const Text("Change Password"),
            subtitle: const Text("Update your login credentials"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePasswordScreen(userId: widget.userId ?? ""),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            "Danger Zone", 
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Delete Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text("Permanently remove all your data"),
            onTap: () {
              if (widget.userId != null) {
                _showDeleteAccountDialog(context, widget.userId!);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?", style: TextStyle(color: Colors.red)),
        content: const SingleChildScrollView(
          child: Text(
            "This will permanently delete your account, progress, and all saved data. This action cannot be undone.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final api = ApiService();
                await api.deleteAccount(userId);
                await _repo.wipeUserData(userId);
                await _repo.clearSession();
                
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Account deleted successfully")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete account: $e")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete Forever"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      subtitle: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
    );
  }
}
