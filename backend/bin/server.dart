import 'dart:convert';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import 'config.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';

// Middleware for CORS
Middleware corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        });
      }
      final response = await handler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
      });
    };
  };
}

void main() async {
  final db = await initDatabase();

  // 2. Initialize Admin/Test User if needed
  final collection = db.collection('users');
  final adminExists = await collection.findOne(where.eq('role', 'admin'));

  if (adminExists == null) {
    print("DEBUG: Admin not found. Initializing Admin and Test User...");
    await collection.insertMany([
      {
        "name": "Super Admin",
        "email": "admin@app.com",
        "password": "123456",
        "role": "admin",
        "score": 0
      },
      {
        "name": "GK Test User",
        "email": "user@gmail.com",
        "password": "123456",
        "role": "user",
        "score": 0
      }
    ]);
  }

  // 3. Initialize Router
  final router = Router();

  // --- AUTH ROUTES ---
  router.post('/auth/register', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final email = payload['email'];
    print("DEBUG: Register attempt for $email");

    final existing = await db.collection('users').findOne(where.eq('email', email));
    if (existing != null) {
      print("DEBUG: Register failed - $email already exists");
      return Response.badRequest(body: jsonEncode({'error': 'Account already exists'}));
    }

    payload['role'] = 'user';
    payload['score'] = 0;
    payload['createdAt'] = DateTime.now().toIso8601String();
    
    await db.collection('users').insertOne(payload);
    print("DEBUG: Register success - $email created");
    return Response.ok(jsonEncode({'message': 'User registered successfully'}),
        headers: {'content-type': 'application/json'});
  });

  router.post('/auth/login', (Request request) async {
    final body = await request.readAsString();
    final payload = jsonDecode(body);
    final email = payload['email'];
    print("DEBUG: Login attempt for $email");

    final user = await db.collection('users').findOne(where.eq('email', email));

    if (user == null) {
      print("DEBUG: Login failed - User $email not found");
      return Response.notFound(jsonEncode({'error': 'User not found'}));
    }

    if (user['password'].toString() == payload['password'].toString()) {
      print("DEBUG: Login success - $email");
      return Response.ok(jsonEncode(user), headers: {'content-type': 'application/json'});
    } else {
      print("DEBUG: Login failed - Incorrect password for $email");
      return Response.forbidden(jsonEncode({'error': 'Invalid credentials'}));
    }
  });

  // --- USER ROUTES ---
  router.get('/user/profile', (Request request) async {
    final user = await db.collection('users').findOne();
    return Response.ok(jsonEncode(user), headers: {'content-type': 'application/json'});
  });

  // --- ADMIN USER MANAGEMENT ---
  router.get('/admin/users', (Request request) async {
    final users = await db.collection('users').find().toList();
    return Response.ok(jsonEncode(users), headers: {'content-type': 'application/json'});
  });

  router.delete('/admin/users/<id>', (Request request, String id) async {
    await db.collection('users').remove(where.id(ObjectId.fromHexString(id)));
    return Response.ok(jsonEncode({'message': 'User deleted'}),
        headers: {'content-type': 'application/json'});
  });

  // --- CATEGORY MANAGEMENT ---
  router.get('/admin/category', (Request request) async {
    final categories = await db.collection('categories').find().toList();
    return Response.ok(jsonEncode(categories), headers: {'content-type': 'application/json'});
  });

  router.post('/admin/category/<name>', (Request request, String name) async {
    // Categories now just hold a name. Topics link to them.
    await db.collection('categories').insertOne({'name': name});
    return Response.ok(jsonEncode({'message': 'Category created'}),
        headers: {'content-type': 'application/json'});
  });

  // --- TOPIC MANAGEMENT ---
  // Add Topic (Directly under Category)
  router.put('/admin/category/<catName>', (Request request, String catName) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final topicName = payload['topic']; // Expecting { "topic": "Name" }

      final existing = await db.collection('topics').findOne(
          where.eq('name', topicName).and(where.eq('parentCategory', catName))
      );

      if (existing == null) {
        await db.collection('topics').insertOne({
          'name': topicName,
          'parentCategory': catName,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      return Response.ok(jsonEncode({'message': 'Topic created'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  // Get Topics for a Category
  router.get('/admin/category/<catName>/topics', (Request request, String catName) async {
    final topics = await db.collection('topics')
        .find(where.eq('parentCategory', catName))
        .toList();
    return Response.ok(jsonEncode(topics), headers: {'content-type': 'application/json'});
  });

  // --- QUESTION MANAGEMENT ---
  router.post('/admin/add-question', (Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      // Payload should contain 'topic' and 'question' details. 'level' is removed.
      final result = await db.collection('questions').insertOne(payload);
      return Response.ok(jsonEncode({'success': true, 'id': result.id}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  // Get Questions by Topic (No Level)
  router.get('/admin/questions/<topic>', (Request request, String topic) async {
    final decodedTopic = Uri.decodeComponent(topic);
    
    final questions = await db.collection('questions')
        .find(where.eq('topic', decodedTopic))
        .toList();
    return Response.ok(jsonEncode(questions), headers: {'content-type': 'application/json'});
  });

  // --- USER PROGRESS & SYNC (NEW FEATURES) ---
  router.post('/user/save-progress', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final dynamic rawUserId = payload['userId'];
    final String userId = (rawUserId is Map && rawUserId.containsKey('\$oid')) 
        ? rawUserId['\$oid'].toString() 
        : rawUserId.toString();
        
    final topic = payload['topic'];
    // We can keep 'level' in payload if sent, but logic should rely on topic + mode.
    // Or if we want to support multiple "Quiz Attempts" per topic, we might need a unique ID.
    // For now, assuming One Progress per Topic+Mode.
    final mode = payload['mode'] ?? 'default';

    await db.collection('user_progress').update(
      where.eq('userId', userId).and(where.eq('topic', topic)).and(where.eq('mode', mode)),
      payload,
      upsert: true,
    );
    return Response.ok(jsonEncode({'status': 'success'}));
  });

  router.post('/user/sync', (Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final dynamic rawUserId = payload['userId'];
      final String userId = (rawUserId is Map && rawUserId.containsKey('\$oid')) 
          ? rawUserId['\$oid'].toString() 
          : rawUserId.toString();
          
      final List<dynamic> localProgress = payload['progress'];

      final collection = db.collection('user_progress');
      for (var item in localProgress) {
        item['userId'] = userId;
        final topic = item['topic'];
        final mode = item['mode'] ?? 'default';
        
        await collection.update(
          where.eq('userId', userId).and(where.eq('topic', topic)).and(where.eq('mode', mode)),
          item,
          upsert: true,
        );
      }
      return Response.ok(jsonEncode({'status': 'synced'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  router.get('/user/progress/<userId>', (Request request, String userId) async {
    try {
      // 1. Convert the String ID from Flutter back to a MongoDB ObjectId
      final selector = where.eq('userId', userId);

      // 2. Fetch the progress records for this specific user
      final progress = await db.collection('user_progress').find(selector).toList();

      return Response.ok(
          jsonEncode(progress),
          headers: {'content-type': 'application/json'}
      );
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()})
      );
    }
  });

  router.post('/user/bookmarks/add', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final dynamic rawUserId = payload['userId'];
    final String userId = (rawUserId is Map && rawUserId.containsKey('\$oid')) 
        ? rawUserId['\$oid'].toString() 
        : rawUserId.toString();
        
    final question = payload;

    // Standardize to user_bookmarks collection
    await db.collection('user_bookmarks').update(
      where.eq('userId', userId).and(
        where.eq('question.id', question['id']?.toString()).or(where.eq('question._id', question['_id']?.toString()))
      ),
      {
        'userId': userId,
        'question': question,
        'timestamp': DateTime.now().toIso8601String(),
      },
      upsert: true,
    );

    return Response.ok(jsonEncode({'message': 'Bookmarked successfully'}));
  });

  // --- BOOKMARK MANAGEMENT ---
  router.post('/user/bookmark', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final dynamic rawUserId = payload['userId'];
    final String userId = (rawUserId is Map && rawUserId.containsKey('\$oid')) 
        ? rawUserId['\$oid'].toString() 
        : rawUserId.toString();
        
    final question = payload['question'];
    final questionId = (question['id'] ?? question['_id'])?.toString();

    await db.collection('user_bookmarks').update(
      where.eq('userId', userId).and(
        where.eq('question.id', questionId).or(where.eq('question._id', questionId))
      ),
      {
        'userId': userId,
        'question': question,
        'timestamp': DateTime.now().toIso8601String(),
      },
      upsert: true,
    );
    return Response.ok(jsonEncode({'status': 'success'}));
  });

  router.delete('/user/bookmark/<userId>/<questionId>', (Request request, String userId, String questionId) async {
    // userId from URL is already a string
    await db.collection('user_bookmarks').remove(
      where.eq('userId', userId).and(
        where.eq('question.id', questionId).or(where.eq('question._id', questionId))
      )
    );
    return Response.ok(jsonEncode({'status': 'deleted'}));
  });

  router.get('/user/bookmarks/<userId>', (Request request, String userId) async {
    // Robust query: check for String userId OR Map-based userId
    final results = await db.collection('user_bookmarks').find(
      where.eq('userId', userId).or(where.eq('userId', {'\$oid': userId}))
    ).toList();
    // Return just the questions for the frontend
    final bookmarks = results.map((r) => r['question']).toList();
    return Response.ok(jsonEncode(bookmarks), headers: {'content-type': 'application/json'});
  });

  router.post('/user/bookmarks/sync', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final dynamic rawUserId = payload['userId'];
    final String userId = (rawUserId is Map && rawUserId.containsKey('\$oid')) 
        ? rawUserId['\$oid'].toString() 
        : rawUserId.toString();
        
    final List<dynamic> bookmarks = payload['bookmarks'];

    for (var b in bookmarks) {
      final qId = (b['id'] ?? b['_id'])?.toString();
      await db.collection('user_bookmarks').update(
        where.eq('userId', userId).and(
          where.eq('question.id', qId).or(where.eq('question._id', qId))
        ),
        {
          'userId': userId,
          'question': b,
          'timestamp': DateTime.now().toIso8601String(),
        },
        upsert: true,
      );
    }
    return Response.ok(jsonEncode({'status': 'synced'}));
  });
  
  // --- LEVEL STATE SYNC (Answers) ---
  router.post('/user/level-state/sync', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final dynamic rawUserId = payload['userId'];
    final String userId = (rawUserId is Map && rawUserId.containsKey('\$oid')) 
        ? rawUserId['\$oid'].toString() 
        : rawUserId.toString();
        
    final states = payload['states']; // Map<String, dynamic> where key is topic_level_mode

    await db.collection('user_level_states').update(
      where.eq('userId', userId),
      {
        'userId': userId,
        'states': states,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      upsert: true,
    );
    return Response.ok(jsonEncode({'status': 'success'}));
  });

  router.get('/user/level-state/<userId>', (Request request, String userId) async {
    final result = await db.collection('user_level_states').findOne(where.eq('userId', userId));
    return Response.ok(jsonEncode(result?['states'] ?? {}), headers: {'content-type': 'application/json'});
  });

  // --- DELETE ACCOUNT ---
  router.delete('/auth/delete-account/<userId>', (Request request, String userId) async {
    print("DEBUG: Deleting account and data for $userId");

    // 1. Delete user record
    final deleteResult = await db.collection('users').remove(where.id(ObjectId.fromHexString(userId)));
    
    if (deleteResult['n'] == 0) {
      return Response.notFound(jsonEncode({'error': 'User not found'}));
    }

    // 2. Clean up associated data
    await db.collection('user_progress').remove(where.eq('userId', userId));
    await db.collection('user_bookmarks').remove(where.eq('userId', userId));
    await db.collection('user_level_states').remove(where.eq('userId', userId));

    print("DEBUG: All data for $userId successfully removed.");
    return Response.ok(jsonEncode({'status': 'deleted', 'success': true}), headers: {'content-type': 'application/json'});
  });

  // --- GOOGLE AUTH & PASSWORD RESET ---
  router.post('/auth/google-login', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final email = (payload['email'] as String?)?.trim();
    final name = payload['name'];
    final googleId = payload['googleId'];
    print("DEBUG: Google Login Payload - Email: $email, Name: $name, ID: $googleId");

    var user = await db.collection('users').findOne(where.eq('email', email));

    if (user != null) {
      // User exists, update/link googleId if not present
      if (user['googleId'] == null) {
        await db.collection('users').updateOne(
            where.eq('email', email),
            modify.set('googleId', googleId).set('signupSource', 'google')
        );
        user = await db.collection('users').findOne(where.eq('email', email));
      }
      return Response.ok(jsonEncode(user), headers: {'content-type': 'application/json'});
    } else {
      // User not found
      return Response.notFound(jsonEncode({'error': 'User not found', 'code': 'USER_NOT_FOUND'}));
    }
  });

  router.post('/auth/google-signup', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final email = (payload['email'] as String?)?.trim();
    print("DEBUG: Google Signup Payload - Email: $email");

    final existing = await db.collection('users').findOne(where.eq('email', email));
    if (existing != null) {
      return Response.badRequest(body: jsonEncode({'error': 'Account already exists'}));
    }

    payload['signupSource'] = 'google';
    payload['role'] = 'user';
    await db.collection('users').insertOne(payload);
    print("DEBUG: Google User Created - $email");
    final user = await db.collection('users').findOne(where.eq('email', email));
    return Response.ok(jsonEncode(user), headers: {'content-type': 'application/json'});
  });

  router.post('/auth/forgot-password', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final email = (payload['email'] as String?)?.trim();
    final user = await db.collection('users').findOne(where.eq('email', email));

    print("----------------------------------------------------------------");
    print("DEBUG: Password - STEP 1: Request received for Password Reset for: $email");

    if (user == null) {
      print("DEBUG: Password - STEP 2: [FAILURE] Email $email not found in database.");
      print("DEBUG: Password - ----------------------------------------------------------------");
      return Response.notFound(jsonEncode({'error': 'Email not found'}));
    }
    print("DEBUG: Password - STEP 2: [SUCCESS] User found in database: ${user['_id']}");

    // Generate a random 6-digit OTP
    final otp = (100000 + Random().nextInt(900000)).toString();
    print("DEBUG: Password - STEP 3: Generated Random OTP: $otp");

    await db.collection('users').updateOne(
        where.eq('email', email),
        modify.set('otpCode', otp).set('otpExpiry', DateTime.now().add(const Duration(minutes: 10)).toIso8601String())
    );
    print("DEBUG: Password - STEP 4: [SUCCESS] OTP saved to database for user.");

    // Real Email Sending
    // Real Email Sending
    // check config.dart for credentials
    if (smtpPassword == 'INSERT_YOUR_PASSWORD_HERE') {
      print("DEBUG: Password - ERROR: Password not set in bin/config.dart");
      return Response.internalServerError(body: jsonEncode({'error': 'Server Misconfigured: Password not set'}));
    }

    print("DEBUG: Password - STEP 5: Configuring SMTP Server with user: $smtpEmail");
    // Note: If using non-gmail, switch to SmtpServer(host, port: port)
    final smtpServer = gmail(smtpEmail, smtpPassword);


    final message = Message()
      ..from = Address('meenakshi.s@cybomb.com', 'GKRank Support')
      ..recipients.add(email)
      ..subject = 'Your Password Reset OTP'
      ..text = 'Hello,\n\nYour OTP code is $otp.\n\nIt is valid for 10 minutes.\n\nRegards,\nAptigo Team';

    print("DEBUG: Password - STEP 6: Attempting to send email to $email...");
    try {
      final sendReport = await send(message, smtpServer);
      print("DEBUG: Password - STEP 7: [SUCCESS] Email sent successfully!");
      print('DEBUG: Password - SMTP Report: ' + sendReport.toString());
      print("DEBUG: Password - ----------------------------------------------------------------");
      return Response.ok(jsonEncode({'message': 'OTP sent to $email'}),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      print("DEBUG: Password - STEP 7: [FAILURE] Email sending failed.");
      print("DEBUG: Password - ERROR DETAILS: " + e.toString());
      print("DEBUG: Password - FALLBACK OTP LOG (for testing): $otp");
      print("DEBUG: Password - ----------------------------------------------------------------");

      // Return specific error if auth failed
      if (e.toString().contains("Authentication Failed")) {
        return Response.internalServerError(body: jsonEncode({'error': 'Server Email Auth Failed. Check App Password.'}));
      }
      return Response.internalServerError(body: jsonEncode({'error': 'Failed to send OTP. Check server logs.'}));
    }
  });

  router.post('/auth/verify-otp', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final email = (payload['email'] as String?)?.trim();
    final otp = payload['otp'];

    print("----------------------------------------------------------------");
    print("DEBUG: Password(Verify) - STEP 1: Request received for $email with Code: $otp");

    final user = await db.collection('users').findOne(where.eq('email', email));
    if (user == null) {
      print("DEBUG: Password(Verify) - STEP 2: [FAILURE] User not found for $email");
      print("----------------------------------------------------------------");
      return Response.notFound(jsonEncode({'error': 'User not found'}));
    }

    print("DEBUG: Password(Verify) - STEP 2: [SUCCESS] User found. Stored Code: ${user['otpCode']} | Expiry: ${user['otpExpiry']}");

    if (user['otpCode'] == otp) {
      final expiryStr = user['otpExpiry'];
      if (expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          print("DEBUG: Password(Verify) - STEP 3: [FAILURE] OTP Expired. Current: ${DateTime.now()}, Expiry: $expiry");
          print("----------------------------------------------------------------");
          return Response.forbidden(jsonEncode({'error': 'OTP expired', 'success': false}));
        }
      }
      print("DEBUG: Password(Verify) - STEP 3: [SUCCESS] OTP Verified.");
      print("----------------------------------------------------------------");
      return Response.ok(jsonEncode({'message': 'OTP verified successfully', 'success': true}),
          headers: {'content-type': 'application/json'});
    } else {
      print("DEBUG: Password(Verify) - STEP 3: [FAILURE] OTP Mismatch. Provided: $otp, Stored: ${user['otpCode']}");
      print("----------------------------------------------------------------");
      return Response.forbidden(jsonEncode({'error': 'Invalid OTP', 'success': false}));
    }
  });

  router.post('/auth/reset-password', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final email = (payload['email'] as String?)?.trim();
    final otp = payload['otp'];
    final newPassword = payload['password'];

    print("----------------------------------------------------------------");
    print("DEBUG: Password(Reset) - STEP 1: Request received for $email");

    final user = await db.collection('users').findOne(where.eq('email', email));

    if (user != null) {
      print("DEBUG: Password(Reset) - STEP 2: [SUCCESS] User found. Stored Code: ${user['otpCode']}");
    } else {
      print("DEBUG: Password(Reset) - STEP 2: [FAILURE] User NOT found.");
      print("----------------------------------------------------------------");
      return Response.forbidden(jsonEncode({'error': 'Invalid request'}));
    }

    if (user['otpCode'] != otp) {
      print("DEBUG: Password(Reset) - STEP 3: [FAILURE] OTP Mismatch. Provided: $otp, Stored: ${user['otpCode']}");
      print("----------------------------------------------------------------");
      return Response.forbidden(jsonEncode({'error': 'Invalid OTP'}));
    }

    final expiryStr = user['otpExpiry'];
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        print("DEBUG: Password(Reset) - STEP 3: [FAILURE] OTP Expired.");
        print("----------------------------------------------------------------");
        return Response.forbidden(jsonEncode({'error': 'OTP expired'}));
      }
    }

    await db.collection('users').updateOne(
        where.eq('email', email),
        modify.set('password', newPassword).unset('otpCode').unset('otpExpiry')
    );
    print("DEBUG: Password(Reset) - STEP 4: [SUCCESS] Password updated in DB. OTP Cleared.");
    print("----------------------------------------------------------------");

    return Response.ok(jsonEncode({'message': 'Password reset successfully'}),
        headers: {'content-type': 'application/json'});
  });

  router.post('/auth/change-password', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final userId = payload['userId'];
    final currentPassword = payload['currentPassword'];
    final newPassword = payload['newPassword'];

    final user = await db.collection('users').findOne(where.id(ObjectId.fromHexString(userId)));
    if (user == null) return Response.notFound(jsonEncode({'error': 'User not found'}));

    // If they have a password, we must check it. 
    // If they only have GoogleId (traditional password is null), we allow setting one.
    if (user['password'] != null && user['password'] != currentPassword) {
      return Response.forbidden(jsonEncode({'error': 'Incorrect current password'}));
    }

    await db.collection('users').updateOne(
        where.id(ObjectId.fromHexString(userId)),
        modify.set('password', newPassword)
    );

    return Response.ok(jsonEncode({'message': 'Password changed successfully'}));
  });

  // --- SERVER STARTUP ---
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addHandler(router.call);

  await io.serve(handler, '0.0.0.0', 8080);
  print('Server live at http://localhost:8080');

  // await io.serve(handler, '0.0.0.0', 5021);
  // print('Server live at http://localhost:5021');
}
