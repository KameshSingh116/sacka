import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save User Profile & Location
  Future<void> saveUserProfile({
    required String name,
    required String tower,
    required String flatNo,
    required double latitude,
    required double longitude,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in!");

    // Create a neat package of data
    Map<String, dynamic> userData = {
      'uid': user.uid,
      'phone': user.phoneNumber,
      'name': name,
      'tower': tower,
      'flatNo': flatNo,
      'location': GeoPoint(latitude, longitude), // Firestore's special location format
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Save to the 'users' collection
    await _db.collection('users').doc(user.uid).set(userData);
  }

  // Check if user already exists (We will use this later)
  Future<bool> checkUserExists() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
    return doc.exists;
  }
}