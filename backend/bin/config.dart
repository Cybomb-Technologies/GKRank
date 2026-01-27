import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

// Helper to load .env manually
Map<String, String> loadEnv() {
  final env = <String, String>{};

  // Try multiple possible locations for .env
  final paths = [
    '.env', // Current directory
    'bin/.env', // If run from root
    '../.env', // Parent directory (if run from bin/)
    '../../.env', // Two levels up (if run from backend/bin/)
  ];

  File? envFile;
  for (var path in paths) {
    final file = File(path);
    if (file.existsSync()) {
      envFile = file;
      break;
    }
  }

  if (envFile != null) {
    print("DEBUG: Loading environment from ${envFile.absolute.path}");
    final lines = envFile.readAsLinesSync();
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('=');
      if (parts.length >= 2) {
        env[parts[0].trim()] = parts.sublist(1).join('=').trim();
      }
    }
  } else {
    print("WARNING: No .env file found in expected locations: $paths");
  }
  return env;
}

Future<Db> initDatabase() async {
  final env = loadEnv();
  final appEnv = env['APP_ENV']?.toLowerCase() ?? 'local';
  final mongoUri = appEnv == 'production' || appEnv == 'live'
      ? env['MONGO_URI_LIVE']
      : env['MONGO_URI_LOCAL'];

  if (mongoUri == null || mongoUri.isEmpty) {
    throw Exception("ERROR: MongoDB URI not found in .env for environment: $appEnv");
  }

  print("DEBUG: Connecting to Database in $appEnv mode...");
  final db = await Db.create(mongoUri);
  await db.open();
  print("DEBUG: Connected to MongoDB at $mongoUri");
  return db;
}

// SMTP Configuration
const String smtpEmail = 'ms.cybombtech@gmail.com';
const String smtpPassword = 'sovesqgzqabpsvdw'; 
