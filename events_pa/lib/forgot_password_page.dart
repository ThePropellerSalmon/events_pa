import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // This will listen for the deep link triggered from the password reset email
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('AuthChangeEvent: $event');
      
      if (session != null) {
        print('Session Access Token: ${session.accessToken}');
        print('Session Refresh Token: ${session.refreshToken}');
      } else {
        print('No session found');
      }

      if (event == AuthChangeEvent.passwordRecovery) {
        print('Password recovery event triggered');
        // Navigate to the password update screen
        Navigator.of(context).pushNamed('/update-password');
      }
    });
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.events_pa://update-password/', // Your custom scheme
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your email to receive a reset link',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendResetEmail,
              child: const Text('Send Reset Email'),
            ),
          ],
        ),
      ),
    );
  }
}
