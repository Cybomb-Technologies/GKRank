import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/api.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final _apiService = ApiService();
  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _handleVerify() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.verifyOtp(widget.email, otp);
      if (mounted) {
        if (response.data['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(email: widget.email, otp: otp),
            ),
          );
        } else {
          _showErrorSnack("Check OTP or try again.");
        }
      }
    } catch (e) {
      _showErrorSnack("Invalid OTP. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleResend() async {
    if (_resendTimer > 0) return;
    try {
      await _apiService.forgotPassword(widget.email);
      _startTimer();
      _showErrorSnack("New OTP sent!");
    } catch (e) {
      _showErrorSnack("Failed to resend OTP.");
    }
  }

  void _showErrorSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "We've sent a 6-digit code to",
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              widget.email,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildOtpBox(index)),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerify,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: _isLoading ? const CircularProgressIndicator() : const Text("Verify Account"),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _resendTimer == 0 ? _handleResend : null,
                  child: Text(_resendTimer == 0 ? "Resend OTP" : "Resend in ${_resendTimer}s"),
                ),
                const Text("|"),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Try Again"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: "",
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 5 && value.isNotEmpty) {
            _handleVerify();
          }
        },
      ),
    );
  }
}
