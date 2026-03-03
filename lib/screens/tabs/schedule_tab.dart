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

  CollectionReference<Map<String, dynamic>> get scheduleRef =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('schedules');

  //  لون كروت 
  static const Color _tileColor = Color(0xFFE9C2B7);

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  String _dayName(int d) {
    switch (d) {
      case DateTime.sunday:
        return 'Sunday';
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
      default:
        return '';
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

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
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

  Future<void> _toggleDatedDone(String id, bool v) async {
    await scheduleRef.doc(id).update({'done': v});
  }

  Future<void> _delete(String id) async {
    await scheduleRef.doc(id).delete();
  }

  void showUpsertDialog({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) {
    final bool isEdit = doc != null;
    final String? docId = doc?.id;
    final Map<String, dynamic> data = doc?.data() ?? <String, dynamic>{};

    final titleCtrl = TextEditingController(text: (data['title'] ?? '').toString());
    final roomCtrl = TextEditingController(text: (data['room'] ?? '').toString());

    String type = (data['type'] ?? 'weekly').toString(); // weekly / dated

    int dayOfWeek = (data['dayOfWeek'] is int) ? data['dayOfWeek'] as int : DateTime.monday;
    int startMin = (data['startMin'] is int) ? data['startMin'] as int : 8 * 60;
    int endMin = (data['endMin'] is int) ? data['endMin'] as int : 9 * 60;

    DateTime startDT =
        (data['start'] is Timestamp) ? (data['start'] as Timestamp).toDate() : DateTime.now();
    DateTime endDT = (data['end'] is Timestamp)
        ? (data['end'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(isEdit ? "Edit schedule" : "Add schedule"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(hintText: "Title"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(hintText: "Room (optional)"),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text("Weekly class")),
                  DropdownMenuItem(value: 'dated', child: Text("Exam / Event")),
                ],
                onChanged: (v) => setLocal(() => type = v ?? 'weekly'),
                decoration: const InputDecoration(labelText: "Type"),
              ),
              const SizedBox(height: 12),

              if (type == 'weekly') ...[
                DropdownButtonFormField<int>(
                  value: dayOfWeek,
                  items: const [
                    DropdownMenuItem(value: DateTime.sunday, child: Text("Sunday")),
                    DropdownMenuItem(value: DateTime.monday, child: Text("Monday")),
                    DropdownMenuItem(value: DateTime.tuesday, child: Text("Tuesday")),
                    DropdownMenuItem(value: DateTime.wednesday, child: Text("Wednesday")),
                    DropdownMenuItem(value: DateTime.thursday, child: Text("Thursday")),
                    DropdownMenuItem(value: DateTime.friday, child: Text("Friday")),
                    DropdownMenuItem(value: DateTime.saturday, child: Text("Saturday")),
                  ],
                  onChanged: (v) => setLocal(() => dayOfWeek = v ?? DateTime.monday),
                  decoration: const InputDecoration(labelText: "Day"),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Text("Start: ${_fmtMin(startMin)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60),
                        );
                        if (picked != null) setLocal(() => startMin = _toMin(picked));
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text("End: ${_fmtMin(endMin)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60),
                        );
                        if (picked != null) setLocal(() => endMin = _toMin(picked));
                      },
                    ),
                  ],
                ),
              ],

              if (type == 'dated') ...[
                Row(
                  children: [
                    Expanded(
                      child: Text("Start: ${startDT.toString().substring(0, 16)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.event),
                      onPressed: () async {
                        final picked = await _pickDateTime(context, startDT);
                        if (picked != null) setLocal(() => startDT = picked);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text("End: ${endDT.toString().substring(0, 16)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.event),
                      onPressed: () async {
                        final picked = await _pickDateTime(context, endDT);
                        if (picked != null) setLocal(() => endDT = picked);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final room = roomCtrl.text.trim();
                final roomValue = room.isEmpty ? null : room;

                if (title.isEmpty) return;

                if (type == 'weekly') {
                  final s = startMin;
                  final e = endMin;
                  final fixedStart = s <= e ? s : e;
                  final fixedEnd = s <= e ? e : s;

                  final payload = <String, dynamic>{
                    'title': title,
                    'room': roomValue,
                    'type': 'weekly',
                    'dayOfWeek': dayOfWeek,
                    'startMin': fixedStart,
                    'endMin': fixedEnd,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (isEdit && docId != null) {
                    await scheduleRef.doc(docId).update(payload);
                  } else {
                    await scheduleRef.add({
                      ...payload,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }
                } else {
                  DateTime s = startDT;
                  DateTime e = endDT;
                  if (e.isBefore(s)) {
                    final tmp = s;
                    s = e;
                    e = tmp;
                  }

                  final payload = <String, dynamic>{
                    'title': title,
                    'room': roomValue,
                    'type': 'dated',
                    'start': Timestamp.fromDate(s),
                    'end': Timestamp.fromDate(e),
                    'done': (data['done'] ?? false) == true ? true : false,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (isEdit && docId != null) {
                    await scheduleRef.doc(docId).update(payload);
                  } else {
                    await scheduleRef.add({
                      ...payload,
                      'done': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,

      //  + واحد فقط تحت
      floatingActionButton: FloatingActionButton(
        onPressed: () => showUpsertDialog(),
        child: const Icon(Icons.add),
      ),

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
            stream: scheduleRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

              final docs = snapshot.data?.docs ?? [];

              final weekly = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final datedUpcoming = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final datedDone = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              for (final d in docs) {
                final data = d.data();
                final type = (data['type'] ?? 'weekly').toString();
                if (type == 'dated') {
                  final done = (data['done'] ?? false) == true;
                  if (done) {
                    datedDone.add(d);
                  } else {
                    datedUpcoming.add(d);
                  }
                } else {
                  weekly.add(d);
                }
              }

              final weekOrder = const [
                DateTime.sunday,
                DateTime.monday,
                DateTime.tuesday,
                DateTime.wednesday,
                DateTime.thursday,
                DateTime.friday,
                DateTime.saturday,
              ];

              final Map<int, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byDay = {};
              for (final d in weekly) {
                final data = d.data();
                if (data['dayOfWeek'] is int) {
                  final dow = data['dayOfWeek'] as int;
                  byDay.putIfAbsent(dow, () => []);
                  byDay[dow]!.add(d);
                }
              }

              for (final dow in byDay.keys) {
                byDay[dow]!.sort((a, b) {
                  final aMin = (a.data()['startMin'] ?? 0) as int;
                  final bMin = (b.data()['startMin'] ?? 0) as int;
                  return aMin.compareTo(bMin);
                });
              }

              datedUpcoming.sort((a, b) {
                final aS = (a.data()['start'] as Timestamp).toDate();
                final bS = (b.data()['start'] as Timestamp).toDate();
                return aS.compareTo(bS);
              });

              datedDone.sort((a, b) {
                final aS = (a.data()['start'] as Timestamp).toDate();
                final bS = (b.data()['start'] as Timestamp).toDate();
                return bS.compareTo(aS);
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  const Text("Schedule",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),

                  if (docs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _tileColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: const Text(
                        "No schedule yet.\nPress + to add.",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                  if (byDay.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text("Weekly schedule",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 10),

                    for (final dow in weekOrder)
                      if (byDay.containsKey(dow)) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 6),
                          child: Text(_dayName(dow),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                        for (final d in byDay[dow]!) ...[
                          _WeeklyTile(
                            color: _tileColor,
                            title: (d.data()['title'] ?? '').toString(),
                            room: (d.data()['room'] ?? '').toString(),
                            startMin: (d.data()['startMin'] ?? 0) as int,
                            endMin: (d.data()['endMin'] ?? 0) as int,
                            fmtMin: _fmtMin,
                            onEdit: () => showUpsertDialog(doc: d),
                            onDelete: () => _delete(d.id),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                  ],

                  const SizedBox(height: 14),
                  const Text("Exams / Events",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 10),

                  if (datedUpcoming.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _tileColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: const Text(
                        "No upcoming exams/events.",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                  for (final d in datedUpcoming) ...[
                    _DatedTile(
                      color: _tileColor,
                      title: (d.data()['title'] ?? '').toString(),
                      room: (d.data()['room'] ?? '').toString(),
                      start: (d.data()['start'] as Timestamp).toDate(),
                      end: (d.data()['end'] as Timestamp).toDate(),
                      fmtDue: _fmtDue,
                      overdue: ((d.data()['start'] as Timestamp).toDate()).isBefore(now),
                      done: false,
                      onToggleDone: () => _toggleDatedDone(d.id, true),
                      onEdit: () => showUpsertDialog(doc: d),
                      onDelete: () => _delete(d.id),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (datedDone.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text("Completed",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 10),

                    for (final d in datedDone) ...[
                      _DatedTile(
                        color: _tileColor,
                        title: (d.data()['title'] ?? '').toString(),
                        room: (d.data()['room'] ?? '').toString(),
                        start: (d.data()['start'] as Timestamp).toDate(),
                        end: (d.data()['end'] as Timestamp).toDate(),
                        fmtDue: _fmtDue,
                        overdue: false,
                        done: true,
                        onToggleDone: () => _toggleDatedDone(d.id, false),
                        onEdit: () => showUpsertDialog(doc: d),
                        onDelete: () => _delete(d.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WeeklyTile extends StatelessWidget {
  final Color color;
  final String title;
  final String room;
  final int startMin;
  final int endMin;
  final String Function(int) fmtMin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WeeklyTile({
    required this.color,
    required this.title,
    required this.room,
    required this.startMin,
    required this.endMin,
    required this.fmtMin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final roomText = room.trim().isEmpty ? "" : " • Room: $room";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 6),
                Text("${fmtMin(startMin)} → ${fmtMin(endMin)}$roomText",
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }
}

class _DatedTile extends StatelessWidget {
  final Color color;
  final String title;
  final String room;
  final DateTime start;
  final DateTime end;
  final String Function(DateTime) fmtDue;
  final bool overdue;
  final bool done;
  final VoidCallback onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DatedTile({
    required this.color,
    required this.title,
    required this.room,
    required this.start,
    required this.end,
    required this.fmtDue,
    required this.overdue,
    required this.done,
    required this.onToggleDone,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final roomText = room.trim().isEmpty ? "" : " • Room: $room";
    final timeText = "${fmtDue(start)} → ${fmtDue(end)}$roomText";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleDone,
            child: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeText,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: (!done && overdue) ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }
}