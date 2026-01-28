import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/api.dart';
import '../../core/data_repository.dart';
import '../../core/theme/app_colors.dart';
import '../admin/presentation/admin_main_screen.dart';
import '../home/presentation/user_home_screen.dart';
import '../main/presentation/user_main_screen.dart';
import 'user_register.dart';
import 'forgot_password_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _apiService = ApiService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],
  );
  bool _obscurePassword = true;

  void _handleLogin() async {
    try {
      final response = await _apiService.login(_emailController.text.trim(), _passwordController.text);
      final userData = response.data;

      if (mounted) {
        if (userData['role'] == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminMainScreen(
                userName: userData['name'],
                userId: userData,
              ),
            ),
          );
        } else {
          // SAVE SESSION
          final repo = DataRepository();
          await repo.saveUserSession(userData);

          // PERFORM FULL SYNC
          final userId = userData['_id'];
          await _performFullSync(repo, userId);

          // NAVIGATE TO MAINSCREEN
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserMainScreen(
                userName: userData['name'],
                userId: userId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      String errorMsg = "Login Failed";
      if (e is DioException && e.response?.data != null) {
        errorMsg = e.response?.data['error'] ?? errorMsg;
      }
      //print('DEBUG: _handleLogin caught error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  void _handleGoogleAuth({required bool isLogin}) async {
    //print("DEBUG - UserLoginScreen/_handleGoogleAuth : Initiating Real Google Sign-In");
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        //print("DEBUG - UserLoginScreen/_handleGoogleAuth : User cancelled sign-in");
        return;
      }

      final String email = account.email;
      final String name = account.displayName ?? "Google User";
      final String googleId = account.id;

      //print("DEBUG - UserLoginScreen/_handleGoogleAuth : Account Retrieved - Email: $email, Name: $name, GoogleID: $googleId");

      final response = isLogin
          ? await _apiService.googleLogin(email, name, googleId)
          : await _apiService.googleSignup(email, name, googleId);

      final userData = response.data;
      if (mounted) {
        _processUserData(userData);
      }
    } catch (e) {
      //print("DEBUG - UserLoginScreen/_handleGoogleAuth : Error - $e");
      if (mounted) {
        String msg = isLogin ? "Login failed. Please check your account." : "Signup failed (Account may already exist).";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _processUserData(dynamic userData) async {
    final repo = DataRepository();
    await repo.saveUserSession(userData);

    final userId = userData['_id'];
    await _performFullSync(repo, userId);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserMainScreen(
            userName: userData['name'],
            userId: userId,
          ),
        ),
      );
    }
  }

  Future<void> _performFullSync(DataRepository repo, String userId) async {
    // 1. Progress
    await repo.syncLocalToRemote(userId);
    await repo.fetchRemoteToLocal(userId);

    // 2. Bookmarks
    await repo.syncBookmarksToRemote(userId);
    await repo.fetchBookmarksToLocal(userId);

    // 3. Level States (Selected Answers)
    await repo.syncLevelStateToRemote(userId);
    await repo.fetchLevelStatesToLocal(userId);
  }

  void _handleForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.onBackground.withOpacity(0.02),
              colorScheme.primary.withOpacity(0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: OrientationBuilder(
                builder: (context, orientation) {
                  bool isLandscape = orientation == Orientation.landscape;

                  Widget logoSection = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logos/gk_rank_icon_t_512x512.png',
                        height: isLandscape ? 100 : 150,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "GkRank",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.brandTeal,
                          fontSize: isLandscape ? 42 : 54,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Master your skills with ease",
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground),
                      ),
                    ],
                  );

                  Widget formSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isLandscape) const SizedBox(height: 48),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        obscureText: _obscurePassword,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: Text("Forgot Password?", style: TextStyle(color: colorScheme.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _handleLogin,
                        child: const Text("Sign In"),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _handleGoogleAuth(isLogin: true),
                        icon: Image.asset('assets/logos/google_logo_960.png', height: 24, width: 24),
                        label: const Text("Continue with Google"),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.outlineVariant),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserMainScreen(userName: "Guest", userId: null),
                            ),
                                (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.primary),
                          foregroundColor: colorScheme.primary,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Continue as Guest"),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?", style: textTheme.bodyMedium),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UserRegisterScreen()),
                            ),
                            child: Text(
                              "Register",
                              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  if (isLandscape) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: logoSection),
                        const SizedBox(width: 48),
                        Expanded(flex: 7, child: formSection),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      logoSection,
                      formSection,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
