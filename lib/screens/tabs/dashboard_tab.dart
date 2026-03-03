import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';

class DashboardTab extends StatefulWidget {
  final VoidCallback goToSchedule;
  final VoidCallback goToTasks;

  const DashboardTab({
    super.key,
    required this.goToSchedule,
    required this.goToTasks,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  static const Color _cardColor = Color(0xFFE4B8AC);
  static const Color _btnSoft = Color(0xFFC27C86);

  static const _quotes = [
    "SMALL STEPS, BIG\nPROGRESS",
    "DO IT NOW,\nBE PROUD LATER",
    "ONE TASK\nAT A TIME",
    "FOCUS\nAND FINISH",
    "CONSISTENCY\nWINS",
    "YOU'VE GOT\nTHIS",
  ];

  late String _quote;

  @override
  void initState() {
    super.initState();
    _quote = _quotes[Random().nextInt(_quotes.length)];
  }

  String _weekdayName(int w) {
    const names = [
      'Monday','Tuesday','Wednesday',
      'Thursday','Friday','Saturday','Sunday'
    ];
    return names[w - 1];
  }

  String _monthName(int m) {
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        (user?.email ?? "Student").split('@').first;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.bgTop, AppTheme.bgBottom],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          children: [

            // ✅ Welcome + Date Card
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _btnSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, $displayName",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_weekdayName(now.weekday)}, ${_monthName(now.month)}",
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8A79A),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${now.day}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quote Card
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF9B858C),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _quote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Schedule Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: AppTheme.dark, width: 2),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Schedule",
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "No schedule yet.",
                    style: TextStyle(
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _softButton(
                      "Add", widget.goToSchedule),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tasks Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: AppTheme.dark, width: 2),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tasks",
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "No tasks yet.",
                    style: TextStyle(
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _softButton(
                      "Add", widget.goToTasks),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _softButton(
      String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _btnSoft,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}