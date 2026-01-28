import 'package:flutter/foundation.dart';

class NetworkUtils {
  /// Flag to switch between production and development.
  /// Set this to [true] for production, [false] for local development.
  static const bool isProduction = true;

  // Live production URL
  static const String _liveBaseUrl = 'https://gkrank.cybomb.com'; // for Backend both web and App APIs
  // https://gkrank-admin.cybomb.com // URL for Web admin Frontend

  // Local development URLs
  static const String _localWebUrl = 'http://localhost:8080';
  static const String _localMobileUrl = 'http://10.0.2.2:8080';

  /// Returns the base URL based on the current platform and environment.
  static String get baseUrl {
    if (isProduction) {
      return _liveBaseUrl;
    }

    if (kIsWeb) {
      return _localWebUrl;
    } else {
      // For Android Emulator, use 10.0.2.2.
      // For physical devices, you might need your machine's local IP, e.g., 'http://192.168.1.5:8080'
      return _localMobileUrl;
    }
  }

  /// Helpful getter to check current environment
  static String get currentEnvironment => isProduction ? 'Production' : 'Local';

  static void printConfig() {
    //print('DEBUG: --- Network Configuration ---');
    //print('DEBUG: isProduction: $isProduction');
    //print('DEBUG: kIsWeb: $kIsWeb');
    //print('DEBUG: Current Base URL: $baseUrl');
    //print('DEBUG: Environment: $currentEnvironment');
    //print('DEBUG: -----------------------------');
  }
}
