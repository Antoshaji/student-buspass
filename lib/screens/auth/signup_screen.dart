import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentIdController = TextEditingController();
  bool _isAdmin = false; // Toggle state
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                        });
                      },
                    ),
                    const Text('Admin'),
                  ],
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your name' : null,
                ),

                // Student ID Field (Only for Students)
                if (!_isAdmin)
                  TextFormField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(labelText: 'Student ID'),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter Student ID' : null,
                  ),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter an email' : null,
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
                            String? error = await authService.signUp(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              name: _nameController.text.trim(),
                              role: _isAdmin ? 'admin' : 'student',
                              studentId: _isAdmin
                                  ? null
                                  : _studentIdController.text.trim(),
                            );
                            setState(() => _isLoading = false);
                            if (error != null) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(error)));
                            } else {
                              Navigator.pop(context); // Go back to Login
                            }
                          }
                        },
                        child: Text(
                          _isAdmin ? 'Signup as Admin' : 'Signup as Student',
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
