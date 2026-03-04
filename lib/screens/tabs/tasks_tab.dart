import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');

  static const Color _cardColor = Color(0xFFE4B8AC);

  // ---------- helpers ----------
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

  // ---------- firestore actions ----------
  Future<void> _setDone(String id, bool v) async {
    await _tasksRef.doc(id).update({
      'done': v,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _delete(String id) async {
    await _tasksRef.doc(id).delete();
  }

  // ---------- dialogs ----------
  Future<void> _addTask(BuildContext context) async {
    final titleCtrl = TextEditingController();
    bool hasDeadline = false;
    DateTime due = DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Add Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Title",
                ),
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Deadline"),
                value: hasDeadline,
                onChanged: (v) => setLocal(() => hasDeadline = v),
              ),

              if (hasDeadline)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fmtDT(due),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await _pickDateTime(context, due);
                        if (picked != null) setLocal(() => due = picked);
                      },
                      child: const Text("Choose"),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final t = titleCtrl.text.trim();
                if (t.isEmpty) return;

                await _tasksRef.add({
                  'title': t,
                  'done': false,
                  'dueAt': hasDeadline ? Timestamp.fromDate(due) : null,
                  'createdAt': FieldValue.serverTimestamp(),
                });

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
    DateTime due = hasDeadline ? (data['dueAt'] as Timestamp).toDate() : DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Deadline"),
                value: hasDeadline,
                onChanged: (v) => setLocal(() => hasDeadline = v),
              ),

              if (hasDeadline)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fmtDT(due),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await _pickDateTime(context, due);
                        if (picked != null) setLocal(() => due = picked);
                      },
                      child: const Text("Choose"),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final t = titleCtrl.text.trim();
                if (t.isEmpty) return;

                await _tasksRef.doc(doc.id).update({
                  'title': t,
                  'dueAt': hasDeadline ? Timestamp.fromDate(due) : null,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI ----------
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
    );
  }

  Widget _cardWrap(Widget child) {
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

  Widget _taskRow({
    required String title,
    String subtitle = "",
    bool subtitleRed = false,
    bool showCheck = true,
    bool checked = false,
    VoidCallback? onToggle,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Row(
      children: [
        if (showCheck)
          GestureDetector(
            onTap: onToggle,
            child: Icon(checked ? Icons.check_circle : Icons.radio_button_unchecked),
          )
        else
          const SizedBox(width: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: subtitleRed ? Colors.red : null,
                  ),
                )
              ]
            ],
          ),
        ),
        if (onEdit != null) IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
        if (onDelete != null) IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
      ],
    );
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
            stream: _tasksRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final all = snapshot.data?.docs ?? [];

              final active = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final expired = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final completed = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              for (final d in all) {
                final data = d.data();
                final done = (data['done'] ?? false) == true;

                final due = data['dueAt'];
                final hasDue = due is Timestamp;
                final isExpired = hasDue && due.toDate().isBefore(now) && !done;

                if (done) {
                  completed.add(d);
                } else if (isExpired) {
                  expired.add(d);
                } else {
                  active.add(d);
                }
              }

              int sortByDue(a, b) {
                final aDue = a.data()['dueAt'];
                final bDue = b.data()['dueAt'];
                final aHas = aDue is Timestamp;
                final bHas = bDue is Timestamp;
                if (aHas && bHas) return aDue.toDate().compareTo(bDue.toDate());
                if (aHas && !bHas) return -1;
                if (!aHas && bHas) return 1;
                return 0;
              }

              active.sort(sortByDue);
              expired.sort(sortByDue);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  const Text("Tasks", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),

                  _sectionTitle("Active"),
                  _cardWrap(
                    Column(
                      children: [
                        if (active.isEmpty)
                          const Text("No active tasks.", style: TextStyle(fontWeight: FontWeight.w800))
                        else
                          for (int i = 0; i < active.length; i++) ...[
                            _taskRow(
                              title: (active[i].data()['title'] ?? '').toString(),
                              subtitle: (active[i].data()['dueAt'] is Timestamp)
                                  ? "Deadline: ${_fmtDT((active[i].data()['dueAt'] as Timestamp).toDate())}"
                                  : "",
                              showCheck: true,
                              checked: false,
                              onToggle: () => _setDone(active[i].id, true),
                              onEdit: () => _editTask(context, active[i]),
                              onDelete: () => _delete(active[i].id),
                            ),
                            if (i != active.length - 1) const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  _sectionTitle("Expired"),
                  _cardWrap(
                    Column(
                      children: [
                        if (expired.isEmpty)
                          const Text("No expired tasks.", style: TextStyle(fontWeight: FontWeight.w800))
                        else
                          for (int i = 0; i < expired.length; i++) ...[
                            _taskRow(
                              title: (expired[i].data()['title'] ?? '').toString(),
                              subtitle: (expired[i].data()['dueAt'] is Timestamp)
                                  ? "Deadline: ${_fmtDT((expired[i].data()['dueAt'] as Timestamp).toDate())}"
                                  : "",
                              subtitleRed: true,
                              showCheck: false, // no checkbox
                              onEdit: null,
                              onDelete: () => _delete(expired[i].id),
                            ),
                            if (i != expired.length - 1) const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  _sectionTitle("Completed"),
                  _cardWrap(
                    Column(
                      children: [
                        if (completed.isEmpty)
                          const Text("No completed tasks yet.", style: TextStyle(fontWeight: FontWeight.w800))
                        else
                          for (int i = 0; i < completed.length; i++) ...[
                            _taskRow(
                              title: (completed[i].data()['title'] ?? '').toString(),
                              subtitle: (completed[i].data()['dueAt'] is Timestamp)
                                  ? "Deadline: ${_fmtDT((completed[i].data()['dueAt'] as Timestamp).toDate())}"
                                  : "",
                              showCheck: true,
                              checked: true,
                              onToggle: () => _setDone(completed[i].id, false),
                              onEdit: () => _editTask(context, completed[i]),
                              onDelete: () => _delete(completed[i].id),
                            ),
                            if (i != completed.length - 1) const SizedBox(height: 10),
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