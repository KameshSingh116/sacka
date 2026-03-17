import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🛠️ ADDED: Firestore import
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'rental_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showDevelopingToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("This feature is coming soon!"), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      // 🎧 StreamBuilder listens to Firebase Auth state in real-time
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // ⏳ Show a loader while checking
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)));
          }

          final user = snapshot.data;

          // 🚫 If no user is logged in, show the Guest UI
          if (user == null) {
            return _buildGuestUI(context);
          }

          // ✅ If logged in, show their personal dashboard
          return _buildUserDashboard(context, user);
        },
      ),
    );
  }

  // ----------------------------------------------------------------
  // 👤 GUEST UI (Not Logged In)
  // ----------------------------------------------------------------
  Widget _buildGuestUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, size: 80, color: Color(0xFFFF8C00)),
            ),
            const SizedBox(height: 32),
            const Text(
              'Join the ShaCa Community',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Log in to rent tools, list your own machinery, and connect with your neighborhood.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Log In / Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 📱 AUTHENTICATED UI (Logged In Dashboard)
  // ----------------------------------------------------------------
  Widget _buildUserDashboard(BuildContext context, User user) {
    // 🛠️ Wrap the dashboard in a Firestore StreamBuilder to get real user data!
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Default fallbacks just in case
        String displayName = 'ShaCa Member';
        String contactInfo = user.email ?? user.phoneNumber ?? 'No contact info provided';

        // Extract real data from Firestore
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          displayName = userData['name'] ?? displayName;
          contactInfo = userData['email'] ?? userData['phone'] ?? contactInfo;
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- HEADER SECTION ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFFF8C00),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S', // First initial
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contactInfo,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- MENU OPTIONS ---
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'My Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
            ),

            _buildMenuTile(Icons.handyman_outlined, 'My Listed Tools', 'Manage items you are renting out', () {
              _showDevelopingToast(context);
            }),
            _buildMenuTile(Icons.history_outlined, 'Rental History', 'View tools you have rented', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RentalHistoryScreen()),
              );
            }),
            _buildMenuTile(Icons.favorite_border, 'Saved Items', 'Tools you are watching', () {
              _showDevelopingToast(context);
            }),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Account Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
            ),

            _buildMenuTile(Icons.person_outline, 'Edit Profile', 'Update your name and location', () {}),
            _buildMenuTile(Icons.support_agent_outlined, 'Help & Support', 'Get help with a rental', () {}),

            const SizedBox(height: 40),

            // --- LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ) ?? false;

                  if (confirm) {
                    await FirebaseAuth.instance.signOut();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // 🛠️ Helper widget to create clean, consistent menu rows
  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2C3E50)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}