import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyEmail = 'email';
  static const _keyPassword = 'password';
  static const _keyLoggedIn = 'logged_in';

  // Check login status
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  // Register user (DOES NOT LOG IN)
  static Future<String?> register(
      String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    final existingEmail = prefs.getString(_keyEmail);

    if (existingEmail != null &&
        existingEmail == email) {
      return 'Account already exists';
    }

    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
    await prefs.setBool(_keyLoggedIn, false);

    return null; // success
  }

  // Login user (ONLY place that logs in)
  static Future<bool> login(
      String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    final storedEmail = prefs.getString(_keyEmail);
    final storedPassword = prefs.getString(_keyPassword);

    if (email == storedEmail &&
        password == storedPassword) {
      await prefs.setBool(_keyLoggedIn, true);
      return true;
    }
    return false;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
  }
}
