import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const StudentMateApp());
}

class StudentMateApp extends StatelessWidget {
  const StudentMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final user = authSnap.data;

        if (user == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Student Mate',
            theme: AppTheme.lightTheme(),
            home: const LoginScreen(),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Student Mate',
          theme: AppTheme.lightTheme(),
          home: const HomeScreen(),
        );
      },
    );
  }
}