import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class RegisterPhoneScreen extends StatefulWidget {
  final String userName;
  final String email;     // <--- NEW
  final String password;  // <--- NEW

  const RegisterPhoneScreen({
    super.key,
    required this.userName,
    required this.email,
    required this.password,
  });

  @override
  State<RegisterPhoneScreen> createState() => _RegisterPhoneScreenState();
}

class _RegisterPhoneScreenState extends State<RegisterPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _verifyPhoneNumber() async {
    String phone = _phoneController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid 10-digit number"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    String fullPhoneNumber = "+91$phone";

    try {
      // 1. SMART CHECK: Does phone exist?
      var userQuery = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: fullPhoneNumber).get();

      if (userQuery.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showLoginDialog("This phone number is already registered. Please login instead.");
        return;
      }

      // 2. If new, Send OTP
      _authService.sendOtp(
        phoneNumber: fullPhoneNumber,
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() => _isLoading = false);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                verificationId: verificationId,
                phoneNumber: fullPhoneNumber,
                isLoginFlow: false,
                userName: widget.userName,
                email: widget.email,       // <--- Pass to OTP Screen
                password: widget.password, // <--- Pass to OTP Screen
              ),
            ),
          );
        },
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification Failed: ${error.message}"), backgroundColor: Colors.red));
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _showLoginDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Number Registered"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Go to Login", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Phone"), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.phone_android_rounded, size: 80, color: Color(0xFF2C3E50)),
            const SizedBox(height: 20),

            Text(
              "Hi ${widget.userName.split(' ')[0]},",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Step 2: Link your mobile number to secure your account.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
              decoration: const InputDecoration(labelText: "Phone Number", prefixText: "+91  ", prefixStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyPhoneNumber,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00), foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Get OTP", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}