import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _uploadingRentalId;

  // 📸 1. UPLOAD LOGIC (No auto-declining yet! Let them race to pay.)
  Future<void> _takeLivePhotoAndApprove(String rentalId, String toolId, String toolName) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (photo == null) return;

      setState(() => _uploadingRentalId = rentalId);

      // 1. Upload to Storage
      File imageFile = File(photo.path);
      String fileName = 'live_photos/${DateTime.now().millisecondsSinceEpoch}_$rentalId.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(imageFile);
      String downloadUrl = await ref.getDownloadURL();

      // 2. Just update this specific user's ticket so they can pay!
      // Notice we are NOT hiding the tool or declining others anymore.
      await FirebaseFirestore.instance.collection('rentals').doc(rentalId).update({
        'liveImageUrl': downloadUrl,
        'status': 'pending_payment',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo sent! Waiting for them to pay fast."), backgroundColor: Colors.green),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _uploadingRentalId = null);
    }
  }

  // 🛑 2. DECLINE LOGIC (For duplicates or unwanted requests)
  Future<void> _declineRequest(String rentalId) async {
    try {
      await FirebaseFirestore.instance.collection('rentals').doc(rentalId).update({
        'status': 'declined',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request declined."), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please log in.")));

    return Scaffold(
      appBar: AppBar(title: const Text('My Incoming Requests', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rentals')
            .where('lenderId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'pending_verification') // Only show fresh requests
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("No pending requests right now.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index].data() as Map<String, dynamic>;
              String rentalId = requests[index].id;
              String toolId = request['toolId']; // 🛠️ Grab the tool ID

              DateTime startDate = (request['startDate'] as Timestamp).toDate();
              int days = request['days'] ?? 1;
              double amount = (request['totalAmount'] ?? 0).toDouble();

              bool isUploading = _uploadingRentalId == rentalId;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(request['toolName'] ?? 'Tool', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                            child: const Text("Action Required", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                      const Divider(height: 24),
                      Row(children: [const Icon(Icons.calendar_today, size: 16, color: Colors.grey), const SizedBox(width: 8), Text("Starts: ${DateFormat('MMM dd, yyyy').format(startDate)}") ]),
                      const SizedBox(height: 8),
                      Row(children: [const Icon(Icons.timer, size: 16, color: Colors.grey), const SizedBox(width: 8), Text("Duration: $days Days") ]),
                      const SizedBox(height: 8),
                      Row(children: [const Icon(Icons.payments, size: 16, color: Colors.green), const SizedBox(width: 8), Text("You Earn: ₹${amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)) ]),
                      const SizedBox(height: 20),

                      // 🔘 ACTION BUTTONS
                      Row(
                        children: [
                          // 🛑 Decline Button
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: isUploading ? null : () => _declineRequest(rentalId),
                              child: const Text("Decline"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // ✅ Accept & Photo Button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8C00),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: isUploading ? null : () => _takeLivePhotoAndApprove(rentalId, toolId, request['toolName']),
                              icon: isUploading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              label: Text(
                                  isUploading ? "Uploading..." : "Send Photo",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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