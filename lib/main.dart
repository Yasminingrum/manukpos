import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize services
  final sharedPrefs = await SharedPreferences.getInstance();
  final databaseService = DatabaseService();
  // Initialize database - method call removed as we'll need to implement this in DatabaseService class
  
  final apiService = ApiService(baseUrl: 'https://api.manuk-pos.com/v1');
  final authService = AuthService(
    databaseService: databaseService,
    apiService: apiService,
    sharedPreferences: sharedPrefs,
  );
  
  final syncService = SyncService(
    databaseService: databaseService,
    apiService: apiService,
  );
  
  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<ApiService>.value(value: apiService),
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
      ],
      child: const ManukPosApp(),
    ),
  );
}
