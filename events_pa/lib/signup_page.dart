import 'dart:async';

import 'package:events_pa/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Error messages
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  final emailRegex = RegExp(r"^(?!.*\.\.)[a-zA-Z0-9][a-zA-Z0-9._%+-]{0,63}@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

  // Function to check if the password is strong
  bool _isStrongPassword(String password) {
    final strongPasswordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return strongPasswordRegex.hasMatch(password);
  }

  Future<bool> _isEmailAlreadyRegistered(String email) async {
    final supabase = Supabase.instance.client;
    final users = await supabase.from('users').select();
    final data = await supabase.from('users').select('email').eq('email', email.trim().toLowerCase());

    var emailExist = false;

    if (data.isNotEmpty) {
      emailExist = true;
    }

    return emailExist; // Return true if the email is found
  }

  // Validation function
  bool _validateFields() {
    setState(() {
      _firstNameError = _firstNameController.text.isEmpty ? "First Name is required" : null;
      _lastNameError = _lastNameController.text.isEmpty ? "Last Name is required" : null;
      _emailError = !emailRegex.hasMatch(_emailController.text) ? "Enter a valid email address" : null;

      // Check if email already exists in the database
      if (_emailError == null) {
        _isEmailAlreadyRegistered(_emailController.text).then((isRegistered) {
          setState(() {
            if (isRegistered) {
              _emailError = "This email is already registered";
            }
          });
        });
      }

      _passwordError =
          _passwordController.text.isEmpty
              ? "Password is required"
              : !_isStrongPassword(_passwordController.text)
              ? "Password must be at least 8 characters, contain an uppercase letter, a lowercase letter, a number, and a special character."
              : null;
      _confirmPasswordError =
          _confirmPasswordController.text.isEmpty
              ? "Please confirm your password"
              : _confirmPasswordController.text != _passwordController.text
              ? "Passwords do not match"
              : null;
    });

    return _firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  // Create account function
  Future<void> _signUp() async {
    if (!_validateFields()) return; // Stop if validation fails

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        emailRedirectTo: '${supabaseAuthCallback}account/',
      );

      if (response.user == null) {
        setState(() {
          _isLoading = false;
        });
        context.showSnackBar('There was an issue with the sign-up');
        return;
      }

      // Insert user details into the database
      await Supabase.instance.client.from('users').insert({
        'userId': response.user!.id, // Assuming your table has a UUID column for user ID
        'accountCreationDate': DateTime.now().toIso8601String(),
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text.trim().toLowerCase(),
        'hasSubscriptionPlan': false,
        'hasPriorityPlan': false,
        'roleId': 1,
      });

      setState(() {
        _isLoading = false;
      });

      context.showSnackBar('Check your email for a login link!');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      context.showSnackBar('Error: $error');
      print('$error');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name', errorText: _firstNameError),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name', errorText: _lastNameError),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email', errorText: _emailError),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password', errorText: _passwordError),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm Password', errorText: _confirmPasswordError),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
