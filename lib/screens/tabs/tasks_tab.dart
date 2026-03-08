import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');

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

  String _fmt(DateTime d) {
    int h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    h %= 12;
    if (h == 0) h = 12;
    return '$h:$m$ampm';
  }

  String _fmtDue(Timestamp ts) {
    final d = ts.toDate();
    final dd = d.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '$dd ${months[d.month - 1]} · ${_fmt(d)}';
  }

  bool _isOverdue(Map<String, dynamic> t) {
    final done = (t['done'] ?? false) == true;
    if (done) return false;
    final due = t['dueAt'];
    if (due is! Timestamp) return false;
    return due.toDate().isBefore(DateTime.now());
  }

  bool _datePassed(Timestamp? due) {
    if (due == null) return false;
    return due.toDate().isBefore(DateTime.now());
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

  Future<void> _addOrEditDialog(
    BuildContext context, {
    String? docId,
    String initialTitle = '',
    Timestamp? initialDue,
  }) async {
    final titleCtrl = TextEditingController(text: initialTitle);
    DateTime? due = initialDue?.toDate();

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(docId == null ? "Add Task" : "Edit Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          due == null ? "No deadline" : _fmtDue(Timestamp.fromDate(due!)),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: "Pick deadline",
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final picked = await _pickDateTime(ctx, due ?? DateTime.now());
                          if (picked != null) {
                            setLocal(() => due = picked);
                          }
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
                    if (title.isEmpty) return;

                    if (docId == null) {
                      await _tasksRef.add({
                        'title': title,
                        'done': false,
                        'dueAt': due == null ? null : Timestamp.fromDate(due!),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await _tasksRef.doc(docId).update({
                        'title': title,
                        'dueAt': due == null ? null : Timestamp.fromDate(due!),
                        'updatedAt': FieldValue.serverTimestamp(),
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

  Future<void> _toggleDone(String id, bool done) async {
    await _tasksRef.doc(id).update({
      'done': done,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _delete(String id) async {
    await _tasksRef.doc(id).delete();
  }

  Future<void> _restoreTask(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final due = data['dueAt'];

    if (due is Timestamp && _datePassed(due)) {
      await _showRestoreExpiredDialog(
        context,
        typeName: "task",
        onEdit: () => _addOrEditDialog(
          context,
          docId: doc.id,
          initialTitle: (data['title'] ?? '').toString(),
          initialDue: due,
        ),
      );
      return;
    }

    await _toggleDone(doc.id, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.rose,
        foregroundColor: Colors.white,
        onPressed: () => _addOrEditDialog(context),
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
            stream: _tasksRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final docs = snapshot.data?.docs ?? [];

              final active = docs.where((d) => (d.data()['done'] ?? false) != true).toList();
              final completed = docs.where((d) => (d.data()['done'] ?? false) == true).toList();

              final withDue = active.where((d) => d.data()['dueAt'] is Timestamp).toList();
              final noDue = active.where((d) => d.data()['dueAt'] is! Timestamp).toList();

              withDue.sort((a, b) {
                final ad = (a.data()['dueAt'] as Timestamp).toDate();
                final bd = (b.data()['dueAt'] as Timestamp).toDate();
                return ad.compareTo(bd);
              });

              noDue.sort((a, b) {
                final ac = a.data()['createdAt'];
                final bc = b.data()['createdAt'];
                if (ac is Timestamp && bc is Timestamp) {
                  return bc.toDate().compareTo(ac.toDate());
                }
                return 0;
              });

              final overdue = withDue.where((d) => _isOverdue(d.data())).toList();
              final upcoming = withDue.where((d) => !_isOverdue(d.data())).toList();

              completed.sort((a, b) {
                final ad = a.data()['updatedAt'];
                final bd = b.data()['updatedAt'];
                if (ad is Timestamp && bd is Timestamp) {
                  return bd.toDate().compareTo(ad.toDate());
                }
                return 0;
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  const Text(
                    "Tasks",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),

                  if (overdue.isNotEmpty) ...[
                    const Text("Overdue",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    for (final d in overdue) ...[
                      _TaskCard(
                        title: (d.data()['title'] ?? '').toString(),
                        rightText: _fmtDue(d.data()['dueAt']),
                        rightColor: AppTheme.overdueRed,
                        showCheck: false,
                        showRestore: false,
                        onEdit: () => _addOrEditDialog(
                          context,
                          docId: d.id,
                          initialTitle: (d.data()['title'] ?? '').toString(),
                          initialDue: d.data()['dueAt'],
                        ),
                        onDelete: () => _delete(d.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                  ],

                  const Text("Active",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 8),

                  if (active.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: const Text(
                        "No tasks",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                  for (final d in [...upcoming, ...noDue]) ...[
                    _TaskCard(
                      title: (d.data()['title'] ?? '').toString(),
                      rightText: (d.data()['dueAt'] is Timestamp) ? _fmtDue(d.data()['dueAt']) : null,
                      rightColor: Colors.black87,
                      showCheck: true,
                      onCheck: () => _toggleDone(d.id, true),
                      showRestore: false,
                      onEdit: () => _addOrEditDialog(
                        context,
                        docId: d.id,
                        initialTitle: (d.data()['title'] ?? '').toString(),
                        initialDue: d.data()['dueAt'],
                      ),
                      onDelete: () => _delete(d.id),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 16),
                  const Text("Completed",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 8),

                  if (completed.isEmpty)
                    const Text("No completed tasks",
                        style: TextStyle(fontWeight: FontWeight.w700)),

                  for (final d in completed) ...[
                    _TaskCard(
                      title: (d.data()['title'] ?? '').toString(),
                      rightText: (d.data()['dueAt'] is Timestamp) ? _fmtDue(d.data()['dueAt']) : null,
                      rightColor: Colors.black87,
                      showCheck: false,
                      showRestore: true,
                      onRestore: () => _restoreTask(context, d),
                      onEdit: () => _addOrEditDialog(
                        context,
                        docId: d.id,
                        initialTitle: (d.data()['title'] ?? '').toString(),
                        initialDue: d.data()['dueAt'],
                      ),
                      onDelete: () => _delete(d.id),
                    ),
                    const SizedBox(height: 10),
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

class _TaskCard extends StatelessWidget {
  final String title;
  final String? rightText;
  final Color rightColor;

  final bool showCheck;
  final bool checked;
  final VoidCallback? onCheck;

  final bool showRestore;
  final VoidCallback? onRestore;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    super.key,
    required this.title,
    required this.rightText,
    required this.rightColor,
    required this.showCheck,
    this.checked = false,
    this.onCheck,
    required this.showRestore,
    this.onRestore,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
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
                  border: Border.all(color: AppTheme.dark, width: 2),
                ),
                child: checked ? const Icon(Icons.check, size: 14) : null,
              ),
            ),
          if (showCheck) const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (rightText != null) ...[
            const SizedBox(width: 10),
            Text(
              rightText!,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: rightColor,
              ),
            ),
          ],

          const SizedBox(width: 6),

          if (showRestore)
            IconButton(
              tooltip: "Restore",
              onPressed: onRestore,
              icon: const Icon(Icons.undo),
            ),

          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}