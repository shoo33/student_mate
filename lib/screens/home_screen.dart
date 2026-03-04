import 'package:flutter/material.dart';

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
  int _tab = 0;

  void _goToSchedule() => setState(() => _tab = 2);
  void _goToTasks() => setState(() => _tab = 1);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(goToSchedule: _goToSchedule, goToTasks: _goToTasks),
      const TasksTab(),
      const ScheduleTab(),
      const NotesTab(),
      const GpaTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: "Notes"),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "GPA"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}