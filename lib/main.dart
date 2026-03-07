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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Mate',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.rose,
          primary: AppTheme.rose,
          surface: AppTheme.bgBottom,
        ),

        scaffoldBackgroundColor: AppTheme.bgBottom,

        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppTheme.bgBottom,
          hourMinuteTextColor: AppTheme.dark,
          hourMinuteColor: AppTheme.beigeBtn,
          dayPeriodTextColor: AppTheme.dark,
          dayPeriodColor: AppTheme.beigeBtn,
          dayPeriodBorderSide: BorderSide(color: AppTheme.dark.withValues(alpha: 0.25)),
          dialBackgroundColor: AppTheme.beigeBtn.withValues(alpha: 0.45),
          dialHandColor: AppTheme.dark,
          entryModeIconColor: AppTheme.dark,
          helpTextStyle: TextStyle(
            color: AppTheme.dark,
            fontWeight: FontWeight.w900,
          ),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: AppTheme.dark,
          ),
          cancelButtonStyle: TextButton.styleFrom(
            foregroundColor: AppTheme.dark,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),

        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppTheme.bgBottom,
          headerBackgroundColor: AppTheme.rose,
          headerForegroundColor: Colors.white,
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppTheme.dark;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppTheme.rose;
            return null;
          }),
          todayForegroundColor: WidgetStatePropertyAll(AppTheme.rose),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),

        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFFF1ECF3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          labelStyle: TextStyle(
            color: AppTheme.dark.withValues(alpha: 0.75),
            fontWeight: FontWeight.w800,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.dark.withValues(alpha: 0.35)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.dark, width: 2),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}