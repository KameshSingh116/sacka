import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../root/root_screen.dart';

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
  bool rememberMe = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                    : 'Min 6 chars',
              ),

              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (v) {
                      setState(() => rememberMe = v!);
                    },
                  ),
                  const Text('Stay logged in'),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate())
                    return;

                  await AuthService.register(
                    email.text,
                    password.text,
                    rememberMe,
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RootScreen(
                        onToggleTheme:
                        widget.onToggleTheme,
                      ),
                    ),
                  );
                },
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
