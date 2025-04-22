import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to your account!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate back to the authentication page
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
