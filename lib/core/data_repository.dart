import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class DataRepository {
  final ApiService _api = ApiService();

  // Keys for Local Storage (Prefixes)
  static const String _keyProgressBase = 'user_progress';
  static const String _keyUserId = 'user_id';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyLevelStateBase = 'user_level_state';
  static const String _keyBookmarksBase = 'user_bookmarks';
  static const String _keyUserData = 'user_data';
  static const String _keyTheme = 'app_theme';

  static String parseId(dynamic rawId) {
    if (rawId == null) return "";
    if (rawId is String) return rawId;
    if (rawId is Map) {
      if (rawId.containsKey('\$oid')) return rawId['\$oid'].toString();
      // Nested check for cases where the map itself is { "userId": { "$oid": "..." } }
      if (rawId.containsKey('_id')) return parseId(rawId['_id']);
      if (rawId.containsKey('id')) return parseId(rawId['id']);
    }
    return rawId.toString();
  }

  /// Helper to get user-specific key
  Future<String> _getKey(String base) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString(_keyUserId) ?? 'guest';
    final String key = "${base}_$userId";
    //print("DEBUG - DataRepository/_getKey : Accessing partition for User: $userId -> Key: $key");
    return key;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Get Current User ID (or 'guest')
  Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId) ?? 'guest';
  }

  /// Save User Progress w/ Mode Separation
  Future<void> saveProgress(Map<String, dynamic> progressData) async {
    final prefs = await SharedPreferences.getInstance();
    final bool online = await isLoggedIn();
    final String key = await _getKey(_keyProgressBase);
    
    // Always save locally first (as cache or primary source)
    List<String> localData = prefs.getStringList(key) ?? [];
    
    // Remove duplicate entry if exists (Topic + Mode)
    localData.removeWhere((item) {
      final json = jsonDecode(item);
      bool sameTopic = json['topic'] == progressData['topic'];
      
      String jsonMode = json['mode'] ?? "";
      String newMode = progressData['mode'] ?? "";
      
      return sameTopic && (jsonMode == newMode);
    });
    
    localData.add(jsonEncode(progressData));
    await prefs.setStringList(key, localData);

    // If Online, Sync immediately
    if (online) {
      final userId = prefs.getString(_keyUserId);
      if (userId != null) {
        progressData['userId'] = userId; 
        try {
          await _api.saveUserProgress(progressData);
        } catch (e) {
          //print("Failed to sync progress: $e");
        }
      }
    }
  }

  /// Get Progress for specific Topic + Mode
  Future<Map<String, dynamic>?> getProgress(String topic, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getKey(_keyProgressBase);
    List<String> localData = prefs.getStringList(key) ?? [];
    for (String item in localData) {
      final json = jsonDecode(item);
      final jsonMode = json['mode'] ?? "";
      
      if (json['topic'] == topic && jsonMode == mode) {
        return json;
      }
    }
    return null;
  }

  /// Get ALL Progress (Calculated for Topics Screen)
  Future<List<Map<String, dynamic>>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getKey(_keyProgressBase);
    List<String> localData = prefs.getStringList(key) ?? [];
    return localData.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// Get progress grouped by topic (for Recent Activity)
  Future<List<Map<String, dynamic>>> getGroupedProgress() async {
    final allProgress = await getAllProgress();
    
    // Group by topic
    Map<String, Map<String, dynamic>> grouped = {};
    
    for (var progress in allProgress) {
      final topic = progress['topic'] ?? 'Unknown';
      
      if (!grouped.containsKey(topic)) {
        grouped[topic] = {
          'topic': topic,
          'modes': <String, dynamic>{},
          'timestamp': progress['timestamp'],
        };
      }
      
      // Add mode data
      final mode = progress['mode'] ?? 'Unknown';
      grouped[topic]!['modes'][mode] = {
        'score': progress['score'],
        'total': progress['total'],
        'completed': progress['completed'],
        'timestamp': progress['timestamp'],
      };
      
      // Update timestamp to most recent
      if (progress['timestamp'] != null) {
        final currentTime = DateTime.tryParse(grouped[topic]!['timestamp'] ?? '') ?? DateTime(2000);
        final newTime = DateTime.tryParse(progress['timestamp']) ?? DateTime(2000);
        if (newTime.isAfter(currentTime)) {
          grouped[topic]!['timestamp'] = progress['timestamp'];
        }
      }
    }
    
    // Convert to list and sort by timestamp
    final result = grouped.values.toList();
    result.sort((a, b) {
      final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
      final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
      return bTime.compareTo(aTime); // Most recent first
    });
    
    return result;
  }

  /// Sync Local Data to Server (Call this on Login)
  Future<void> syncLocalToRemote(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    // We sync from GUEST key to ACCOUNT
    final String guestKey = "${_keyProgressBase}_guest";
    List<String> localStrings = prefs.getStringList(guestKey) ?? [];
    
    if (localStrings.isEmpty) return;

    List<Map<String, dynamic>> batch = [];
    for (String item in localStrings) {
      final Map<String, dynamic> map = jsonDecode(item);
      map['userId'] = userId;
      batch.add(map);
    }

    try {
      await _api.syncUserProgress(userId, batch);
      // After sync, we could clear guest data if you want, but user said "saved with that account"
      // Let's clear guest data to prevent double syncing next time
      await prefs.remove(guestKey);
      //print("DEBUG - DataRepository/syncLocalToRemote : Synced and cleared GUEST data to account $userId");
    } catch (e) {
      //print("DEBUG - DataRepository/syncLocalToRemote : Sync failed: $e");
    }
  }

  /// Fetch Remote Data to Local and MERGE
  Future<void> fetchRemoteToLocal(String userId) async {
    try {
      final response = await _api.getUserProgress(userId);
      final List<dynamic> remoteData = response.data;
      
      final prefs = await SharedPreferences.getInstance();
      final String key = "${_keyProgressBase}_$userId";
      List<String> localStrings = prefs.getStringList(key) ?? [];
      Map<String, Map<String, dynamic>> merged = {};
      
      for (var s in localStrings) {
        final data = jsonDecode(s) as Map<String, dynamic>;
        // Use Topic + Mode as unique key
        final mKey = "${data['topic']}_${data['mode'] ?? ""}";
        merged[mKey] = data;
      }

      for (var remote in remoteData) {
        final mKey = "${remote['topic']}_${remote['mode'] ?? ""}";
        if (merged.containsKey(mKey)) {
          final local = merged[mKey]!;
          final DateTime remoteTime = DateTime.tryParse(remote['timestamp'] ?? "") ?? DateTime(2000);
          final DateTime localTime = DateTime.tryParse(local['timestamp'] ?? "") ?? DateTime(2000);
          if (remoteTime.isAfter(localTime)) {
             merged[mKey] = Map<String, dynamic>.from(remote);
          }
        } else {
          merged[mKey] = Map<String, dynamic>.from(remote);
        }
      }

      await prefs.setStringList(key, merged.values.map((e) => jsonEncode(e)).toList());
    } catch (e) {
      //print("Fetch failed: $e");
    }
  }

  /// Save Topic State (Selected Answers) - Renamed from saveLevelState
  Future<void> saveTopicState(String topic, String mode, Map<int, String?> answers) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getKey(_keyLevelStateBase);
    
    String stateKey = "${topic}_$mode";
    Map<String, String> stringKeysMap = {};
    answers.forEach((k, v) {
      if(v != null) stringKeysMap[k.toString()] = v;
    });

    String jsonValue = jsonEncode(stringKeysMap);
    String? allStatesStr = prefs.getString(key);
    Map<String, dynamic> allStates = allStatesStr != null ? jsonDecode(allStatesStr) : {};

    allStates[stateKey] = jsonValue;
    await prefs.setString(key, jsonEncode(allStates));
  }

  /// Get Topic State
  Future<Map<int, String?>?> getTopicState(String topic, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getKey(_keyLevelStateBase);
    
    String? allStatesStr = prefs.getString(key);
    if (allStatesStr == null) return null;

    Map<String, dynamic> allStates = jsonDecode(allStatesStr);
    String stateKey = "${topic}_$mode";
    
    if (allStates.containsKey(stateKey)) {
      Map<String, dynamic> stringMap = jsonDecode(allStates[stateKey]);
      Map<int, String?> finalMap = {};
      stringMap.forEach((k, v) => finalMap[int.parse(k)] = v.toString());
      return finalMap;
    }
    return null;
  }

  /// Clear Topic State (Reset)
  Future<void> clearTopicState(String topic, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final String stateKeyBase = await _getKey(_keyLevelStateBase);
    final String progressKeyBase = await _getKey(_keyProgressBase);
    
    // 1. Clear Answers
    String? allStatesStr = prefs.getString(stateKeyBase);
    if (allStatesStr != null) {
      Map<String, dynamic> allStates = jsonDecode(allStatesStr);
      String key = "${topic}_$mode";
      if (allStates.containsKey(key)) {
        allStates.remove(key);
        await prefs.setString(stateKeyBase, jsonEncode(allStates));
      }
    }
    
    // 2. Clear Progress
    List<String> localData = prefs.getStringList(progressKeyBase) ?? [];
    List<String> updatedData = localData.where((item) {
      final json = jsonDecode(item);
      return !(json['topic'] == topic && (json['mode'] ?? "") == mode);
    }).toList();
    
    await prefs.setStringList(progressKeyBase, updatedData);
  }

  /// Sync Level States (Answers) to Server
  Future<void> syncLevelStateToRemote(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String guestKey = "${_keyLevelStateBase}_guest";
    final String guestDataStr = prefs.getString(guestKey) ?? "{}";
    final Map<String, dynamic> guestData = jsonDecode(guestDataStr);

    if (guestData.isEmpty) return;

    try {
      await _api.syncLevelState(userId, guestData);
      await prefs.remove(guestKey);
      //print("DEBUG - DataRepository/syncLevelStateToRemote : Success - Migrated guest states to $userId");
    } catch (e) {
      //print("DEBUG - DataRepository/syncLevelStateToRemote : Error - $e");
    }
  }

  /// Fetch Level States from Server
  Future<void> fetchLevelStatesToLocal(String userId) async {
    try {
      final response = await _api.getUserLevelState(userId);
      final Map<String, dynamic> remoteData = Map<String, dynamic>.from(response.data);
      
      final prefs = await SharedPreferences.getInstance();
      final String key = "${_keyLevelStateBase}_$userId";
      
      // For answers, we usually just overwrite or merge. 
      // Let's merge - if local has it, keep local (as it might be the most recent session)
      final String localDataStr = prefs.getString(key) ?? "{}";
      final Map<String, dynamic> localData = jsonDecode(localDataStr);
      
      remoteData.forEach((k, v) {
        if (!localData.containsKey(k)) {
          localData[k] = v;
        }
      });

      await prefs.setString(key, jsonEncode(localData));
      //print("DEBUG - DataRepository/fetchLevelStatesToLocal : Success - Merged states for $userId");
    } catch (e) {
      //print("DEBUG - DataRepository/fetchLevelStatesToLocal : Error - $e");
    }
  }
  
  /// Clear only the session flags (Persistent data stays in local storage)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString(_keyUserId);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserData);
    await prefs.setBool(_keyIsLoggedIn, false);
    //print("DEBUG - DataRepository/clearSession : Session Flags Cleared for $userId. Partition data PRESERVED.");
  }

  /// Explicitly delete all local data for a specific user ID
  Future<void> wipeUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String progressKey = "${_keyProgressBase}_$userId";
    final String stateKey = "${_keyLevelStateBase}_$userId";
    final String bookmarkKey = "${_keyBookmarksBase}_$userId";

    await prefs.remove(progressKey);
    await prefs.remove(stateKey);
    await prefs.remove(bookmarkKey);
    
    //print("DEBUG - DataRepository/wipeUserData : ALL partition data DELETED for User: $userId");
  }

  /// Save full user session
  Future<void> saveUserSession(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = parseId(userData['_id'] ?? userData['id']);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserData, jsonEncode(userData));
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyUserData);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // --- Theme Management ---
  Future<void> saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, mode.toString());
    //print("DEBUG - DataRepository/saveTheme : Success - Set to $mode");
  }

  Future<ThemeMode> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeStr = prefs.getString(_keyTheme);
    if (themeStr == "ThemeMode.light") return ThemeMode.light;
    if (themeStr == "ThemeMode.dark") return ThemeMode.dark;
    return ThemeMode.system;
  }

  // --- Bookmarks Section ---

  Future<void> toggleBookmark(Map<String, dynamic> questionData, {String? category, String? subCategory, String? topic, String? levelName}) async {
    final prefs = await SharedPreferences.getInstance();
    final bool online = await isLoggedIn();
    final String? userId = prefs.getString(_keyUserId);
    final String key = await _getKey(_keyBookmarksBase);
    
    // Check both 'id' and '_id' (from Mongo)
    final String qId = (questionData['id'] ?? questionData['_id'])?.toString() ?? "";

    if (qId.isEmpty) {
      //print("DEBUG - DataRepository/toggleBookmark : Error - Question ID is empty. Data: $questionData");
      return;
    }

    // Prepare enriched question data
    final Map<String, dynamic> enrichedData = Map<String, dynamic>.from(questionData);
    if (category != null) enrichedData['category'] = category;
    if (subCategory != null) enrichedData['subCategory'] = subCategory;
    if (topic != null) enrichedData['topic'] = topic;
    if (levelName != null) enrichedData['levelName'] = levelName;

    List<String> bookmarks = prefs.getStringList(key) ?? [];
    bool isBookmarked = bookmarks.any((item) {
       final data = jsonDecode(item);
       return (data['id'] ?? data['_id'])?.toString() == qId;
    });

    if (isBookmarked) {
      // Remove
      bookmarks.removeWhere((item) => (jsonDecode(item)['id'] ?? jsonDecode(item)['_id'])?.toString() == qId);
      //print("DEBUG - DataRepository/toggleBookmark : Success - Removed locally ($qId)");
      if (online && userId != null) {
        try {
          await _api.removeBookmark(userId, qId);
        } catch (e) {
          //print("DEBUG - DataRepository/toggleBookmark : Error - Remote remove failed: $e");
        }
      }
    } else {
      // Add
      bookmarks.add(jsonEncode(enrichedData));
      //print("DEBUG - DataRepository/toggleBookmark : Success - Added locally ($qId)");
      if (online && userId != null) {
        try {
          await _api.saveBookmark(userId, enrichedData);
        } catch (e) {
          //print("DEBUG - DataRepository/toggleBookmark : Error - Remote save failed: $e");
        }
      }
    }

    await prefs.setStringList(key, bookmarks);
  }

  Future<bool> isBookmarked(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getKey(_keyBookmarksBase);
    List<String> bookmarks = prefs.getStringList(key) ?? [];
    return bookmarks.any((item) {
       final data = jsonDecode(item);
       return (data['id'] ?? data['_id'])?.toString() == questionId;
    });
  }

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getKey(_keyBookmarksBase);
    List<String> bookmarks = prefs.getStringList(key) ?? [];
    return bookmarks.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> syncBookmarksToRemote(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    // Sync guest bookmarks to account
    final String guestKey = "${_keyBookmarksBase}_guest";
    List<String> localBookmarks = prefs.getStringList(guestKey) ?? [];
    
    if (localBookmarks.isEmpty) {
      // If guest is empty, maybe sync current user (though fetch does that)
      return;
    }

    List<Map<String, dynamic>> bookmarks = localBookmarks.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    try {
      await _api.syncBookmarks(userId, bookmarks);
      await prefs.remove(guestKey);
      //print("DEBUG - DataRepository/syncBookmarksToRemote : Success - Synced guest bookmarks to $userId");
    } catch (e) {
      //print("DEBUG - DataRepository/syncBookmarksToRemote : Error - $e");
    }
  }

  Future<void> fetchBookmarksToLocal(String userId) async {
    try {
      final response = await _api.getUserBookmarks(userId);
      final List<dynamic> remoteData = response.data;
      
      final prefs = await SharedPreferences.getInstance();
      final String key = "${_keyBookmarksBase}_$userId";
      List<String> localStrings = prefs.getStringList(key) ?? [];
      Map<String, Map<String, dynamic>> merged = {};
      
      for (var s in localStrings) {
        final data = jsonDecode(s) as Map<String, dynamic>;
        final String qId = (data['id'] ?? data['_id'])?.toString() ?? "";
        if (qId.isNotEmpty) merged[qId] = data;
      }

      for (var remote in remoteData) {
        final String qId = (remote['id'] ?? remote['_id'])?.toString() ?? "";
        if (qId.isNotEmpty) merged[qId] = Map<String, dynamic>.from(remote);
      }

      await prefs.setStringList(key, merged.values.map((e) => jsonEncode(e)).toList());
      //print("DEBUG - DataRepository/fetchBookmarksToLocal : Success - Merged ${merged.length} bookmarks for $userId");
    } catch (e) {
      //print("DEBUG - DataRepository/fetchBookmarksToLocal : Error - $e");
    }
  }
}
