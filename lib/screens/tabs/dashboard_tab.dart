import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');

  CollectionReference<Map<String, dynamic>> get _scheduleRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('schedules');

  static const Color _cardColor = Color(0xFFE4B8AC);
  static const Color _btnSoft = Color(0xFFC27C86);
  static const Color _tableHeader = Color(0xFFD9A99C);

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
    const names = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return names[w - 1];
  }

  String _monthName(int m) {
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return names[m - 1];
  }

  String _dayShort(int weekday) {
    const names = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return names[(weekday - 1).clamp(0, 6)];
  }

  String _fmtMin(int mins) {
    int h = mins ~/ 60;
    final m = (mins % 60).toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$m$ampm';
  }

  String _fmtDT(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final day = d.day.toString().padLeft(2, '0');
    final mon = months[d.month - 1];

    int h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    h = h % 12;
    if (h == 0) h = 12;

    return "$day $mon • $h:$m$ampm";
  }

  Widget _pillButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _btnSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _setTaskDone(String id, bool v) async {
    await _tasksRef.doc(id).update({
      'done': v,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
          children: [
            // ===== Header: Date + Welcome =====
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userDoc.snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data();
                final name = (data?['name'] ?? '').toString().trim();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB97E87),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${_weekdayName(now.weekday)}, ${_monthName(now.month)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            if (name.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Welcome, $name",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ],
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
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ===== Quote =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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

            const SizedBox(height: 12),

            // ===== Weekly classes (TABLE) =====
            // ===== Weekly classes (REAL WEEK TABLE) =====
StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: _scheduleRef.where('type', isEqualTo: 'weekly').snapshots(),
  builder: (context, snapshot) {
    final docs = snapshot.data?.docs ?? [];

    // group by day
    final Map<int, List<Map<String, dynamic>>> grouped = {};
    for (final d in docs) {
      final data = d.data();
      final day = data['dayOfWeek'];
      if (day is! int) continue;
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add({
        'title': (data['title'] ?? '').toString(),
        'room': (data['room'] ?? '').toString(),
        'startMin': (data['startMin'] ?? 0) as int,
        'endMin': (data['endMin'] ?? 0) as int,
      });
    }

    // sort inside each day
    for (final k in grouped.keys) {
      grouped[k]!.sort((a, b) => (a['startMin'] as int).compareTo(b['startMin'] as int));
    }

    Widget classChip(Map<String, dynamic> c) {
      final time = "${_fmtMin(c['startMin'] as int)}-${_fmtMin(c['endMin'] as int)}";
      final title = (c['title'] as String).trim();
      final room = (c['room'] as String).trim();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2B8A8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 2),
            Text(time, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
            if (room.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text("Room: $room", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
            ],
          ],
        ),
      );
    }

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Weekly classes",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              _pillButton(docs.isEmpty ? "Add" : "Open", widget.goToSchedule),
            ],
          ),
          const SizedBox(height: 10),

          if (docs.isEmpty)
            const Text("No weekly classes yet.", style: TextStyle(fontWeight: FontWeight.w800))
          else
            Column(
              children: [
                // header row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _tableHeader,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text("Day", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                      Expanded(
                        child: Text("Classes", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // rows Mon..Sun
                for (final day in [1, 2, 3, 4, 5, 6, 7]) ...[
                  if ((grouped[day] ?? []).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 50,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _dayShort(day),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in grouped[day]!) classChip(c),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  },
),

            const SizedBox(height: 12),

            // ===== Exams / Events (dated) top 3 upcoming =====
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _scheduleRef.where('type', isEqualTo: 'dated').snapshots(),
              builder: (context, snapshot) {
                final all = snapshot.data?.docs ?? [];
                final now = DateTime.now();

                final upcoming = all.where((d) {
                  final data = d.data();
                  if ((data['done'] ?? false) == true) return false;
                  if (data['start'] is! Timestamp) return false;
                  return (data['start'] as Timestamp).toDate().isAfter(now);
                }).toList()
                  ..sort((a, b) {
                    final aS = (a.data()['start'] as Timestamp).toDate();
                    final bS = (b.data()['start'] as Timestamp).toDate();
                    return aS.compareTo(bS);
                  });

                final top3 = upcoming.take(3).toList();

                return _cardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text("Exams / Events",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                          _pillButton(upcoming.isEmpty ? "Add" : "More", widget.goToSchedule),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (upcoming.isEmpty)
                        const Text("No upcoming events.",
                            style: TextStyle(fontWeight: FontWeight.w800))
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final d in top3) ...[
                              Text(
                                (d.data()['title'] ?? '').toString(),
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${_fmtDT((d.data()['start'] as Timestamp).toDate())}"
                                "${((d.data()['room'] ?? '').toString().trim().isEmpty) ? "" : " • ${(d.data()['room'] ?? '').toString()}"}",
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                            ]
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ===== Tasks top 3 (done=false) =====
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _tasksRef.where('done', isEqualTo: false).snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final now = DateTime.now();

                // ترتيب محلي: اللي عنده dueAt أول + الأقرب
                docs.sort((a, b) {
                  final aDue = a.data()['dueAt'];
                  final bDue = b.data()['dueAt'];
                  final aHas = aDue is Timestamp;
                  final bHas = bDue is Timestamp;

                  if (aHas && bHas) {
                    return (aDue).toDate().compareTo((bDue).toDate());
                  }
                  if (aHas && !bHas) return -1;
                  if (!aHas && bHas) return 1;
                  return 0;
                });

                final top = docs.take(3).toList();

                return _cardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text("Tasks",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                          _pillButton(docs.isEmpty ? "Add" : "More", widget.goToTasks),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (docs.isEmpty)
                        const Text("No tasks yet.",
                            style: TextStyle(fontWeight: FontWeight.w800))
                      else
                        Column(
                          children: [
                            for (final d in top) ...[
                              _TaskRow(
                                title: (d.data()['title'] ?? '').toString(),
                                subtitle: (d.data()['dueAt'] is Timestamp)
                                    ? "Deadline: ${_fmtDT((d.data()['dueAt'] as Timestamp).toDate())}"
                                    : "",
                                subtitleRed: (d.data()['dueAt'] is Timestamp)
                                    ? ((d.data()['dueAt'] as Timestamp).toDate().isBefore(now))
                                    : false,
                                onDone: () => _setTaskDone(d.id, true),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool subtitleRed;
  final VoidCallback onDone;

  const _TaskRow({
    required this.title,
    required this.subtitle,
    required this.subtitleRed,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(onTap: onDone, child: const Icon(Icons.radio_button_unchecked)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: subtitleRed ? Colors.red : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}