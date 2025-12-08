import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAdmin = false; // Toggle state
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Role Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Student'),
                  Switch(
                    value: _isAdmin,
                    onChanged: (value) {
                      setState(() {
                        _isAdmin = value;
                        _emailController.clear();
                        _passwordController.clear();
                      });
                    },
                  ),
                  const Text('Admin'),
                ],
              ),
              const SizedBox(height: 20),

              // Conditional Fields
              if (_isAdmin)
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter an email' : null,
                )
              else
                TextFormField(
                  controller:
                      _emailController, // We'll reuse this controller for Student ID for simplicity, or create a new one
                  decoration: const InputDecoration(labelText: 'Student ID'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter Student ID' : null,
                ),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? 'Password must be 6+ chars' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          final authService = Provider.of<AuthService>(
                            context,
                            listen: false,
                          );
                          String? error;

                          if (_isAdmin) {
                            error = await authService.loginAdmin(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                          } else {
                            // Note: For Student, _emailController holds the Student ID
                            error = await authService.loginStudent(
                              studentId: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                          }

                          setState(() => _isLoading = false);
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        }
                      },
                      child: Text(
                        _isAdmin ? 'Login as Admin' : 'Login as Student',
                      ),
                    ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                child: const Text('Create an Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
