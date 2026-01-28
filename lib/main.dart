import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/utils/network_utils.dart';
import 'core/services/flutter_push_notification_service.dart';
import 'features/admin/presentation/admin_main_screen.dart';
import 'features/main/presentation/user_main_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/data_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NetworkUtils.printConfig();
  await dotenv.load(fileName: ".env");
  await ThemeController.initialize();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Only set background handler/initialize notifications if not web or if supported
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await NotificationService().initialize();
    } else {
      //print("DEBUG: Firebase initialized on Web. Skipping mobile notification setup.");
    }
  } catch (e) {
    //print("WARNING: Firebase Initialization Failed: $e");
    // App continues so UI can render even if notifications fail
  }

  final repo = DataRepository();
  final userData = await repo.getUserSession();
  runApp(MyApp(userData: userData));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const MyApp({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GKRank',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,

          // The Builder allows us to place a widget on top of all screens
          builder: (context, child) {
            return Stack(
              children: [
                child!, // This represents your screens (Login, Home, etc.)
                // Positioned(
                //   top: MediaQuery.of(context).padding.top + 64,
                //   right: 32,
                //   child: const FloatingThemeToggle(),
                // ),
              ],
            );
          },
          home: _getInitialScreen(),
        );
      },
    );
  }

  Widget _getInitialScreen() {
    if (kIsWeb) return const AdminMainScreen(userName: '');
    
    if (userData != null) {
      return UserMainScreen(
        userName: userData!['name'] ?? "User",
        userId: userData!['_id'],
      );
    }
    return const UserMainScreen(userName: "Guest", userId: null);
  }
}

// The specific Toggle Widget with a background so it's visible on any screen
class FloatingThemeToggle extends StatelessWidget {
  const FloatingThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
        child: IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: isDark ? AppColors.brandOrange : Colors.blueGrey,
          ),
          onPressed: () => ThemeController.toggleTheme(),
        ),
      ),
    );
  }
}
