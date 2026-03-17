import 'package:flutter/material.dart';
import 'register_phone_screen.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  void _goToNextStep() {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) return;

    // 2. Do NOT create the account yet! Just pass the data forward.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPhoneScreen(
          userName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add_alt_1_rounded, size: 80, color: Color(0xFF2C3E50)),
              const SizedBox(height: 20),

              Text(
                "Join ShaCa",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Step 1: Setup your credentials", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Please enter your name" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                validator: (val) {
                  if (val!.isEmpty) return "Please enter your email";
                  if (!val.contains("@")) return "Please enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Create Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (val) {
                  if (val!.isEmpty) return "Please enter a password";
                  if (val.length < 6) return "Password must be at least 6 characters";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _goToNextStep,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00), foregroundColor: Colors.white),
                  child: const Text("Next: Verify Phone", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}