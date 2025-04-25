// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'config/routes.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

// Navigator Observer untuk debugging
class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    developer.log('NAVIGASI: PUSH ke ${route.settings.name} dari ${previousRoute?.settings.name}', name: 'Navigation');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    developer.log('NAVIGASI: POP dari ${route.settings.name} ke ${previousRoute?.settings.name}', name: 'Navigation');
    super.didPop(route, previousRoute);
  }
}

// Global Navigator Key untuk akses navigator dari mana saja
class GlobalNavigatorKey {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}

class ManukPosApp extends StatelessWidget {
  const ManukPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return MaterialApp(
      title: 'MANUK - Manajemen Keuangan UMKM',
      debugShowCheckedModeBanner: false,
      
      // Tambahkan navigatorKey untuk akses global
      navigatorKey: GlobalNavigatorKey.key,
      
      // Tambahkan observer untuk debugging navigasi
      navigatorObservers: [
        NavigationObserver(),
      ],
      
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Default to light theme
      
      // Localization settings for Indonesian
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesian
        Locale('en', 'US'), // English
      ],
      locale: const Locale('id', 'ID'), // Default to Indonesian
      
      // Route settings
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
      
      // Builder untuk implementasi PopScope (pengganti WillPopScope)
      builder: (context, child) {
        return PopScope(
          canPop: false, // Default tidak bisa pop
          onPopInvoked: (didPop) {
            // Ketika tombol back ditekan
            if (didPop) return;

            // Cek apakah Navigator dapat pop
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            }
          },
          child: child ?? Container(),
        );
      },
      
      // Handle initial route based on authentication state
      home: FutureBuilder<bool>(
        future: authService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final bool isLoggedIn = snapshot.data ?? false;
          return isLoggedIn ? const DashboardScreen() : const LoginScreen();
        },
      ),
    );
  }
}