import 'package:flutter/material.dart';
import '../../core/api.dart';
import 'otp_verification_screen.dart';
import 'package:dio/dio.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  void _handleSendOtp() async {
    if (_emailController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.forgotPassword(_emailController.text.trim());
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(email: _emailController.text),
          ),
        );
      }
    } on DioException catch (e) {
      String msg = "An error occurred.";
      if (e.response?.statusCode == 404) {
        msg = "Email address not found. Please register first.";
      } else if (e.response?.statusCode == 500) {
        // Checking if we have a specific error message from server
        final serverMsg = e.response?.data['error'];
        msg = serverMsg ?? "Server error. Could not send OTP.";
      } else {
        msg = e.response?.data['error'] ?? e.message ?? "Unknown error";
      }

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: colorScheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Theme.of(context).colorScheme.error),
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
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Enter your email address to receive a 6-digit verification code.",
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email Address",
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Send Code"),
            ),
          ],
        ),
      ),
    );
  }
}

