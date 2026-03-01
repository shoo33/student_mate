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
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('schedule');

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

  String _fmtTime(dynamic ts) {
    if (ts == null) return '--';
    try {
      final d = (ts as Timestamp).toDate();
      int h = d.hour;
      final m = d.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'pm' : 'am';
      h = h % 12;
      if (h == 0) h = 12;
      return '$h:$m$ampm';
    } catch (_) {
      return '--';
    }
  }

  Future<void> _markDone(String docId) async {
    await _tasksRef.doc(docId).update({'done': true});
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          children: [
            // ✅ شلنا الثلاث نقاط بالكامل

            // Date
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2B8A8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${_weekdayName(now.weekday)}, ${_monthName(now.month)}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
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

            // Schedule (2)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _scheduleRef.orderBy('start').limit(2).snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                if (docs.isEmpty) {
                  return GestureDetector(
                    onTap: widget.goToSchedule,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: const Text("No schedule yet (tap to add)",
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 0; i < docs.length; i++) ...[
                            GestureDetector(
                              onTap: widget.goToSchedule,
                              child: _Pill(text: (docs[i].data()['title'] ?? '').toString()),
                            ),
                            if (i != docs.length - 1) const SizedBox(height: 10),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        for (int i = 0; i < docs.length; i++) ...[
                          _TimePill(
                            text:
                                '${_fmtTime(docs[i].data()['start'])}\n${_fmtTime(docs[i].data()['end'])}',
                          ),
                          if (i != docs.length - 1) const SizedBox(height: 10),
                        ]
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 14),

            // Tasks box (only)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.dark, width: 2),
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _tasksRef
                    .where('done', isEqualTo: false)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Column(
                      children: [
                        const Text("No tasks yet",
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: widget.goToTasks,
                          child: const Text("Go to Tasks"),
                        ),
                      ],
                    );
                  }

                  final topDocs = docs.take(2).toList();

                  return Column(
                    children: [
                      for (final d in topDocs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DashTaskRow(
                            text: (d.data()['title'] ?? '').toString(),
                            onDone: () => _markDone(d.id),
                          ),
                        ),
                      if (docs.length > 2)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: widget.goToTasks,
                            child: const Text("View all"),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2B8A8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _TimePill extends StatelessWidget {
  final String text;
  const _TimePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE8A79A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DashTaskRow extends StatelessWidget {
  final String text;
  final VoidCallback onDone;

  const _DashTaskRow({
    required this.text,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onDone,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.dark, width: 2),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}