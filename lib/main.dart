import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // 🛠️ ADDED: Provider package
import 'firebase_options.dart';
import 'screens/root_screen.dart';
import 'services/cart_service.dart'; // 🛠️ ADDED: Your new Cart Engine

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ShacaApp());
}

// 🛠️ Converted to StatefulWidget so the app can update when the theme changes
class ShacaApp extends StatefulWidget {
  const ShacaApp({super.key});

  @override
  State<ShacaApp> createState() => _ShacaAppState();
}

class _ShacaAppState extends State<ShacaApp> {
  // 🌙 State variable to track the current theme mode
  ThemeMode _themeMode = ThemeMode.light;

  // 💡 Function to toggle between Light and Dark modes
  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🛠️ NEW: Wrap the MaterialApp in a MultiProvider so the Cart Service is available everywhere!
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shaca',

        // ✅ Tells the app which theme to show based on the toggle state
        themeMode: _themeMode,

        // ☀️ LIGHT THEME CONFIGURATION (Keeping your exact custom colors)
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          primaryColor: const Color(0xFFFF8C00),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF8C00),
            brightness: Brightness.light,
            primary: const Color(0xFFFF8C00),
            secondary: const Color(0xFF2C3E50),
          ),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            bodyMedium: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 16,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E6ED)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFF7F8C8D)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        // 🌙 DARK THEME CONFIGURATION
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212), // Standard dark background
          primaryColor: const Color(0xFFFF8C00),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF8C00),
            brightness: Brightness.dark,
            primary: const Color(0xFFFF8C00),
            secondary: Colors.white70,
          ),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            bodyMedium: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.white54),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        // ✅ FIXED: Pass the REAL _toggleTheme function instead of an empty one
        home: RootScreen(onToggleTheme: _toggleTheme),
      ),
    );
  }
}