// lib/utils/back_button_interceptor.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> GlobalNavigatorKey = GlobalKey<NavigatorState>();

class BackButtonInterceptor {
  static void setup() {
    // Handle tombol back hardware
    SystemChannels.platform.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'SystemNavigator.pop') {
        final navigator = GlobalNavigatorKey.currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return;
        }
      }
      return;
    });
  }
}