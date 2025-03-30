import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Reset password function
  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt to reset the password
      await Supabase.instance.client.auth.resetPasswordForEmail(_emailController.text);

      setState(() {
        _isLoading = false;
      });

      // Success: password reset link sent
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("The password reset link has been sent to your email")),
      );
      Navigator.pop(context);
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      // Catch and handle errors (e.g., invalid email or other errors)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Password Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}
