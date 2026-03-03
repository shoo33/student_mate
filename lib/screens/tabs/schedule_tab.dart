import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // users/{uid}/schedules
  CollectionReference<Map<String, dynamic>> get scheduleRef =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('schedules');

  // ---------- Add / Update / Delete ----------
  Future<void> addScheduleItem({
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    await scheduleRef.add({
      'title': title,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem({
    required String docId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    await scheduleRef.doc(docId).update({
      'title': title,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(String docId) async {
    await scheduleRef.doc(docId).delete();
  }

  // ---------- Pick DateTime ----------
  Future<DateTime?> pickDateTime(BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ---------- Add Dialog ----------
  void showAddDialog() {
    final titleCtrl = TextEditingController();
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: const Text("Add Appointment"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    hintText: "Course name (e.g., SWE356)",
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Start: ${_fmt(start)}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await pickDateTime(context, start);
                        if (picked != null) setLocal(() => start = picked);
                      },
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "End: ${_fmt(end)}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await pickDateTime(context, end);
                        if (picked != null) setLocal(() => end = picked);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;

                  if (end.isBefore(start)) {
                    final temp = start;
                    start = end;
                    end = temp;
                  }

                  await addScheduleItem(title: title, start: start, end: end);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Edit Dialog ----------
  void showEditDialog(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final titleCtrl = TextEditingController(
      text: (data['title'] ?? '').toString(),
    );

    DateTime start = (data['start'] as Timestamp).toDate();
    DateTime end = (data['end'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: const Text("Edit Appointment"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    hintText: "Course name (e.g., SWE356)",
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Start: ${_fmt(start)}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await pickDateTime(context, start);
                        if (picked != null) setLocal(() => start = picked);
                      },
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "End: ${_fmt(end)}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await pickDateTime(context, end);
                        if (picked != null) setLocal(() => end = picked);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;

                  if (end.isBefore(start)) {
                    final temp = start;
                    start = end;
                    end = temp;
                  }

                  await updateItem(
                    docId: doc.id,
                    title: title,
                    start: start,
                    end: end,
                  );

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Format helpers ----------
  String _fmt(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? "pm" : "am";
    return "$h:$m$ampm";
  }

  String _fmtRange(Timestamp start, Timestamp end) {
    final s = _fmt(start.toDate());
    final e = _fmt(end.toDate());
    return "$s → $e";
  }

  // ---------- Group by Day ----------
  final List<String> _weekOrder = const [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  String _dayName(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _groupByDay(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};

    for (final d in docs) {
      final data = d.data();
      final startTs = data['start'];

      if (startTs is! Timestamp) continue;

      final day = _dayName(startTs.toDate());
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(d);
    }

    // sort within each day by start time
    for (final day in grouped.keys) {
      grouped[day]!.sort((a, b) {
        final aStart = (a.data()['start'] as Timestamp).toDate();
        final bStart = (b.data()['start'] as Timestamp).toDate();
        return aStart.compareTo(bStart);
      });
    }

    return grouped;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
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
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: scheduleRef.orderBy('start').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final docs = snapshot.data?.docs ?? [];

              final grouped = _groupByDay(docs);
              final orderedDays =
                  _weekOrder.where((day) => grouped.containsKey(day)).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Schedule",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        onPressed: showAddDialog,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (docs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: const Text(
                        "No appointments yet.\nTap + to add one.",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),

                  // Sections grouped by day
                  for (final day in orderedDays) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    for (final doc in grouped[day]!) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.dark, width: 2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (doc.data()['title'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _fmtRange(doc.data()['start'], doc.data()['end']),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => showEditDialog(doc),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () => deleteItem(doc.id),
                                  icon: const Icon(Icons.delete),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}