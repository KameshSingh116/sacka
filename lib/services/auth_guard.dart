import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../screens/auth/login_screen.dart';

class AuthGuard {
  static Future<bool> requireLogin(
      BuildContext context,
      VoidCallback onToggleTheme,
      ) async {
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) return true;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(onToggleTheme: onToggleTheme),
      ),
    );

    return await AuthService.isLoggedIn();
  }
}
