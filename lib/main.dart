import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/root/root_screen.dart';

void main() {
  runApp(const SackaApp());
}

class SackaApp extends StatefulWidget {
  const SackaApp({super.key});

  @override
  State<SackaApp> createState() => _SackaAppState();
}

class _SackaAppState extends State<SackaApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SACKA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data!
              ? RootScreen(onToggleTheme: toggleTheme)
              : LoginScreen(onToggleTheme: toggleTheme);
        },
      ),
    );
  }
}
