import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

class ResetPasswordTempPage extends StatefulWidget {
  const ResetPasswordTempPage({Key? key}) : super(key: key);

  @override
  State<ResetPasswordTempPage> createState() => _ResetPasswordTempPageState();
}

class _ResetPasswordTempPageState extends State<ResetPasswordTempPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _emailSent = false;
  bool _showResetForm = false;
  String? _resetCode;
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinkHandling();
  }

  Future<void> _initDeepLinkHandling() async {
    // Initial app link
    final initialUri = await _appLinks.getInitialAppLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Listen for new links
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      print('Error receiving URI: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'events_pa' && uri.host == 'reset-password') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        setState(() {
          _showResetForm = true;
          _resetCode = code;
        });
      }
    }
  }

  Future<void> _sendResetEmail() async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'https://thepropellersalmon.github.io/events_pa/reset-password.html',
      );

      setState(() {
        _emailSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _submitNewPassword() async {
    final newPassword = _passwordController.text.trim();
    if (_resetCode != null && newPassword.isNotEmpty) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );

        Navigator.pushReplacementNamed(context, '/login');
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _showResetForm
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Enter your new password below:'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitNewPassword,
                    child: const Text('Reset Password'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendResetEmail,
                    child: const Text('Send Password Reset Link'),
                  ),
                  if (_emailSent)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        'Check your email and click the reset link to continue.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
