import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------
  // 1. EMAIL & PASSWORD AUTHENTICATION
  // ---------------------------------------------------------

  // Sign Up with Email
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception("This email is already registered. Please login.");
      }
      throw Exception(e.message ?? "Sign up failed.");
    }
  }

  // Login with Email
  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Pass the exact Firebase error code back to the screen
      if (e.code == 'user-not-found') {
        throw Exception("user-not-found");
      } else if (e.code == 'wrong-password') {
        throw Exception("wrong-password");
      } else if (e.code == 'invalid-email') {
        throw Exception("invalid-email");
      } else if (e.code == 'invalid-credential') {
        throw Exception("invalid-credential"); // Fallback if Firebase security is blocking us
      }
      throw Exception(e.message ?? "Login failed.");
    }
  }

  // Forgot Password (Sends Reset Email)
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Could not send reset email.");
    }
  }

  // ---------------------------------------------------------
  // 2. PHONE AUTHENTICATION (Existing Logic)
  // ---------------------------------------------------------

  void sendOtp({
    required String phoneNumber,
    required Function(String, int?) codeSent,
    required Function(FirebaseAuthException) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-resolution (Android only)
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Log Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}