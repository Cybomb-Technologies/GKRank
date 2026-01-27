// lib/core/services/data_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';

class DataService {
  final ApiService _apiService = ApiService();

  // Save data locally and try to sync if logged in
  Future<void> saveProgress(Map<String, dynamic> data, String? userId) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Always save to Local State first
    await prefs.setString('local_user_data', jsonEncode(data));

    // 2. If userId exists (Logged in), sync to MongoDB
    if (userId != null) {
      try {
        await _apiService.syncUserData(userId, data);
        print("Synced with DB");
      } catch (e) {
        print("Offline: Saved locally only. Will sync later.");
      }
    }
  }

  // Load data: Try Local first
  Future<Map<String, dynamic>?> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? localData = prefs.getString('local_user_data');
    return localData != null ? jsonDecode(localData) : null;
  }
}
