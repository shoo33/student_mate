import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../app_text.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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

  String _fmt(DateTime d) {
    int h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    h %= 12;
    if (h == 0) h = 12;
    return '$h:$m$ampm';
  }

  String _monthName(int month, AppText t) {
    if (t.isArabic) {
      const months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      return months[month - 1];
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _fmtDue(Timestamp ts, AppText t) {
    final d = ts.toDate();
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd ${_monthName(d.month, t)} · ${_fmt(d)}';
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
    final t = AppText(Localizations.localeOf(context).languageCode);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.dateExpired),
          content: Text(
            t.dateExpiredMessage(typeName),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.close),
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
              child: Text(t.editDate),
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
    final t = AppText(Localizations.localeOf(context).languageCode);
    final titleCtrl = TextEditingController(text: initialTitle);
    DateTime? due = initialDue?.toDate();

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(docId == null ? t.addTask : t.editTask),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(labelText: t.title),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          due == null ? t.noDeadline : _fmtDue(Timestamp.fromDate(due!), t),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: t.pickDeadline,
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
                  child: Text(t.cancel),
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
                      _toast(context, t.taskSaved);
                    } else {
                      await _tasksRef.doc(docId).update({
                        'title': title,
                        'dueAt': due == null ? null : Timestamp.fromDate(due!),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      _toast(context, t.taskUpdated);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(t.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleDone(BuildContext context, String id, bool done) async {
    final t = AppText(Localizations.localeOf(context).languageCode);

    await _tasksRef.doc(id).update({
      'done': done,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (done) {
      _toast(context, t.markedCompleted);
    }
  }

  Future<void> _delete(BuildContext context, String id) async {
    final t = AppText(Localizations.localeOf(context).languageCode);
    await _tasksRef.doc(id).delete();
    _toast(context, t.taskDeleted);
  }

  Future<void> _restoreTask(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final t = AppText(Localizations.localeOf(context).languageCode);
    final data = doc.data();
    final due = data['dueAt'];

    if (due is Timestamp && _datePassed(due)) {
      await _showRestoreExpiredDialog(
        context,
        typeName: t.isArabic ? "المهمة" : "task",
        onEdit: () => _addOrEditDialog(
          context,
          docId: doc.id,
          initialTitle: (data['title'] ?? '').toString(),
          initialDue: due,
        ),
      );
      return;
    }

    await _tasksRef.doc(doc.id).update({
      'done': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _toast(context, t.taskRestored);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppText(Localizations.localeOf(context).languageCode);
    final pageTop = AppTheme.pageTop(context);
    final pageBottom = AppTheme.pageBottom(context);
    final cardColor = AppTheme.cardColor(context);
    final textColor = AppTheme.textPrimary(context);
    final mutedText = AppTheme.textMuted(context);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.rose,
        foregroundColor: Colors.white,
        onPressed: () => _addOrEditDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [pageTop, pageBottom],
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
                  Text(
                    t.tasks,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (overdue.isNotEmpty) ...[
                    Text(
                      t.overdue,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final d in overdue) ...[
                      _TaskCard(
                        title: (d.data()['title'] ?? '').toString(),
                        rightText: _fmtDue(d.data()['dueAt'], t),
                        rightColor: AppTheme.overdueRed,
                        showCheck: false,
                        showRestore: false,
                        onEdit: () => _addOrEditDialog(
                          context,
                          docId: d.id,
                          initialTitle: (d.data()['title'] ?? '').toString(),
                          initialDue: d.data()['dueAt'],
                        ),
                        onDelete: () => _delete(context, d.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                  ],
                  Text(
                    t.active,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (active.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: Text(
                        t.noTasks,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  for (final d in [...upcoming, ...noDue]) ...[
                    _TaskCard(
                      title: (d.data()['title'] ?? '').toString(),
                      rightText: (d.data()['dueAt'] is Timestamp)
                          ? _fmtDue(d.data()['dueAt'], t)
                          : null,
                      rightColor: mutedText,
                      showCheck: true,
                      onCheck: () => _toggleDone(context, d.id, true),
                      showRestore: false,
                      onEdit: () => _addOrEditDialog(
                        context,
                        docId: d.id,
                        initialTitle: (d.data()['title'] ?? '').toString(),
                        initialDue: d.data()['dueAt'],
                      ),
                      onDelete: () => _delete(context, d.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    t.completed,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (completed.isEmpty)
                    Text(
                      t.noCompletedTasks,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: mutedText,
                      ),
                    ),
                  for (final d in completed) ...[
                    _TaskCard(
                      title: (d.data()['title'] ?? '').toString(),
                      rightText: (d.data()['dueAt'] is Timestamp)
                          ? _fmtDue(d.data()['dueAt'], t)
                          : null,
                      rightColor: mutedText,
                      showCheck: false,
                      showRestore: true,
                      restoreTooltip: t.restore,
                      onRestore: () => _restoreTask(context, d),
                      onEdit: () => _addOrEditDialog(
                        context,
                        docId: d.id,
                        initialTitle: (d.data()['title'] ?? '').toString(),
                        initialDue: d.data()['dueAt'],
                      ),
                      onDelete: () => _delete(context, d.id),
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
  final String? restoreTooltip;
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
    this.restoreTooltip,
    this.onRestore,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textPrimary(context);
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
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
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.70)
                        : AppTheme.dark,
                    width: 2,
                  ),
                ),
                child: checked
                    ? Icon(Icons.check, size: 14, color: textColor)
                    : null,
              ),
            ),
          if (showCheck) const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
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
              tooltip: restoreTooltip,
              onPressed: onRestore,
              icon: Icon(Icons.undo, color: textColor),
            ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit, color: textColor),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete, color: textColor),
          ),
        ],
      ),
    );
  }
}