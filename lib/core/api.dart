import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gkrank/core/utils/network_utils.dart';

class ApiService {

  final Dio _dio = Dio(BaseOptions(
    baseUrl: NetworkUtils.baseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  // For user_register.dart
  Future<Response> register(String name, String email, String password) async {
    //print('DEBUG: Attempting API Register for: $email');
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      //print('DEBUG: API Register Success: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      //print('DEBUG: API Register Error: ${e.response?.statusCode} - ${e.response?.data}');
      rethrow;
    }
  }

  // For user_login.dart
  Future<Response> login(String email, String password) async {
    //print('DEBUG: Attempting API Login to: ${_dio.options.baseUrl}/auth/login');
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      //print('DEBUG: API Response Received: ${response.statusCode} - Data: ${response.data}');
      return response;
    } on DioException catch (e) {
      //print('DEBUG: Dio Error: ${e.type} - Message: ${e.message}');
      //print('DEBUG: Response Data from Server: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> syncUserData(String userId, Map<String, dynamic> data) async {
    return await _dio.put('/user/sync/$userId', data: data);
  }

  Future<Response> getAllUsers() async {
    return await _dio.get('/admin/users');
  }

  Future<Response> deleteUser(String userId) async {
    return await _dio.delete('/admin/users/$userId');
  }

  Future<void> getData() async {
    final response = await _dio.get('/user/profile');
    //print(response.data);
  }

  Future<Response> getAllCategories() async {
    return await _dio.get('/admin/category');
  }

  Future<Response> createCategory(String name) async {
    // Matches your request for /category/custom-name
    return await _dio.post('/admin/category/$name');
  }

  Future<Response> addTopic(String categoryName, String topicName) async {
    return await _dio.put(
      '/admin/category/$categoryName',
      data: {'topic': topicName}, 
    );
  }

  Future<Response> getTopics(String categoryName) async {
    return await _dio.get('/admin/category/$categoryName/topics');
  }
  
  // getSubCategories removed - No longer needed

  Future<Response> saveUserProgress(Map<String, dynamic> data) async {
    return await _dio.post('/user/save-progress', data: data);
  }

  Future<Response> syncUserProgress(String userId, List<Map<String, dynamic>> progressData) async {
    return await _dio.post('/user/sync', data: {
      'userId': userId,
      'progress': progressData,
    });
  }

  Future<Response> getUserProgress(String userId) async {
    return await _dio.get('/user/progress/$userId');
  }

  Future<Response> addQuestion(Map<String, dynamic> data) async {
    //print("DEBUG: API Service calling POST /admin/add-question");
    try {
      final response = await _dio.post('/admin/add-question', data: data);
      //print("DEBUG: Dio success status -> ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG: Dio Error -> ${e.message}");
      //print("DEBUG: Dio Error Response -> ${e.response?.data}");
      rethrow;
    }
  }

  Future<Response> getQuestions(String topic) async {
    // Use exact quotes to see if 'topic' contains hidden spaces
    //print("DEBUG: API - Requesting Questions for Topic: '$topic'");

    final response = await _dio.get('/admin/questions/$topic');

    //print("DEBUG: API - getQuestions Response Status: ${response.statusCode}");
    //print("DEBUG: API - getQuestions Raw Data: ${response.data}"); 
    return response;
  }


  // Alias for compatibility
  Future<Response> addBookmark(Map<String, dynamic> bookmarkData) async {
    try {
      // We send the whole map to the server
      final response = await _dio.post('/user/bookmarks/add', data: bookmarkData);
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> saveBookmark(String userId, Map<String, dynamic> questionData) async {
    //print("DEBUG - ApiService/saveBookmark : Attempting to save bookmark for user $userId");
    try {
      final response = await _dio.post('/user/bookmark', data: {
        'userId': userId,
        'question': questionData,
      });
      //print("DEBUG - ApiService/saveBookmark : Success - ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG - ApiService/saveBookmark : Error - ${e.message}");
      rethrow;
    }
  }

  Future<Response> removeBookmark(String userId, String questionId) async {
    //print("DEBUG - ApiService/removeBookmark : Attempting to remove bookmark $questionId for user $userId");
    try {
      final response = await _dio.delete('/user/bookmark/$userId/$questionId');
      //print("DEBUG - ApiService/removeBookmark : Success - ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG - ApiService/removeBookmark : Error - ${e.message}");
      rethrow;
    }
  }

  Future<Response> getUserBookmarks(String userId) async {
    //print("DEBUG - ApiService/getUserBookmarks : Fetching bookmarks for user $userId");
    try {
      final response = await _dio.get('/user/bookmarks/$userId');
      //print("DEBUG - ApiService/getUserBookmarks : Success - ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG - ApiService/getUserBookmarks : Error - ${e.message}");
      rethrow;
    }
  }

  Future<Response> syncBookmarks(String userId, List<Map<String, dynamic>> bookmarks) async {
    //print("DEBUG - ApiService/syncBookmarks : Syncing ${bookmarks.length} bookmarks for user $userId");
    try {
      final response = await _dio.post('/user/bookmarks/sync', data: {
        'userId': userId,
        'bookmarks': bookmarks,
      });
      //print("DEBUG - ApiService/syncBookmarks : Success - ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG - ApiService/syncBookmarks : Error - ${e.message}");
      rethrow;
    }
  }

  Future<Response> googleLogin(String email, String name, String googleId) async {
    //print("DEBUG - ApiService/googleLogin : Attempting Google login for $email");
    try {
      final response = await _dio.post('/auth/google-login', data: {
        'email': email,
        'name': name,
        'googleId': googleId,
      });
      //print("DEBUG - ApiService/googleLogin : Success - ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG - ApiService/googleLogin : Error - ${e.message}");
      rethrow;
    }
  }

  Future<Response> googleSignup(String email, String name, String googleId) async {
    //print("DEBUG - ApiService/googleSignup : Attempting Google signup for $email");
    try {
      final response = await _dio.post('/auth/google-signup', data: {
        'email': email,
        'name': name,
        'googleId': googleId,
      });
      //print("DEBUG - ApiService/googleSignup : Success - ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG - ApiService/googleSignup : Error - ${e.message}");
      rethrow;
    }
  }

  Future<Response> forgotPassword(String email) async {
    //print("DEBUG - ApiService/forgotPassword : Requesting reset for $email");
    try {
      final response = await _dio.post('/auth/forgot-password', data: {'email': email});
      //print("DEBUG - ApiService/forgotPassword : Success - ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG - ApiService/forgotPassword : Error - ${e.message}");
      rethrow;
    }
  }

  Future<Response> verifyOtp(String email, String otp) async {
    //print("DEBUG - ApiService/verifyOtp : Verifying code for $email");
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      //print("DEBUG - ApiService/verifyOtp : Success - ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG - ApiService/verifyOtp : Error - ${e.message}");
      rethrow;
    }
  }

  Future<Response> resetPassword(String email, String otp, String newPassword) async {
    //print("DEBUG - ApiService/resetPassword : Updating password for $email");
    try {
      final response = await _dio.post('/auth/reset-password', data: {
        'email': email,
        'otp': otp,
        'password': newPassword,
      });
      //print("DEBUG - ApiService/resetPassword : Success - ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG - ApiService/resetPassword : Error - ${e.message}");
      rethrow;
    }
  }

  Future<Response> changePassword(String userId, String currentPassword, String newPassword) async {
    //print("DEBUG - ApiService/changePassword : Changing password for user $userId");
    try {
      final response = await _dio.post('/auth/change-password', data: {
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      //print("DEBUG - ApiService/changePassword : Success - ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      //print("DEBUG - ApiService/changePassword : Error - ${e.message}");
      rethrow;
    }
  }

  Future<Response> syncLevelState(String userId, Map<String, dynamic> states) async {
    return await _dio.post('/user/level-state/sync', data: {
      'userId': userId,
      'states': states,
    });
  }

  Future<Response> getUserLevelState(String userId) async {
    return await _dio.get('/user/level-state/$userId');
  }

  Future<Response> deleteAccount(String userId) async {
    return await _dio.delete('/auth/delete-account/$userId');
  }
}
