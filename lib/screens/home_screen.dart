import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';

import 'tabs/dashboard_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/gpa_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _goToSchedule() => setState(() => _index = 2);
  void _goToTasks() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ✅ تاباتك (نهائية)
    final tabs = <Widget>[
      DashboardTab(goToSchedule: _goToSchedule, goToTasks: _goToTasks),
      const TasksTab(),
      const ScheduleTab(),
      const NotesTab(),
      const GpaTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
          ),
        ),
        child: SafeArea(
          child: user == null
              ? const Center(
                  child: Text(
                    "Login required",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                )
              : tabs[_index],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border(top: BorderSide(color: AppTheme.dark, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.dark,
          unselectedItemColor: AppTheme.dark.withOpacity(0.55),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: "Tasks"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Schedule"),
            BottomNavigationBarItem(icon: Icon(Icons.note_alt_outlined), label: "Notes"),
            BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined), label: "GPA"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
          ],
        ),
      ),
    );
  }
}