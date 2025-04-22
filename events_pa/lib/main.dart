import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pages
import 'auth_page.dart';
import 'signup_page.dart';
import 'reset_password_temp_page.dart';
import 'account_page.dart';
import 'forgot_password_page.dart';
import 'update_password_page.dart'; // Add this if not already

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://eclzdvaxrevuktnfrbkq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjbHpkdmF4cmV2dWt0bmZyYmtxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3NzUyNDgsImV4cCI6MjA1ODM1MTI0OH0.pH3_ThyRKgu-qfTwwukHTc5EiyWjyW-eD60OhHmNZN0',
  );

  // Listen for deep link password recovery
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    if (event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.pushNamed('/update-password');
    }
  });

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // important for deep link nav
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const AuthPage());
          case '/signup':
            return MaterialPageRoute(builder: (context) => const SignupPage());
          case '/reset-password-temp':
            return MaterialPageRoute(builder: (context) => const ResetPasswordTempPage());
          case '/account':
            return MaterialPageRoute(builder: (context) => const AccountPage());
          case '/forgot-password':
            return MaterialPageRoute(builder: (context) => const ForgotPasswordPage());
          case '/update-password':
            return MaterialPageRoute(builder: (context) => const UpdatePasswordPage());
          default:
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Page not found')),
              ),
            );
        }
      },
    );
  }
}
