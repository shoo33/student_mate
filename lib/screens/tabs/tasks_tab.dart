import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');

  // ---------- Pick DateTime (optional dueAt) ----------
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

  // ---------- Add Task (dueAt optional) ----------
  Future<void> _addTask(BuildContext context) async {
    final c = TextEditingController();
    DateTime? dueAt;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Add Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c,
                decoration: const InputDecoration(hintText: "Enter task"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dueAt == null ? "No due date" : "Due: ${_fmtDue(dueAt!)}",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: "Pick due date",
                    icon: const Icon(Icons.event),
                    onPressed: () async {
                      final picked = await _pickDateTime(
                        context,
                        dueAt ?? DateTime.now().add(const Duration(hours: 1)),
                      );
                      if (picked != null) setLocal(() => dueAt = picked);
                    },
                  ),
                  if (dueAt != null)
                    IconButton(
                      tooltip: "Remove due date",
                      icon: const Icon(Icons.close),
                      onPressed: () => setLocal(() => dueAt = null),
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
                final text = c.text.trim();
                if (text.isEmpty) return;

                await _tasksRef.add({
                  'title': text,
                  'done': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'dueAt': dueAt == null ? null : Timestamp.fromDate(dueAt!),
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    await _tasksRef.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
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
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final docs = snapshot.data?.docs ?? [];

              // Sort: undone first, then dueAt soonest, then no dueAt
              docs.sort((a, b) {
                final aDone = (a.data()['done'] ?? false) == true;
                final bDone = (b.data()['done'] ?? false) == true;
                if (aDone != bDone) return aDone ? 1 : -1;

                final aDue = a.data()['dueAt'];
                final bDue = b.data()['dueAt'];

                if (aDue is Timestamp && bDue is Timestamp) {
                  return aDue.toDate().compareTo(bDue.toDate());
                }
                if (aDue is Timestamp) return -1;
                if (bDue is Timestamp) return 1;

                return 0;
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  const Text(
                    "Your tasks",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),

                  if (docs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: const Text(
                        "No tasks yet.\nTap + to add one.",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),

                  for (final d in docs) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (d.data()['done'] ?? false) == true
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (d.data()['title'] ?? '').toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    decoration: ((d.data()['done'] ?? false) == true)
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (_) {
                                    final due = d.data()['dueAt'];
                                    if (due is! Timestamp) return const SizedBox.shrink();
                                    return Text(
                                      "Due: ${_fmtDue(due.toDate())}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _delete(d.id),
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
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