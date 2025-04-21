import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

class ManukPosApp extends StatelessWidget {
  const ManukPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return MaterialApp(
      title: 'MANUK - Manajemen Keuangan UMKM',
      debugShowCheckedModeBanner: false,
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