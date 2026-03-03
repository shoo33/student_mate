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

  // Theme-ish colors (أغمق شوي)
  static const Color _cardColor = Color(0xFFE4B8AC);
  static const Color _pill = Color(0xFFC27C86);

  // ----- Helpers -----
  String _dayName(int weekday) {
    // 1=Monday .. 7=Sunday
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
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

  String _fmtDateTime(DateTime d) {
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

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
    return showTimePicker(context: context, initialTime: initial);
  }

  int _todToMin(TimeOfDay t) => t.hour * 60 + t.minute;

  // ----- Firestore ops -----
  Future<void> _addWeekly({
    required String title,
    required int dayOfWeek,
    required int startMin,
    required int endMin,
    required String room,
  }) async {
    await scheduleRef.add({
      'type': 'weekly',
      'title': title,
      'dayOfWeek': dayOfWeek,
      'startMin': startMin,
      'endMin': endMin,
      'room': room,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateWeekly({
    required String docId,
    required String title,
    required int dayOfWeek,
    required int startMin,
    required int endMin,
    required String room,
  }) async {
    await scheduleRef.doc(docId).update({
      'type': 'weekly',
      'title': title,
      'dayOfWeek': dayOfWeek,
      'startMin': startMin,
      'endMin': endMin,
      'room': room,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _addDated({
    required String title,
    required DateTime start,
    required DateTime end,
    required String room,
  }) async {
    await scheduleRef.add({
      'type': 'dated',
      'title': title,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'room': room,
      'done': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateDated({
    required String docId,
    required String title,
    required DateTime start,
    required DateTime end,
    required String room,
  }) async {
    await scheduleRef.doc(docId).update({
      'type': 'dated',
      'title': title,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'room': room,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _setDatedDone(String docId, bool v) async {
    await scheduleRef.doc(docId).update({
      'done': v,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _delete(String docId) async {
    await scheduleRef.doc(docId).delete();
  }

  // ----- Dialogs -----
  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final roomCtrl = TextEditingController();

    bool isDated = false; // default weekly
    int dayOfWeek = DateTime.monday;

    TimeOfDay startT = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endT = const TimeOfDay(hour: 9, minute: 0);

    DateTime startDT = DateTime.now().add(const Duration(hours: 1));
    DateTime endDT = DateTime.now().add(const Duration(hours: 2));

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(isDated ? "Add exam / event" : "Add weekly class"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setLocal(() => isDated = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isDated ? const Color(0xFFEFE6E2) : _pill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            "Weekly",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isDated ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setLocal(() => isDated = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isDated ? _pill : const Color(0xFFEFE6E2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            "Dated",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isDated ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: isDated ? "Title (e.g., Midterm)" : "Course (e.g., SWE356)",
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(
                    hintText: "Room (optional)",
                  ),
                ),
                const SizedBox(height: 12),

                if (!isDated) ...[
                  // Weekly fields
                  DropdownButtonFormField<int>(
                    value: dayOfWeek,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Monday")),
                      DropdownMenuItem(value: 2, child: Text("Tuesday")),
                      DropdownMenuItem(value: 3, child: Text("Wednesday")),
                      DropdownMenuItem(value: 4, child: Text("Thursday")),
                      DropdownMenuItem(value: 5, child: Text("Friday")),
                      DropdownMenuItem(value: 6, child: Text("Saturday")),
                      DropdownMenuItem(value: 7, child: Text("Sunday")),
                    ],
                    onChanged: (v) => setLocal(() => dayOfWeek = v ?? 1),
                    decoration: const InputDecoration(labelText: "Day"),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Text("Start: ${startT.format(context)}",
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () async {
                          final p = await _pickTime(context, startT);
                          if (p != null) setLocal(() => startT = p);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text("End: ${endT.format(context)}",
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () async {
                          final p = await _pickTime(context, endT);
                          if (p != null) setLocal(() => endT = p);
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  // Dated fields
                  Row(
                    children: [
                      Expanded(
                        child: Text("Start: ${_fmtDateTime(startDT)}",
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.event),
                        onPressed: () async {
                          final p = await _pickDateTime(context, startDT);
                          if (p != null) setLocal(() => startDT = p);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text("End: ${_fmtDateTime(endDT)}",
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.event),
                        onPressed: () async {
                          final p = await _pickDateTime(context, endDT);
                          if (p != null) setLocal(() => endDT = p);
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final room = roomCtrl.text.trim();
                if (title.isEmpty) return;

                if (!isDated) {
                  int s = _todToMin(startT);
                  int e = _todToMin(endT);
                  if (e < s) {
                    final tmp = s;
                    s = e;
                    e = tmp;
                  }
                  await _addWeekly(
                    title: title,
                    dayOfWeek: dayOfWeek,
                    startMin: s,
                    endMin: e,
                    room: room,
                  );
                } else {
                  if (endDT.isBefore(startDT)) {
                    final tmp = startDT;
                    startDT = endDT;
                    endDT = tmp;
                  }
                  await _addDated(title: title, start: startDT, end: endDT, room: room);
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

  void _showEditWeeklyDialog(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final titleCtrl = TextEditingController(text: (data['title'] ?? '').toString());
    final roomCtrl = TextEditingController(text: (data['room'] ?? '').toString());

    int dayOfWeek = (data['dayOfWeek'] is int) ? data['dayOfWeek'] as int : 1;
    int startMin = (data['startMin'] is int) ? data['startMin'] as int : 480;
    int endMin = (data['endMin'] is int) ? data['endMin'] as int : 540;

    TimeOfDay startT = TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
    TimeOfDay endT = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Edit weekly class"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: "Course")),
                const SizedBox(height: 10),
                TextField(controller: roomCtrl, decoration: const InputDecoration(hintText: "Room (optional)")),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: dayOfWeek,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("Monday")),
                    DropdownMenuItem(value: 2, child: Text("Tuesday")),
                    DropdownMenuItem(value: 3, child: Text("Wednesday")),
                    DropdownMenuItem(value: 4, child: Text("Thursday")),
                    DropdownMenuItem(value: 5, child: Text("Friday")),
                    DropdownMenuItem(value: 6, child: Text("Saturday")),
                    DropdownMenuItem(value: 7, child: Text("Sunday")),
                  ],
                  onChanged: (v) => setLocal(() => dayOfWeek = v ?? 1),
                  decoration: const InputDecoration(labelText: "Day"),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Text("Start: ${startT.format(context)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final p = await _pickTime(context, startT);
                        if (p != null) setLocal(() => startT = p);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text("End: ${endT.format(context)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final p = await _pickTime(context, endT);
                        if (p != null) setLocal(() => endT = p);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final room = roomCtrl.text.trim();
                if (title.isEmpty) return;

                int s = _todToMin(startT);
                int e = _todToMin(endT);
                if (e < s) {
                  final tmp = s;
                  s = e;
                  e = tmp;
                }

                await _updateWeekly(
                  docId: doc.id,
                  title: title,
                  dayOfWeek: dayOfWeek,
                  startMin: s,
                  endMin: e,
                  room: room,
                );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDatedDialog(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final titleCtrl = TextEditingController(text: (data['title'] ?? '').toString());
    final roomCtrl = TextEditingController(text: (data['room'] ?? '').toString());

    DateTime startDT = (data['start'] as Timestamp).toDate();
    DateTime endDT = (data['end'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Edit exam / event"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: "Title")),
                const SizedBox(height: 10),
                TextField(controller: roomCtrl, decoration: const InputDecoration(hintText: "Room (optional)")),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text("Start: ${_fmtDateTime(startDT)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.event),
                      onPressed: () async {
                        final p = await _pickDateTime(context, startDT);
                        if (p != null) setLocal(() => startDT = p);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text("End: ${_fmtDateTime(endDT)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.event),
                      onPressed: () async {
                        final p = await _pickDateTime(context, endDT);
                        if (p != null) setLocal(() => endDT = p);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final room = roomCtrl.text.trim();
                if (title.isEmpty) return;

                if (endDT.isBefore(startDT)) {
                  final tmp = startDT;
                  startDT = endDT;
                  endDT = tmp;
                }

                await _updateDated(
                  docId: doc.id,
                  title: title,
                  start: startDT,
                  end: endDT,
                  room: room,
                );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // ----- UI builders -----
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _weeklyTile({
    required String title,
    required String timeText,
    required String room,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final roomText = room.trim().isEmpty ? "" : " • Room: $room";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                "$timeText$roomText",
                style: const TextStyle(fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }

  Widget _datedUpcomingTile({
    required String title,
    required DateTime start,
    required DateTime end,
    required String room,
    required VoidCallback onComplete,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final roomText = room.trim().isEmpty ? "" : " • Room: $room";
    final timeText = "${_fmtDateTime(start)}  →  ${_fmtDateTime(end)}$roomText";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onComplete,
            child: const Icon(Icons.radio_button_unchecked),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                timeText,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }

  // ✅ Expired: حذف فقط (بدون تشيك/قلم/أيقونات)
  Widget _datedExpiredDeleteOnly({
    required String title,
    required DateTime start,
    required DateTime end,
    required String room,
    required VoidCallback onDelete,
  }) {
    final roomText = room.trim().isEmpty ? "" : " • Room: $room";
    final timeText = "${_fmtDateTime(start)}  →  ${_fmtDateTime(end)}$roomText";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                timeText,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.red),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }

  Widget _datedCompletedTile({
    required String title,
    required DateTime start,
    required DateTime end,
    required String room,
    required VoidCallback onDelete,
  }) {
    final roomText = room.trim().isEmpty ? "" : " • Room: $room";
    final timeText = "${_fmtDateTime(start)}  →  ${_fmtDateTime(end)}$roomText";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                timeText,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }

  // ----- Build -----
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      // ✅ زر + واحد فقط تحت
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
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
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final all = snapshot.data?.docs ?? [];

              // Split
              final weekly = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final upcoming = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final expired = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final completed = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              for (final d in all) {
                final data = d.data();
                final type = (data['type'] ?? 'weekly').toString();

                if (type == 'weekly') {
                  if (data['dayOfWeek'] is int && data['startMin'] is int && data['endMin'] is int) {
                    weekly.add(d);
                  }
                } else {
                  // dated
                  if (data['start'] is! Timestamp || data['end'] is! Timestamp) continue;
                  final done = (data['done'] ?? false) == true;
                  final start = (data['start'] as Timestamp).toDate();

                  if (done) {
                    completed.add(d);
                  } else if (start.isBefore(now)) {
                    expired.add(d);
                  } else {
                    upcoming.add(d);
                  }
                }
              }

              // sort weekly: day then start
              weekly.sort((a, b) {
                final ad = (a.data()['dayOfWeek'] ?? 0) as int;
                final bd = (b.data()['dayOfWeek'] ?? 0) as int;
                if (ad != bd) return ad.compareTo(bd);
                final as = (a.data()['startMin'] ?? 0) as int;
                final bs = (b.data()['startMin'] ?? 0) as int;
                return as.compareTo(bs);
              });

              // sort upcoming by nearest start
              upcoming.sort((a, b) {
                final aS = (a.data()['start'] as Timestamp).toDate();
                final bS = (b.data()['start'] as Timestamp).toDate();
                return aS.compareTo(bS);
              });

              // sort expired newest first
              expired.sort((a, b) {
                final aS = (a.data()['start'] as Timestamp).toDate();
                final bS = (b.data()['start'] as Timestamp).toDate();
                return bS.compareTo(aS);
              });

              // completed newest first
              completed.sort((a, b) {
                final aS = (a.data()['start'] as Timestamp).toDate();
                final bS = (b.data()['start'] as Timestamp).toDate();
                return bS.compareTo(aS);
              });

              // group weekly by day
              final Map<int, List<QueryDocumentSnapshot<Map<String, dynamic>>>> weeklyByDay = {};
              for (final d in weekly) {
                final day = (d.data()['dayOfWeek'] ?? 1) as int;
                weeklyByDay.putIfAbsent(day, () => []);
                weeklyByDay[day]!.add(d);
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  const Text(
                    "Schedule",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),

                  // Weekly
                  _sectionTitle("Weekly schedule"),
                  if (weekly.isEmpty)
                    _InfoCard(text: "No weekly classes yet.", buttonText: "Add", onTap: _showAddDialog),

                  for (final day in [1,2,3,4,5,6,7]) ...[
                    if ((weeklyByDay[day] ?? []).isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 6),
                        child: Text(
                          _dayName(day),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      for (final doc in weeklyByDay[day]!) ...[
                        _weeklyTile(
                          title: (doc.data()['title'] ?? '').toString(),
                          timeText:
                              "${_fmtMin((doc.data()['startMin'] ?? 0) as int)} → ${_fmtMin((doc.data()['endMin'] ?? 0) as int)}",
                          room: (doc.data()['room'] ?? '').toString(),
                          onEdit: () => _showEditWeeklyDialog(doc),
                          onDelete: () => _delete(doc.id),
                        ),
                      ],
                    ]
                  ],

                  const SizedBox(height: 12),

                  // Dated
                  _sectionTitle("Exams / Events"),

                  // Upcoming
                  if (upcoming.isNotEmpty) ...[
                    const Text("Upcoming", style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    for (final doc in upcoming) ...[
                      _datedUpcomingTile(
                        title: (doc.data()['title'] ?? '').toString(),
                        start: (doc.data()['start'] as Timestamp).toDate(),
                        end: (doc.data()['end'] as Timestamp).toDate(),
                        room: (doc.data()['room'] ?? '').toString(),
                        onComplete: () => _setDatedDone(doc.id, true),
                        onEdit: () => _showEditDatedDialog(doc),
                        onDelete: () => _delete(doc.id),
                      ),
                    ],
                  ] else
                    _InfoCard(text: "No upcoming exams/events.", buttonText: "Add", onTap: _showAddDialog),

                  // Expired (✅ حذف فقط)
                  if (expired.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text("Expired", style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    for (final doc in expired) ...[
                      _datedExpiredDeleteOnly(
                        title: (doc.data()['title'] ?? '').toString(),
                        start: (doc.data()['start'] as Timestamp).toDate(),
                        end: (doc.data()['end'] as Timestamp).toDate(),
                        room: (doc.data()['room'] ?? '').toString(),
                        onDelete: () => _delete(doc.id),
                      ),
                    ],
                  ],

                  // Completed
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text("Completed", style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    for (final doc in completed) ...[
                      _datedCompletedTile(
                        title: (doc.data()['title'] ?? '').toString(),
                        start: (doc.data()['start'] as Timestamp).toDate(),
                        end: (doc.data()['end'] as Timestamp).toDate(),
                        room: (doc.data()['room'] ?? '').toString(),
                        onDelete: () => _delete(doc.id),
                      ),
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

class _InfoCard extends StatelessWidget {
  final String text;
  final String buttonText;
  final VoidCallback onTap;

  const _InfoCard({
    required this.text,
    required this.buttonText,
    required this.onTap,
  });

  static const Color _btnSoft = Color(0xFFC27C86);
  static const Color _cardColor = Color(0xFFE4B8AC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Align(
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
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}