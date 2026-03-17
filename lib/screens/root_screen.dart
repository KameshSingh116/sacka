import 'package:flutter/material.dart';
import 'k_home_screen.dart';
import 'add_item_screen.dart';
import 'profile_screen.dart';

class RootScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  // 🛠️ NEW: A global "remote control" to switch tabs from anywhere in the app
  static final ValueNotifier<int> tabNotifier = ValueNotifier<int>(0);

  const RootScreen({super.key, required this.onToggleTheme});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  Widget build(BuildContext context) {
    final screens = [
      KHomeScreen(onToggleTheme: widget.onToggleTheme),
      const AddItemScreen(),
      const ProfileScreen(),
    ];

    // 🛠️ NEW: Automatically updates the UI the exact millisecond tabNotifier changes
    return ValueListenableBuilder<int>(
      valueListenable: RootScreen.tabNotifier,
      builder: (context, currentTab, child) {
        return Scaffold(
          body: IndexedStack(index: currentTab, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentTab,
            onTap: (i) {
              // Standard tap changes the tab normally
              RootScreen.tabNotifier.value = i;
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}