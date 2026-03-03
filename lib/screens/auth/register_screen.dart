import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const RegisterScreen({super.key, required this.onToggleTheme});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  String error = '';

  @override
  Widget build(BuildContext context) {
    final orange = Colors.deepOrange;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  orange.withOpacity(0.25),
                  orange.withOpacity(0.08),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: orange.withOpacity(0.4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: email,
                    decoration:
                    const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                    v != null && v.contains('@')
                        ? null
                        : 'Invalid email',
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration:
                    const InputDecoration(labelText: 'Password'),
                    validator: (v) =>
                    v != null && v.length >= 6
                        ? null
                        : 'Min 6 characters',
                  ),

                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        error,
                        style:
                        const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate())
                        return;

                      final result =
                      await AuthService.register(
                        email.text,
                        password.text,
                      );

                      if (result != null) {
                        setState(() => error = result);
                        return;
                      }

                      Navigator.pop(context); // back to login
                    },
                    child: const Text('Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
