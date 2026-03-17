import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'root_screen.dart';

class RentalHistoryScreen extends StatelessWidget {
  const RentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // 🛑 If the user somehow gets here without logging in, block them safely
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rental History')),
        body: const Center(child: Text("Please log in to view your history.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental History'),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      // 📡 StreamBuilder listens to the actual Firestore database!
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rentals')
            .where('borrowerId', isEqualTo: currentUser.uid) // Only show THEIR rentals
            .orderBy('createdAt', descending: true) // Newest first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)));
          }

          if (snapshot.hasError) {
            // Because we added an 'orderBy' with a 'where', Firebase might require an Index.
            // If it crashes, check your debug console for a Firebase link to build the index!
            return const Center(child: Text('Something went wrong. Please try again later.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    "You haven't rented any tools yet!",
                    style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
              // 🛠️ ADDED: A button to guide them back to the Home Screen!
                   ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFFFF8C00),
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),),
                   onPressed: () {
                     RootScreen.tabNotifier.value = 0;
                  // This pops the current screen and takes them back to the main tabs!
                     Navigator.popUntil(context, ModalRoute.withName('/'));

                   },
                  icon: const Icon(Icons.search, color: Colors.white),
                     label: const Text(
                    "Browse Tools to Rent",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
                   ),
                ],
              ),
            );
          }

          final rentals = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rentals.length,
            itemBuilder: (context, index) {
              final rental = rentals[index].data() as Map<String, dynamic>;
              final isActive = rental['status'] == 'Active';

              // 📅 Format the Firestore Timestamp into a readable date string
              String dateStr = 'Unknown Date';
              if (rental['createdAt'] != null) {
                DateTime dt = (rental['createdAt'] as Timestamp).toDate();
                dateStr = "${dt.day}/${dt.month}/${dt.year}"; // e.g., 25/10/2023
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFFF8C00).withOpacity(0.1)
                          : const Color(0xFFF5F7FA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.handyman, // You can make this dynamic later based on category
                      color: isActive ? const Color(0xFFFF8C00) : const Color(0xFF2C3E50),
                    ),
                  ),
                  title: Text(
                    rental['toolName'] ?? 'Unknown Tool',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(dateStr, style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(width: 16),
                        Icon(Icons.payments_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('₹${rental['totalCost'] ?? 0}', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rental['status'] ?? 'Completed',
                      style: TextStyle(
                        color: isActive ? Colors.green[700] : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}