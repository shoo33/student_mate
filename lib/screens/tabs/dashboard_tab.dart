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

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');

  CollectionReference<Map<String, dynamic>> get _scheduleRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('schedules');

  // Colors (أغمق شوي ومريح)
  static const Color _cardColor = Color(0xFFE4B8AC);
  static const Color _btnSoft = Color(0xFFC27C86);
  static const Color _dateChip = Color(0xFFE8A79A);

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

  String _dayName(int d) {
    switch (d) {
      case DateTime.sunday: return 'Sunday';
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      default: return '';
    }
  }

  String _fmtMin(int mins) {
    int h = mins ~/ 60;
    final m = (mins % 60).toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$m$ampm';
  }

  String _fmtDue(DateTime d) {
    final months = const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final day = d.day.toString().padLeft(2, '0');
    final mon = months[d.month - 1];

    int h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    h = h % 12;
    if (h == 0) h = 12;

    return "$day $mon • $h:$m$ampm";
  }

  Future<void> _toggleTaskDone(String id, bool v) async {
    await _tasksRef.doc(id).update({'done': v});
  }

  Future<void> _toggleDatedScheduleDone(String id, bool v) async {
    await _scheduleRef.doc(id).update({'done': v});
  }

  Widget _softButton(String text, VoidCallback onTap) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _btnSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.email ?? "student").split('@').first;

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
            // Welcome + Date
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _btnSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, $name",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_weekdayName(now.weekday)}, ${_monthName(now.month)}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: _dateChip, shape: BoxShape.circle),
                    child: Text("${now.day}", style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Quote
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

            // Schedule Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.dark, width: 2),
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _scheduleRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (snapshot.hasError) return Text("Error: ${snapshot.error}");

                  final docs = snapshot.data?.docs ?? [];

                  final weekly = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  final upcomingDated = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                  for (final d in docs) {
                    final data = d.data();
                    final type = (data['type'] ?? 'weekly').toString();

                    if (type == 'dated') {
                      final done = (data['done'] ?? false) == true;
                      if (done) continue;
                      if (data['start'] is! Timestamp || data['end'] is! Timestamp) continue;

                      final start = (data['start'] as Timestamp).toDate();
                      if (start.isBefore(DateTime.now())) continue; // expired لا يطلع بالهوم

                      upcomingDated.add(d);
                    } else {
                      if (data['dayOfWeek'] is int && data['startMin'] is int && data['endMin'] is int) {
                        weekly.add(d);
                      }
                    }
                  }

                  // Sort
                  upcomingDated.sort((a, b) {
                    final aS = (a.data()['start'] as Timestamp).toDate();
                    final bS = (b.data()['start'] as Timestamp).toDate();
                    return aS.compareTo(bS);
                  });

                  weekly.sort((a, b) {
                    final ad = (a.data()['dayOfWeek'] ?? 0) as int;
                    final bd = (b.data()['dayOfWeek'] ?? 0) as int;
                    if (ad != bd) return ad.compareTo(bd);
                    final as = (a.data()['startMin'] ?? 0) as int;
                    final bs = (b.data()['startMin'] ?? 0) as int;
                    return as.compareTo(bs);
                  });

                  final topDated = upcomingDated.take(3).toList();
                  final hasMoreDated = upcomingDated.length > 3;
                  final hasAny = weekly.isNotEmpty || upcomingDated.isNotEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Schedule", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 10),

                      if (!hasAny) ...[
                        const Text("No schedule yet.", style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        _softButton("Add", widget.goToSchedule),
                      ] else ...[
                        if (topDated.isNotEmpty) ...[
                          const Text("Upcoming", style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          for (final d in topDated) ...[
                            _MiniRow(
                              leading: GestureDetector(
                                onTap: () => _toggleDatedScheduleDone(d.id, true),
                                child: const Icon(Icons.radio_button_unchecked),
                              ),
                              title: (d.data()['title'] ?? '').toString(),
                              subtitle: _fmtDue((d.data()['start'] as Timestamp).toDate()),
                              room: (d.data()['room'] ?? '').toString(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (hasMoreDated) ...[
                            const SizedBox(height: 6),
                            _softButton("More", widget.goToSchedule),
                          ],
                          const SizedBox(height: 10),
                        ],

                        if (weekly.isNotEmpty) ...[
                          const Text("Weekly", style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          for (final d in weekly) ...[
                            _MiniRow(
                              leading: const SizedBox(width: 24),
                              title: (d.data()['title'] ?? '').toString(),
                              subtitle:
                                  "${_dayName((d.data()['dayOfWeek'] ?? DateTime.monday) as int)} • "
                                  "${_fmtMin((d.data()['startMin'] ?? 0) as int)} → ${_fmtMin((d.data()['endMin'] ?? 0) as int)}",
                              room: (d.data()['room'] ?? '').toString(),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Tasks Card (✅ فيه Complete في الهوم)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.dark, width: 2),
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _tasksRef.orderBy('createdAt', descending: true).limit(160).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (snapshot.hasError) return Text("Error: ${snapshot.error}");

                  final docs = snapshot.data?.docs ?? [];
                  final now = DateTime.now();

                  final upcoming = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  final noDeadline = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                  for (final d in docs) {
                    final data = d.data();
                    final done = (data['done'] ?? false) == true;
                    if (done) continue;

                    final due = data['dueAt'];
                    if (due is Timestamp) {
                      final dueDate = due.toDate();
                      if (dueDate.isBefore(now)) continue; // expired لا يطلع بالهوم
                      upcoming.add(d);
                    } else {
                      noDeadline.add(d);
                    }
                  }

                  upcoming.sort((a, b) {
                    final aD = (a.data()['dueAt'] as Timestamp).toDate();
                    final bD = (b.data()['dueAt'] as Timestamp).toDate();
                    return aD.compareTo(bD);
                  });

                  noDeadline.sort((a, b) {
                    final aC = a.data()['createdAt'];
                    final bC = b.data()['createdAt'];
                    final aDate = aC is Timestamp ? aC.toDate() : DateTime(2000);
                    final bDate = bC is Timestamp ? bC.toDate() : DateTime(2000);
                    return bDate.compareTo(aDate);
                  });

                  final merged = <QueryDocumentSnapshot<Map<String, dynamic>>>[
                    ...upcoming,
                    ...noDeadline,
                  ];

                  final top = merged.take(3).toList();
                  final hasMore = merged.length > 3;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tasks", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 10),

                      if (top.isEmpty) ...[
                        const Text("No tasks yet.", style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        _softButton("Add", widget.goToTasks),
                      ] else ...[
                        for (final d in top) ...[
                          _MiniRow(
                            leading: GestureDetector(
                              onTap: () => _toggleTaskDone(d.id, true),
                              child: const Icon(Icons.radio_button_unchecked),
                            ),
                            title: (d.data()['title'] ?? '').toString(),
                            subtitle: (d.data()['dueAt'] is Timestamp)
                                ? "Deadline: ${_fmtDue((d.data()['dueAt'] as Timestamp).toDate())}"
                                : "No deadline",
                            room: "",
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (hasMore) _softButton("More", widget.goToTasks),
                      ],
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String room;

  const _MiniRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final roomText = room.trim().isEmpty ? "" : " • $room";

    return Row(
      children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                "$subtitle$roomText",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}