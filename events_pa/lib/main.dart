import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'signup_page.dart';
import 'reset_password_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Initialize Supabase
  await Supabase.initialize(
    url: 'https://eclzdvaxrevuktnfrbkq.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjbHpkdmF4cmV2dWt0bmZyYmtxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3NzUyNDgsImV4cCI6MjA1ODM1MTI0OH0.pH3_ThyRKgu-qfTwwukHTc5EiyWjyW-eD60OhHmNZN0',
  );
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthPage(),
        '/signup': (context) => const SignupPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        // Add other routes as needed
      },
    );
  }
}