import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'tabs/dashboard_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/gpa_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0; // Home أول

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(
        goToTasks: () => setState(() => _index = 1),
        goToSchedule: () => setState(() => _index = 2),
      ),
      const TasksTab(),
      const ScheduleTab(),
      const GpaTab(),
      const NotesTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2B8A8),
            borderRadius: BorderRadius.circular(22),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.dark,
            unselectedItemColor: AppTheme.dark.withOpacity(0.65),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Tasks'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
              BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined), label: 'GPA'),
              BottomNavigationBarItem(icon: Icon(Icons.notes_outlined), label: 'Notes'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}