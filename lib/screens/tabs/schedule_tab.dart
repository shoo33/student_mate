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

  CollectionReference<Map<String, dynamic>> get ref =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('schedules');

  String _dayName(int d) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return names[(d - 1).clamp(0, 6)];
  }

  String _fmtMin(int mins) {
    final h24 = mins ~/ 60;
    final m = (mins % 60).toString().padLeft(2, '0');
    final ampm = h24 >= 12 ? 'pm' : 'am';
    var h = h24 % 12;
    if (h == 0) h = 12;
    return '$h:$m$ampm';
  }

  String _fmt(DateTime d) {
    int h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    h %= 12;
    if (h == 0) h = 12;
    return '$h:$m$ampm';
  }

  String _fmtDateTime(Timestamp ts) {
    final d = ts.toDate();
    final dd = d.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '$dd ${months[d.month - 1]} · ${_fmt(d)}';
  }

  bool _isOverdueDated(Map<String, dynamic> s) {
    final type = (s['type'] ?? 'weekly').toString();
    if (type != 'dated') return false;
    final done = (s['done'] ?? false) == true;
    if (done) return false;
    final end = s['end'];
    if (end is! Timestamp) return false;
    return end.toDate().isBefore(DateTime.now());
  }

  bool _datePassed(Timestamp? ts) {
    if (ts == null) return false;
    return ts.toDate().isBefore(DateTime.now());
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (date == null) return null;
    if (!context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    if (!context.mounted) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _showRestoreExpiredDialog(
    BuildContext context, {
    required String typeName,
    required VoidCallback onEdit,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Date expired"),
          content: Text(
            "This $typeName date has already passed.\nEdit the date first if you want to restore it.",
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rose,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onEdit();
              },
              child: const Text("Edit date"),
            ),
          ],
        );
      },
    );
  }

  void _showAddChooser() {
    int tab = 0;

    final wTitle = TextEditingController();
    final wRoom = TextEditingController();
    int wDay = 1;
    int wStartMin = 8 * 60;
    int wEndMin = 9 * 60;

    final eTitle = TextEditingController();
    final eRoom = TextEditingController();
    DateTime eStart = DateTime.now();
    DateTime eEnd = DateTime.now().add(const Duration(hours: 1));

    Future<void> pickWeeklyStart(BuildContext ctx, void Function(void Function()) setLocal) async {
      final t = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay(hour: wStartMin ~/ 60, minute: wStartMin % 60),
      );
      if (t == null) return;
      if (!ctx.mounted) return;
      setLocal(() => wStartMin = t.hour * 60 + t.minute);
    }

    Future<void> pickWeeklyEnd(BuildContext ctx, void Function(void Function()) setLocal) async {
      final t = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay(hour: wEndMin ~/ 60, minute: wEndMin % 60),
      );
      if (t == null) return;
      if (!ctx.mounted) return;
      setLocal(() => wEndMin = t.hour * 60 + t.minute);
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget tabBtn(String text, int idx) {
              final selected = tab == idx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setLocal(() => tab = idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.rose : const Color(0xFFF2B8A8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.dark, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return AlertDialog(
              title: const Text("Add"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      tabBtn("Weekly", 0),
                      const SizedBox(width: 10),
                      tabBtn("Exams", 1),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (tab == 0) ...[
                    TextField(
                      controller: wTitle,
                      decoration: const InputDecoration(labelText: "Course"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: wRoom,
                      decoration: const InputDecoration(labelText: "Room (optional)"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: wDay,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("Sunday")),
                        DropdownMenuItem(value: 2, child: Text("Monday")),
                        DropdownMenuItem(value: 3, child: Text("Tuesday")),
                        DropdownMenuItem(value: 4, child: Text("Wednesday")),
                        DropdownMenuItem(value: 5, child: Text("Thursday")),
                        DropdownMenuItem(value: 6, child: Text("Friday")),
                        DropdownMenuItem(value: 7, child: Text("Saturday")),
                      ],
                      onChanged: (v) => setLocal(() => wDay = v ?? 1),
                      decoration: const InputDecoration(labelText: "Day"),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Start: ${_fmtMin(wStartMin)}",
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () => pickWeeklyStart(ctx, setLocal),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "End: ${_fmtMin(wEndMin)}",
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () => pickWeeklyEnd(ctx, setLocal),
                        ),
                      ],
                    ),
                  ] else ...[
                    TextField(
                      controller: eTitle,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: eRoom,
                      decoration: const InputDecoration(labelText: "Room (optional)"),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Start: ${_fmtDateTime(Timestamp.fromDate(eStart))}",
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: () async {
                            final picked = await _pickDateTime(ctx, eStart);
                            if (picked != null) setLocal(() => eStart = picked);
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "End: ${_fmtDateTime(Timestamp.fromDate(eEnd))}",
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: () async {
                            final picked = await _pickDateTime(ctx, eEnd);
                            if (picked != null) setLocal(() => eEnd = picked);
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.rose,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (tab == 0) {
                      final title = wTitle.text.trim();
                      if (title.isEmpty) return;

                      int startMin = wStartMin;
                      int endMin = wEndMin;
                      if (endMin < startMin) {
                        final tmp = startMin;
                        startMin = endMin;
                        endMin = tmp;
                      }

                      await ref.add({
                        'type': 'weekly',
                        'title': title,
                        'room': wRoom.text.trim(),
                        'dayOfWeek': wDay,
                        'startMin': startMin,
                        'endMin': endMin,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      final title = eTitle.text.trim();
                      if (title.isEmpty) return;

                      DateTime start = eStart;
                      DateTime end = eEnd;
                      if (end.isBefore(start)) {
                        final tmp = start;
                        start = end;
                        end = tmp;
                      }

                      await ref.add({
                        'type': 'dated',
                        'title': title,
                        'room': eRoom.text.trim(),
                        'start': Timestamp.fromDate(start),
                        'end': Timestamp.fromDate(end),
                        'done': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWeeklyDialog({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) {
    final data = doc?.data();

    final titleCtrl = TextEditingController(text: (data?['title'] ?? '').toString());
    final roomCtrl = TextEditingController(text: (data?['room'] ?? '').toString());

    int dayOfWeek = (data?['dayOfWeek'] ?? 1) is int ? (data?['dayOfWeek'] ?? 1) : 1;
    int startMin = (data?['startMin'] ?? 8 * 60) is int ? (data?['startMin'] ?? 8 * 60) : 8 * 60;
    int endMin = (data?['endMin'] ?? 9 * 60) is int ? (data?['endMin'] ?? 9 * 60) : 9 * 60;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> pickStart() async {
              final t = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60),
              );
              if (t == null) return;
              if (!ctx.mounted) return;
              setLocal(() => startMin = t.hour * 60 + t.minute);
            }

            Future<void> pickEnd() async {
              final t = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60),
              );
              if (t == null) return;
              if (!ctx.mounted) return;
              setLocal(() => endMin = t.hour * 60 + t.minute);
            }

            return AlertDialog(
              title: Text(doc == null ? "Add Weekly class" : "Edit Weekly class"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(hintText: "Course name"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(hintText: "Room (optional)"),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: dayOfWeek,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Sunday")),
                      DropdownMenuItem(value: 2, child: Text("Monday")),
                      DropdownMenuItem(value: 3, child: Text("Tuesday")),
                      DropdownMenuItem(value: 4, child: Text("Wednesday")),
                      DropdownMenuItem(value: 5, child: Text("Thursday")),
                      DropdownMenuItem(value: 6, child: Text("Friday")),
                      DropdownMenuItem(value: 7, child: Text("Saturday")),
                    ],
                    onChanged: (v) => setLocal(() => dayOfWeek = v ?? 1),
                    decoration: const InputDecoration(labelText: "Day"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Start: ${_fmtMin(startMin)}",
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: pickStart,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "End: ${_fmtMin(endMin)}",
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: pickEnd,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.rose,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final room = roomCtrl.text.trim();
                    if (title.isEmpty) return;

                    if (endMin < startMin) {
                      final tmp = startMin;
                      startMin = endMin;
                      endMin = tmp;
                    }

                    final payload = {
                      'type': 'weekly',
                      'title': title,
                      'room': room,
                      'dayOfWeek': dayOfWeek,
                      'startMin': startMin,
                      'endMin': endMin,
                      'updatedAt': FieldValue.serverTimestamp(),
                      'createdAt': data?['createdAt'] ?? FieldValue.serverTimestamp(),
                    };

                    if (doc == null) {
                      await ref.add(payload);
                    } else {
                      await ref.doc(doc.id).update(payload);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDatedDialog({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) {
    final data = doc?.data();

    final titleCtrl = TextEditingController(text: (data?['title'] ?? '').toString());
    final roomCtrl = TextEditingController(text: (data?['room'] ?? '').toString());

    DateTime start = (data?['start'] is Timestamp)
        ? (data!['start'] as Timestamp).toDate()
        : DateTime.now();

    DateTime end = (data?['end'] is Timestamp)
        ? (data!['end'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(doc == null ? "Add Exam / Event" : "Edit Exam / Event"),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Start: ${_fmtDateTime(Timestamp.fromDate(start))}",
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final picked = await _pickDateTime(ctx, start);
                          if (picked != null) setLocal(() => start = picked);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "End: ${_fmtDateTime(Timestamp.fromDate(end))}",
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final picked = await _pickDateTime(ctx, end);
                          if (picked != null) setLocal(() => end = picked);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.rose,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final room = roomCtrl.text.trim();
                    if (title.isEmpty) return;

                    if (end.isBefore(start)) {
                      final tmp = start;
                      start = end;
                      end = tmp;
                    }

                    final payload = {
                      'type': 'dated',
                      'title': title,
                      'room': room,
                      'start': Timestamp.fromDate(start),
                      'end': Timestamp.fromDate(end),
                      'updatedAt': FieldValue.serverTimestamp(),
                      'createdAt': data?['createdAt'] ?? FieldValue.serverTimestamp(),
                    };

                    if (doc == null) {
                      await ref.add({
                        ...payload,
                        'done': false,
                      });
                    } else {
                      await ref.doc(doc.id).update(payload);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _delete(String id) async {
    await ref.doc(id).delete();
  }

  Future<void> _toggleDatedDone(String id, bool done) async {
    await ref.doc(id).update({
      'done': done,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _restoreDated(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final end = data['end'];

    if (end is Timestamp && _datePassed(end)) {
      await _showRestoreExpiredDialog(
        context,
        typeName: "appointment",
        onEdit: () => _showDatedDialog(doc: doc),
      );
      return;
    }

    await _toggleDatedDone(doc.id, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.rose,
        foregroundColor: Colors.white,
        onPressed: _showAddChooser,
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
            stream: ref.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text("Error: ${snap.error}"));
              }

              final docs = snap.data?.docs ?? [];

              final weekly = docs
                  .where((d) => (d.data()['type'] ?? 'weekly').toString() == 'weekly')
                  .toList();

              weekly.sort((a, b) {
                final aw = (a.data()['dayOfWeek'] ?? 1) as int;
                final bw = (b.data()['dayOfWeek'] ?? 1) as int;
                if (aw != bw) return aw.compareTo(bw);
                final am = (a.data()['startMin'] ?? 0) as int;
                final bm = (b.data()['startMin'] ?? 0) as int;
                return am.compareTo(bm);
              });

              final datedAll = docs
                  .where((d) => (d.data()['type'] ?? 'weekly').toString() == 'dated')
                  .toList();

              datedAll.sort((a, b) {
                final as = a.data()['start'];
                final bs = b.data()['start'];
                if (as is Timestamp && bs is Timestamp) {
                  return as.toDate().compareTo(bs.toDate());
                }
                return 0;
              });

              final overdue = datedAll.where((d) => _isOverdueDated(d.data())).toList();
              final active = datedAll.where((d) {
                final data = d.data();
                return !_isOverdueDated(data) && ((data['done'] ?? false) != true);
              }).toList();
              final completed = datedAll.where((d) => (d.data()['done'] ?? false) == true).toList();

              completed.sort((a, b) {
                final ad = a.data()['updatedAt'];
                final bd = b.data()['updatedAt'];
                if (ad is Timestamp && bd is Timestamp) {
                  return bd.toDate().compareTo(ad.toDate());
                }
                return 0;
              });

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
                      const SizedBox(width: 1),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.dark, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Weekly classes",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 10),
                        if (weekly.isEmpty)
                          const Text("No weekly classes",
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        for (final d in weekly) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2B8A8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    _dayName((d.data()['dayOfWeek'] ?? 1) as int),
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (d.data()['title'] ?? '').toString(),
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${_fmtMin((d.data()['startMin'] ?? 0) as int)} → ${_fmtMin((d.data()['endMin'] ?? 0) as int)}"
                                        "${((d.data()['room'] ?? '').toString().trim().isEmpty) ? "" : " · Room: ${(d.data()['room'] ?? '').toString()}"}",
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showWeeklyDialog(doc: d),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () => _delete(d.id),
                                  icon: const Icon(Icons.delete),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.dark, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Exams / Events",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 10),

                        if (overdue.isNotEmpty) ...[
                          const Text("Overdue",
                              style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          for (final d in overdue) ...[
                            _DatedCard(
                              title: (d.data()['title'] ?? '').toString(),
                              subtitle:
                                  "${_fmtDateTime(d.data()['start'])} → ${_fmtDateTime(d.data()['end'])}"
                                  "${((d.data()['room'] ?? '').toString().trim().isEmpty) ? "" : " · Room: ${(d.data()['room'] ?? '').toString()}"}",
                              red: true,
                              showCheck: false,
                              checked: false,
                              onCheck: null,
                              showRestore: false,
                              onRestore: null,
                              onEdit: () => _showDatedDialog(doc: d),
                              onDelete: () => _delete(d.id),
                            ),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 12),
                        ],

                        if (active.isEmpty)
                          const Text("No active dated events",
                              style: TextStyle(fontWeight: FontWeight.w800)),

                        for (final d in active) ...[
                          _DatedCard(
                            title: (d.data()['title'] ?? '').toString(),
                            subtitle:
                                "${_fmtDateTime(d.data()['start'])} → ${_fmtDateTime(d.data()['end'])}"
                                "${((d.data()['room'] ?? '').toString().trim().isEmpty) ? "" : " · Room: ${(d.data()['room'] ?? '').toString()}"}",
                            red: false,
                            showCheck: true,
                            checked: false,
                            onCheck: () => _toggleDatedDone(d.id, true),
                            showRestore: false,
                            onRestore: null,
                            onEdit: () => _showDatedDialog(doc: d),
                            onDelete: () => _delete(d.id),
                          ),
                          const SizedBox(height: 10),
                        ],

                        const SizedBox(height: 12),
                        const Text("Completed",
                            style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),

                        if (completed.isEmpty)
                          const Text("No completed appointments",
                              style: TextStyle(fontWeight: FontWeight.w800)),

                        for (final d in completed) ...[
                          _DatedCard(
                            title: (d.data()['title'] ?? '').toString(),
                            subtitle:
                                "${_fmtDateTime(d.data()['start'])} → ${_fmtDateTime(d.data()['end'])}"
                                "${((d.data()['room'] ?? '').toString().trim().isEmpty) ? "" : " · Room: ${(d.data()['room'] ?? '').toString()}"}",
                            red: false,
                            showCheck: false,
                            checked: false,
                            onCheck: null,
                            showRestore: true,
                            onRestore: () => _restoreDated(context, d),
                            onEdit: () => _showDatedDialog(doc: d),
                            onDelete: () => _delete(d.id),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DatedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool red;

  final bool showCheck;
  final bool checked;
  final VoidCallback? onCheck;

  final bool showRestore;
  final VoidCallback? onRestore;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DatedCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.red,
    required this.showCheck,
    required this.checked,
    required this.onCheck,
    required this.showRestore,
    required this.onRestore,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2B8A8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: red ? AppTheme.overdueRed : AppTheme.dark,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (showCheck)
            GestureDetector(
              onTap: onCheck,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: red ? AppTheme.overdueRed : AppTheme.dark,
                    width: 2,
                  ),
                ),
                child: checked ? const Icon(Icons.check, size: 14) : null,
              ),
            ),
          if (showCheck) const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: red ? AppTheme.overdueRed : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: red ? AppTheme.overdueRed : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          if (showRestore)
            IconButton(
              tooltip: "Restore",
              onPressed: onRestore,
              icon: const Icon(Icons.undo),
            ),

          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit, color: red ? AppTheme.overdueRed : Colors.black87),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete, color: red ? AppTheme.overdueRed : Colors.black87),
          ),
        ],
      ),
    );
  }
}