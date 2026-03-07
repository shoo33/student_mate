import 'package:flutter/material.dart';

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
  int _i = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      DashboardTab(
        goToTasks: () => setState(() => _i = 1),
        goToSchedule: () => setState(() => _i = 2),
      ),
      const TasksTab(),
      const ScheduleTab(),
      const NotesTab(),
      const GpaTab(),
      const ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBottom,
      body: _tabs[_i],
      bottomNavigationBar: Container(
        color: AppTheme.bgBottom,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Material(
              color: const Color(0xFFF2B8A8),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.dark, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      label: "Home",
                      selected: _i == 0,
                      onTap: () => setState(() => _i = 0),
                    ),
                    _NavItem(
                      icon: Icons.check_circle_outline,
                      label: "Tasks",
                      selected: _i == 1,
                      onTap: () => setState(() => _i = 1),
                    ),
                    _NavItem(
                      icon: Icons.calendar_month_outlined,
                      label: "Schedule",
                      selected: _i == 2,
                      onTap: () => setState(() => _i = 2),
                    ),
                    _NavItem(
                      icon: Icons.note_outlined,
                      label: "Notes",
                      selected: _i == 3,
                      onTap: () => setState(() => _i = 3),
                    ),
                    _NavItem(
                      icon: Icons.calculate_outlined,
                      label: "GPA",
                      selected: _i == 4,
                      onTap: () => setState(() => _i = 4),
                    ),
                    _NavItem(
                      icon: Icons.person_outline,
                      label: "Profile",
                      selected: _i == 5,
                      onTap: () => setState(() => _i = 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.black.withValues(alpha: 0.10),
        highlightColor: Colors.black.withValues(alpha: 0.06),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppTheme.dark : Colors.black87,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppTheme.dark : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}