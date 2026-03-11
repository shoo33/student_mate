import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart' as theme;
import '../app_text.dart';
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

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('app');

  @override
  void initState() {
    super.initState();
    _tabs = [
      DashboardTab(
        goToTasks: () => setState(() => _i = 1),
        goToSchedule: () => setState(() => _i = 2),
      ),
      const TasksTab(),
      ScheduleTab(),
      const NotesTab(),
      const GpaTab(),
      const ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.AppTheme.isDark(context);

    final pageBg = theme.AppTheme.pageBottom(context);
    final navBg =
        isDark ? theme.AppTheme.softCardColor(context) : const Color(0xFFF2B8A8);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : theme.AppTheme.dark;

    final selectedColor = isDark ? Colors.white : theme.AppTheme.dark;
    final unselectedColor =
        isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black87;

    final splashColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.10);

    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.06);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _settingsDoc.snapshots(),
      builder: (context, snap) {
        final settings = snap.data?.data() ?? {};
        final text = AppText((settings['languageCode'] ?? 'en').toString());

        return Scaffold(
          backgroundColor: pageBg,
          body: _tabs[_i],
          bottomNavigationBar: Container(
            color: pageBg,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Material(
                  color: navBg,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavItem(
                          icon: Icons.home_outlined,
                          label: text.home,
                          selected: _i == 0,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          splashColor: splashColor,
                          highlightColor: highlightColor,
                          onTap: () => setState(() => _i = 0),
                        ),
                        _NavItem(
                          icon: Icons.check_circle_outline,
                          label: text.tasks,
                          selected: _i == 1,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          splashColor: splashColor,
                          highlightColor: highlightColor,
                          onTap: () => setState(() => _i = 1),
                        ),
                        _NavItem(
                          icon: Icons.calendar_month_outlined,
                          label: text.schedule,
                          selected: _i == 2,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          splashColor: splashColor,
                          highlightColor: highlightColor,
                          onTap: () => setState(() => _i = 2),
                        ),
                        _NavItem(
                          icon: Icons.note_outlined,
                          label: text.notes,
                          selected: _i == 3,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          splashColor: splashColor,
                          highlightColor: highlightColor,
                          onTap: () => setState(() => _i = 3),
                        ),
                        _NavItem(
                          icon: Icons.calculate_outlined,
                          label: text.gpa,
                          selected: _i == 4,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          splashColor: splashColor,
                          highlightColor: highlightColor,
                          onTap: () => setState(() => _i = 4),
                        ),
                        _NavItem(
                          icon: Icons.person_outline,
                          label: text.profile,
                          selected: _i == 5,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          splashColor: splashColor,
                          highlightColor: highlightColor,
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
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color splashColor;
  final Color highlightColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.splashColor,
    required this.highlightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: splashColor,
        highlightColor: highlightColor,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? selectedColor : unselectedColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? selectedColor : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}