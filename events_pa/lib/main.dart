// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_page.dart';
import 'forgot_password_page.dart';
// Pages
import 'login_page.dart';
import 'signup_page.dart';
import 'update_password_page.dart'; // Add this if not already

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const String supabaseAuthCallback = 'com.eventspa.app://login-callback/';
const String supabaseUrl = 'https://eclzdvaxrevuktnfrbkq.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjbHpkdmF4cmV2dWt0bmZyYmtxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3NzUyNDgsImV4cCI6MjA1ODM1MTI0OH0.pH3_ThyRKgu-qfTwwukHTc5EiyWjyW-eD60OhHmNZN0';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  runApp(const MainApp());
}

GoRouter _router(Listenable refreshListenable) => GoRouter(
  initialLocation: '/account',
  debugLogDiagnostics: true,
  refreshListenable: refreshListenable,
  navigatorKey: navigatorKey,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final publicRoutes = ['/login', '/signup', '/forgot-password'];
    debugPrint('Current Path: ${state.fullPath}');
    debugPrint('Matched Path: ${state.matchedLocation}');
    if (session == null && !publicRoutes.contains(state.fullPath)) {
      return '/login';
    } else {
      debugPrint('User is allowed to continue to ${state.matchedLocation}');
      return null;
    }
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => SignupPage()),
    GoRoute(path: '/forgot-password', builder: (context, state) => ForgotPasswordPage()),
    GoRoute(path: '/update-password', builder: (context, state) => UpdatePasswordPage()),
    GoRoute(path: '/account', builder: (context, state) => AccountPage()),
  ],
);

// class MainApp extends StatelessWidget {
//   const MainApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(routerConfig: _router);
//   }
// }

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AuthStateListenable _authStateListenable;

  @override
  void initState() {
    super.initState();
    _authStateListenable = AuthStateListenable(context, Supabase.instance.client.auth.onAuthStateChange);
  }

  @override
  void dispose() {
    _authStateListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router(_authStateListenable));
  }
}

class AuthStateListenable extends ChangeNotifier {
  final BuildContext context;
  StreamSubscription? _subscription;
  AuthState? _latestValue;
  AuthState? get value => _latestValue;

  AuthStateListenable(this.context, Stream<AuthState> stream) {
    _subscription = stream.listen(
      (data) async {
        debugPrint('AuthChangeEvent: ${data.event.name}');
        final route = getRoute(data.event);
        if (route != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => navigatorKey.currentContext?.go(route));
        }
        _latestValue = data;
        notifyListeners();
      },
      onError: (error) {
        if (error is AuthException) {
          context.showSnackBar('Error: $error');
        } else {
          context.showSnackBar('Unexpected error occurred');
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

String? getRoute(AuthChangeEvent event) {
  switch (event) {
    case AuthChangeEvent.signedIn:
      return '/account';
    case AuthChangeEvent.passwordRecovery:
      return '/update-password';
    case AuthChangeEvent.signedOut:
      return '/login';
    default:
      return null;
  }
}

extension BuildContextX on BuildContext {
  GoRouter get goRouter => GoRouter.of(this);
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
