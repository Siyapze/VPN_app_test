import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Authentication wrapper that determines which screen to show
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1565C0),
              ),
            ),
          );
        }

        // Show home screen if user is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // Show login screen if user is not authenticated
        return const LoginScreen();
      },
    );
  }
}
