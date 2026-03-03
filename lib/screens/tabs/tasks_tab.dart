import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');

  static const Color _tileColor = Color(0xFFE4B8AC);

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

  Future<void> _addTask(BuildContext context) async {
    final titleCtrl = TextEditingController();
    bool hasDeadline = false;
    DateTime deadline = DateTime.now().add(const Duration(days: 1));

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Add task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(hintText: "Task title"),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Add deadline"),
                value: hasDeadline,
                onChanged: (v) => setLocal(() => hasDeadline = v),
              ),
              if (hasDeadline) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fmtDue(deadline),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.event),
                      onPressed: () async {
                        final picked = await _pickDateTime(context, deadline);
                        if (picked != null) setLocal(() => deadline = picked);
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
                if (title.isEmpty) return;

                final payload = <String, dynamic>{
                  'title': title,
                  'done': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (hasDeadline) {
                  payload['dueAt'] = Timestamp.fromDate(deadline);
                }

                await _tasksRef.add(payload);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTask(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final titleCtrl = TextEditingController(text: (data['title'] ?? '').toString());

    bool hasDeadline = data['dueAt'] is Timestamp;
    DateTime deadline = hasDeadline
        ? (data['dueAt'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 1));

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Edit task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: "Task title")),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Add deadline"),
                value: hasDeadline,
                onChanged: (v) => setLocal(() => hasDeadline = v),
              ),
              if (hasDeadline) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(_fmtDue(deadline), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.event),
                      onPressed: () async {
                        final picked = await _pickDateTime(context, deadline);
                        if (picked != null) setLocal(() => deadline = picked);
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
                if (title.isEmpty) return;

                final payload = <String, dynamic>{
                  'title': title,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (hasDeadline) {
                  payload['dueAt'] = Timestamp.fromDate(deadline);
                } else {
                  payload['dueAt'] = FieldValue.delete();
                }

                await _tasksRef.doc(doc.id).update(payload);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDone(String id, bool done) async {
    await _tasksRef.doc(id).update({
      'done': done,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _delete(String id) async {
    await _tasksRef.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context),
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
            stream: _tasksRef.orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

              final docs = snapshot.data?.docs ?? [];

              final upcoming = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final noDeadline = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final expired = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final completed = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              for (final d in docs) {
                final data = d.data();
                final done = (data['done'] ?? false) == true;
                final due = data['dueAt'];

                if (done) {
                  completed.add(d);
                  continue;
                }

                if (due is Timestamp) {
                  final dueDate = due.toDate();
                  if (dueDate.isBefore(now)) {
                    expired.add(d);
                  } else {
                    upcoming.add(d);
                  }
                } else {
                  noDeadline.add(d);
                }
              }

              // Sorting
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

              expired.sort((a, b) {
                final aD = (a.data()['dueAt'] as Timestamp).toDate();
                final bD = (b.data()['dueAt'] as Timestamp).toDate();
                return bD.compareTo(aD);
              });

              completed.sort((a, b) {
                final aU = a.data()['updatedAt'];
                final bU = b.data()['updatedAt'];
                final aDate = aU is Timestamp ? aU.toDate() : DateTime(2000);
                final bDate = bU is Timestamp ? bU.toDate() : DateTime(2000);
                return bDate.compareTo(aDate);
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  const Text("Tasks", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),

                  // Upcoming
                  const Text("Upcoming", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (upcoming.isEmpty) _InfoBox(text: "No upcoming tasks.", color: _tileColor),
                  for (final d in upcoming) ...[
                    _TaskTileActive(
                      color: _tileColor,
                      title: (d.data()['title'] ?? '').toString(),
                      dueAt: d.data()['dueAt'],
                      fmtDue: _fmtDue,
                      onDone: () => _setDone(d.id, true),
                      onEdit: () => _editTask(context, d),
                      onDelete: () => _delete(d.id),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 14),

                  // No deadline
                  const Text("No deadline", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (noDeadline.isEmpty) _InfoBox(text: "No tasks here.", color: _tileColor),
                  for (final d in noDeadline) ...[
                    _TaskTileActive(
                      color: _tileColor,
                      title: (d.data()['title'] ?? '').toString(),
                      dueAt: null,
                      fmtDue: _fmtDue,
                      onDone: () => _setDone(d.id, true),
                      onEdit: () => _editTask(context, d),
                      onDelete: () => _delete(d.id),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 14),

                  // Expired (Delete only)
                  const Text("Expired", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (expired.isEmpty) _InfoBox(text: "No expired tasks.", color: _tileColor),
                  for (final d in expired) ...[
                    _TaskTileExpiredDeleteOnly(
                      color: _tileColor,
                      title: (d.data()['title'] ?? '').toString(),
                      dueAt: d.data()['dueAt'],
                      fmtDue: _fmtDue,
                      onDelete: () => _delete(d.id),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 14),

                  // ✅ Completed
                  const Text("Completed", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (completed.isEmpty) _InfoBox(text: "No completed tasks.", color: _tileColor),
                  for (final d in completed) ...[
                    _TaskTileCompleted(
                      color: _tileColor,
                      title: (d.data()['title'] ?? '').toString(),
                      dueAt: d.data()['dueAt'],
                      fmtDue: _fmtDue,
                      onUndo: () => _setDone(d.id, false),
                      onDelete: () => _delete(d.id),
                    ),
                    const SizedBox(height: 12),
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

class _InfoBox extends StatelessWidget {
  final String text;
  final Color color;
  const _InfoBox({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _TaskTileActive extends StatelessWidget {
  final Color color;
  final String title;
  final dynamic dueAt; // Timestamp? أو null
  final String Function(DateTime) fmtDue;
  final VoidCallback onDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskTileActive({
    required this.color,
    required this.title,
    required this.dueAt,
    required this.fmtDue,
    required this.onDone,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDue = dueAt is Timestamp;
    final dueDate = hasDue ? (dueAt as Timestamp).toDate() : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Row(
        children: [
          GestureDetector(onTap: onDone, child: const Icon(Icons.radio_button_unchecked)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                if (hasDue) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Deadline: ${fmtDue(dueDate!)}",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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

class _TaskTileExpiredDeleteOnly extends StatelessWidget {
  final Color color;
  final String title;
  final dynamic dueAt;
  final String Function(DateTime) fmtDue;
  final VoidCallback onDelete;

  const _TaskTileExpiredDeleteOnly({
    required this.color,
    required this.title,
    required this.dueAt,
    required this.fmtDue,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = (dueAt as Timestamp).toDate();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  "Expired: ${fmtDue(dueDate)}",
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.red),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }
}

class _TaskTileCompleted extends StatelessWidget {
  final Color color;
  final String title;
  final dynamic dueAt;
  final String Function(DateTime) fmtDue;
  final VoidCallback onUndo;
  final VoidCallback onDelete;

  const _TaskTileCompleted({
    required this.color,
    required this.title,
    required this.dueAt,
    required this.fmtDue,
    required this.onUndo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDue = dueAt is Timestamp;
    final dueDate = hasDue ? (dueAt as Timestamp).toDate() : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.lineThrough,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasDue) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Deadline: ${fmtDue(dueDate!)}",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: "Undo",
            onPressed: onUndo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }
}