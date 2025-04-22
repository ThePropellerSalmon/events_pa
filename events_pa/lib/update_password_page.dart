import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkIfSignedIn();
  }

  Future<void> _checkIfSignedIn() async {
    final session = Supabase.instance.client.auth.currentSession;

    setState(() {
      _isSignedIn = session != null;
    });

    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to update your password.')),
      );
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your password has been updated!')),
      );

      Navigator.pop(context); // Or navigate to login screen
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSignedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
