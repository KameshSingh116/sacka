import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; // <-- REQUIRED: Needed for generating random codes

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔑 THE MISSING FUNCTION: Generates a random 6-character code (e.g., A8F9B2)
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Save User Profile (MVP with Map Pin & Status)
  Future<void> saveUserProfile({
    required String name,
    required String tower,
    required String flatNo,
    required double latitude,
    required double longitude,
    required String status, // 'verified' or 'guest'
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in!");

    // Generate their personal code for the Web of Trust (for later!)
    String myPersonalCode = _generateInviteCode();

    Map<String, dynamic> userData = {
      'uid': user.uid,
      'phone': user.phoneNumber,
      'name': name,
      'tower': tower,
      'flatNo': flatNo,
      'location': GeoPoint(latitude, longitude),
      'myInviteCode': myPersonalCode, // Saves the generated code
      'trustScore': 10, // Everyone starts with 10 Trust Points
      'status': status, // 'verified' or 'guest'
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(user.uid).set(userData);
  }

  // Check if user already exists
  Future<bool> checkUserExists() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
    return doc.exists;
  }
}