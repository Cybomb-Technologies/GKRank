import 'package:flutter/material.dart';
import '../../../core/api.dart';
import '../../auth/forgot_password_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userId;
  const ChangePasswordScreen({super.key, required this.userId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _handleChangePassword() async {
    if (_newPasswordController.text.isEmpty) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.changePassword(
        widget.userId, 
        _currentPasswordController.text, 
        _newPasswordController.text
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update password. Check your current password.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            TextField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: "Current Password",
                prefixIcon: const Icon(Icons.password),
                helperText: "Leave blank if you never set a password (Google Sign-In only)",
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              obscureText: _obscureCurrent,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: "New Password", 
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              obscureText: _obscureNew,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: "Confirm New Password", 
                prefixIcon: const Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              obscureText: _obscureConfirm,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleChangePassword,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: _isLoading ? const CircularProgressIndicator() : const Text("Update Password"),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                );
              },
              child: Text(
                "Forgot password? Reset here",
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
