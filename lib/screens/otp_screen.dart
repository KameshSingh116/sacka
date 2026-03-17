import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'create_profile_screen.dart';
import 'root_screen.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final bool isLoginFlow;
  final String? userName;
  final String? email;
  final String? password;

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.isLoginFlow,
    this.userName,
    this.email,
    this.password,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  void _verifyOTP() async {
    String otp = _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid 6-digit OTP")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Verify the OTP code first
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      if (widget.isLoginFlow) {
        // --- PATH A: LOGGING IN ---
        await _auth.signInWithCredential(credential);

        if (!mounted) return;

        // 🛠️ FIX: Explicitly target the absolute base route ('/') of the app!
        RootScreen.tabNotifier.value = 0;
        Navigator.popUntil(context, ModalRoute.withName('/'));
      } else {
        // --- PATH B: NEW REGISTRATION ---

        // Step 1: CREATE the Email/Password account NOW that phone is verified
        UserCredential userCred = await _auth.createUserWithEmailAndPassword(
          email: widget.email!,
          password: widget.password!,
        );

        // Step 2: LINK the verified phone number to this new account
        await userCred.user!.linkWithCredential(credential);

        // Step 3: Send them to Profile Screen to save Name and Location!
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateProfileScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = "Authentication Failed.";
      if (e.code == 'invalid-verification-code')
        message = "The code you entered is incorrect.";
      if (e.code == 'credential-already-in-use')
        message = "This phone is linked to another account.";
      if (e.code == 'email-already-in-use')
        message = "This email is already registered. Please go back to login.";

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP"), elevation: 0),
      // 🛠️ FIX: Center + SingleChildScrollView replaces the Padding wrapper
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // 🛠️ Centers items vertically
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                  Icons.message_rounded, size: 80, color: Color(0xFF2C3E50)),
              const SizedBox(height: 20),
              Text(
                "Enter Verification Code",
                textAlign: TextAlign.center,
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Sent to ${widget.phoneNumber}", textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(counterText: "",
                    border: OutlineInputBorder(),
                    hintText: "000000"),
              ),
              const SizedBox(height: 30),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator(
                      color: Colors.white) : const Text(
                      "Verify & Continue", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40), // 🛠️ Safety buffer for the keyboard
            ],
          ),
        ),
      ),
    );
  }
}