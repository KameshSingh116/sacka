import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../root/root_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const LoginScreen({super.key, required this.onToggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool rememberMe = true;
  bool loading = false;
  String error = '';

  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _anim,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      'SACKA',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: email,
                      decoration:
                      const InputDecoration(labelText: 'Email'),
                      validator: (v) =>
                      v != null && v.contains('@')
                          ? null
                          : 'Enter valid email',
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

                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (v) {
                            setState(() => rememberMe = v!);
                          },
                        ),
                        const Text('Remember me'),
                      ],
                    ),

                    if (error.isNotEmpty)
                      Text(error,
                          style:
                          const TextStyle(color: Colors.red)),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                        if (!_formKey.currentState!
                            .validate()) return;

                        setState(() {
                          loading = true;
                          error = '';
                        });

                        final success =
                        await AuthService.login(
                          email.text,
                          password.text,
                          rememberMe,
                        );

                        setState(() => loading = false);

                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RootScreen(
                                onToggleTheme:
                                widget.onToggleTheme,
                              ),
                            ),
                          );
                        } else {
                          setState(() =>
                          error = 'Wrong credentials');
                        }
                      },
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(
                              onToggleTheme:
                              widget.onToggleTheme,
                            ),
                          ),
                        );
                      },
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
