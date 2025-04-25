// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart'; // Tambahkan package logging
import 'app.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';

// Global Navigator Key untuk akses navigator dari mana saja
class GlobalNavigatorKey {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}

// Logger untuk aplikasi
final Logger _logger = Logger('Navigation');

// Navigator Observer untuk debugging
class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.info('NAVIGASI: PUSH ke ${route.settings.name} dari ${previousRoute?.settings.name}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.info('NAVIGASI: POP dari ${route.settings.name} ke ${previousRoute?.settings.name}');
    super.didPop(route, previousRoute);
  }
}

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup logging
  _setupLogging();

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
  
  final apiService = ApiService(baseUrl: 'https://documenter.getpostman.com/view/37267696/2sB2ca8L6X');
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
        // Tambahkan Provider untuk GlobalNavigatorKey
        Provider<GlobalKey<NavigatorState>>.value(
          value: GlobalNavigatorKey.key,
        ),
      ],
      child: const ManukPosApp(),
    ),
  );
}

// Setup logging configuration
void _setupLogging() {
  Logger.root.level = Level.ALL; // Atur level logging sesuai kebutuhan
  Logger.root.onRecord.listen((record) {
    // Dalam pengembangan, cetak ke konsol
    if (record.level >= Level.INFO) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
    
    // Dalam produksi, implementasikan penyimpanan log ke file atau layanan pihak ketiga
    // (Firebase Crashlytics, Sentry, dll) di sini
  });
}