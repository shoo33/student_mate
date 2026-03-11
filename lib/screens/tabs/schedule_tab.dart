import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../app_text.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get ref =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('schedules');

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('app');

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _dayName(int d, AppText t) => t.shortDay(d);

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

  String _fmtDateTime(Timestamp ts, AppText t) {
    final d = ts.toDate();
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd ${_monthName(d.month, t)} · ${_fmt(d)}';
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

  int _notifIdFromDocId(String docId) {
    return docId.hashCode & 0x7fffffff;
  }

  Future<Map<String, dynamic>> _settingsData() async {
    final snap = await _settingsDoc.get();
    return snap.data() ?? {};
  }

  Future<bool> _notificationsEnabled() async {
    final data = await _settingsData();
    return (data['notificationsEnabled'] ?? true) == true;
  }

  Future<int> _reminderMinutes() async {
    final data = await _settingsData();
    return (data['reminderMinutes'] ?? 30) as int;
  }

  Future<void> _scheduleReminderForDoc({
    required String docId,
    required String title,
    required DateTime start,
  }) async {
    if (!await _notificationsEnabled()) return;

    final reminderMinutes = await _reminderMinutes();

    await NotificationService.instance.scheduleAppointmentReminder(
      id: _notifIdFromDocId(docId),
      title: title,
      eventStart: start,
      reminderMinutes: reminderMinutes,
      body: title,
    );
  }

  Future<void> _cancelReminderForDoc(String docId) async {
    await NotificationService.instance.cancelById(_notifIdFromDocId(docId));
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

  void _showAddChooser() {
    final t = AppText(Localizations.localeOf(context).languageCode);

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

    Future<void> pickWeeklyStart(
      BuildContext ctx,
      void Function(void Function()) setLocal,
    ) async {
      final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay(hour: wStartMin ~/ 60, minute: wStartMin % 60),
      );
      if (time == null) return;
      if (!ctx.mounted) return;
      setLocal(() => wStartMin = time.hour * 60 + time.minute);
    }

    Future<void> pickWeeklyEnd(
      BuildContext ctx,
      void Function(void Function()) setLocal,
    ) async {
      final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay(hour: wEndMin ~/ 60, minute: wEndMin % 60),
      );
      if (time == null) return;
      if (!ctx.mounted) return;
      setLocal(() => wEndMin = time.hour * 60 + time.minute);
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
              title: Text(t.add),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        tabBtn(t.weekly, 0),
                        const SizedBox(width: 10),
                        tabBtn(t.appointments, 1),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (tab == 0) ...[
                      TextField(
                        controller: wTitle,
                        decoration: InputDecoration(labelText: t.course),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: wRoom,
                        decoration: InputDecoration(
                          labelText: t.isArabic ? "القاعة (اختياري)" : "Room (optional)",
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: wDay,
                        items: [
                          DropdownMenuItem(value: 1, child: Text(t.sunday)),
                          DropdownMenuItem(value: 2, child: Text(t.monday)),
                          DropdownMenuItem(value: 3, child: Text(t.tuesday)),
                          DropdownMenuItem(value: 4, child: Text(t.wednesday)),
                          DropdownMenuItem(value: 5, child: Text(t.thursday)),
                          DropdownMenuItem(value: 6, child: Text(t.friday)),
                          DropdownMenuItem(value: 7, child: Text(t.saturday)),
                        ],
                        onChanged: (v) => setLocal(() => wDay = v ?? 1),
                        decoration: InputDecoration(labelText: t.day),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${t.start}: ${_fmtMin(wStartMin)}",
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
                              "${t.end}: ${_fmtMin(wEndMin)}",
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
                        decoration: InputDecoration(labelText: t.title),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: eRoom,
                        decoration: InputDecoration(
                          labelText: t.isArabic ? "القاعة (اختياري)" : "Room (optional)",
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${t.start}: ${_fmtDateTime(Timestamp.fromDate(eStart), t)}",
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
                              "${t.end}: ${_fmtDateTime(Timestamp.fromDate(eEnd), t)}",
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
                      _toast(t.weeklyClassSaved);
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

                      final doc = await ref.add({
                        'type': 'dated',
                        'title': title,
                        'room': eRoom.text.trim(),
                        'start': Timestamp.fromDate(start),
                        'end': Timestamp.fromDate(end),
                        'done': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      await _scheduleReminderForDoc(
                        docId: doc.id,
                        title: title,
                        start: start,
                      );
                      _toast(t.appointmentSaved);
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

  void _showWeeklyDialog({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) {
    final t = AppText(Localizations.localeOf(context).languageCode);
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
              final picked = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60),
              );
              if (picked == null) return;
              if (!ctx.mounted) return;
              setLocal(() => startMin = picked.hour * 60 + picked.minute);
            }

            Future<void> pickEnd() async {
              final picked = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60),
              );
              if (picked == null) return;
              if (!ctx.mounted) return;
              setLocal(() => endMin = picked.hour * 60 + picked.minute);
            }

            return AlertDialog(
              title: Text(doc == null ? t.addWeeklyClass : t.editWeeklyClass),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(hintText: t.course),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: roomCtrl,
                      decoration: InputDecoration(
                        hintText: t.isArabic ? "القاعة (اختياري)" : "Room (optional)",
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: dayOfWeek,
                      items: [
                        DropdownMenuItem(value: 1, child: Text(t.sunday)),
                        DropdownMenuItem(value: 2, child: Text(t.monday)),
                        DropdownMenuItem(value: 3, child: Text(t.tuesday)),
                        DropdownMenuItem(value: 4, child: Text(t.wednesday)),
                        DropdownMenuItem(value: 5, child: Text(t.thursday)),
                        DropdownMenuItem(value: 6, child: Text(t.friday)),
                        DropdownMenuItem(value: 7, child: Text(t.saturday)),
                      ],
                      onChanged: (v) => setLocal(() => dayOfWeek = v ?? 1),
                      decoration: InputDecoration(labelText: t.day),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${t.start}: ${_fmtMin(startMin)}",
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
                            "${t.end}: ${_fmtMin(endMin)}",
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
                      _toast(t.weeklyClassSaved);
                    } else {
                      await ref.doc(doc.id).update(payload);
                      _toast(t.weeklyClassUpdated);
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

  void _showDatedDialog({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) {
    final t = AppText(Localizations.localeOf(context).languageCode);
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
              title: Text(doc == null ? t.addExamEvent : t.editExamEvent),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(hintText: t.title),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: roomCtrl,
                      decoration: InputDecoration(
                        hintText: t.isArabic ? "القاعة (اختياري)" : "Room (optional)",
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${t.start}: ${_fmtDateTime(Timestamp.fromDate(start), t)}",
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
                            "${t.end}: ${_fmtDateTime(Timestamp.fromDate(end), t)}",
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
                      final created = await ref.add({
                        ...payload,
                        'done': false,
                      });

                      await _scheduleReminderForDoc(
                        docId: created.id,
                        title: title,
                        start: start,
                      );
                      _toast(t.appointmentSaved);
                    } else {
                      await ref.doc(doc.id).update(payload);
                      await _cancelReminderForDoc(doc.id);
                      await _scheduleReminderForDoc(
                        docId: doc.id,
                        title: title,
                        start: start,
                      );
                      _toast(t.appointmentUpdated);
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

  Future<void> _delete(String id) async {
    final t = AppText(Localizations.localeOf(context).languageCode);
    await _cancelReminderForDoc(id);
    await ref.doc(id).delete();
    _toast(t.appointmentDeleted);
  }

  Future<void> _toggleDatedDone(String id, bool done) async {
    final t = AppText(Localizations.localeOf(context).languageCode);

    await ref.doc(id).update({
      'done': done,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (done) {
      await _cancelReminderForDoc(id);
      _toast(t.markedCompleted);
    }
  }

  Future<void> _restoreDated(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final t = AppText(Localizations.localeOf(context).languageCode);
    final data = doc.data();
    final end = data['end'];

    if (end is Timestamp && _datePassed(end)) {
      await _showRestoreExpiredDialog(
        context,
        typeName: t.appointmentWord,
        onEdit: () => _showDatedDialog(doc: doc),
      );
      return;
    }

    await _toggleDatedDone(doc.id, false);

    final start = data['start'];
    if (start is Timestamp) {
      await _scheduleReminderForDoc(
        docId: doc.id,
        title: (data['title'] ?? '').toString(),
        start: start.toDate(),
      );
    }
    _toast(t.appointmentRestored);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppText(Localizations.localeOf(context).languageCode);
    final pageTop = AppTheme.pageTop(context);
    final pageBottom = AppTheme.pageBottom(context);
    final cardColor = AppTheme.cardColor(context);
    final textColor = AppTheme.textPrimary(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.rose,
        foregroundColor: Colors.white,
        onPressed: _showAddChooser,
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
                final asValue = a.data()['start'];
                final bsValue = b.data()['start'];
                if (asValue is Timestamp && bsValue is Timestamp) {
                  return asValue.toDate().compareTo(bsValue.toDate());
                }
                return 0;
              });

              final overdue = datedAll.where((d) => _isOverdueDated(d.data())).toList();
              final active = datedAll.where((d) {
                final data = d.data();
                return !_isOverdueDated(data) && ((data['done'] ?? false) != true);
              }).toList();
              final completed =
                  datedAll.where((d) => (d.data()['done'] ?? false) == true).toList();

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
                  Text(
                    t.schedule,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.dark, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.weeklyClasses,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (weekly.isEmpty)
                          Text(
                            t.noWeeklyClasses,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        for (final d in weekly) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.softCardColor(context),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    _dayName((d.data()['dayOfWeek'] ?? 1) as int, t),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (d.data()['title'] ?? '').toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${_fmtMin((d.data()['startMin'] ?? 0) as int)} → ${_fmtMin((d.data()['endMin'] ?? 0) as int)}"
                                        "${((d.data()['room'] ?? '').toString().trim().isEmpty) ? "" : t.isArabic ? " · ${t.room}: ${(d.data()['room'] ?? '').toString()}" : " · Room: ${(d.data()['room'] ?? '').toString()}"}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showWeeklyDialog(doc: d),
                                  icon: Icon(Icons.edit, color: textColor),
                                ),
                                IconButton(
                                  onPressed: () => _delete(d.id),
                                  icon: Icon(Icons.delete, color: textColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.examsEvents,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (overdue.isNotEmpty) ...[
                    Text(
                      t.overdue,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final d in overdue) ...[
                      _DatedCard(
                        title: (d.data()['title'] ?? '').toString(),
                        subtitle:
                            "${_fmtDateTime(d.data()['start'], t)} → ${_fmtDateTime(d.data()['end'], t)}"
                            "${((d.data()['room'] ?? '').toString().trim().isEmpty) ? "" : t.isArabic ? " · ${t.room}: ${(d.data()['room'] ?? '').toString()}" : " · Room: ${(d.data()['room'] ?? '').toString()}"}",
                        red: true,
                        showCheck: false,
                        checked: false,
                        onCheck: null,
                        showRestore: false,
                        restoreTooltip: null,
                        onRestore: null,
                        onEdit: () => _showDatedDialog(doc: d),
                        onDelete: () => _delete(d.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.dark, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.active,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (active.isEmpty)
                          Text(
                            t.noActiveDatedEvents,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        for (final d in active) ...[
                          _DatedCard(
                            title: (d.data()['title'] ?? '').toString(),
                            subtitle:
                                "${_fmtDateTime(d.data()['start'], t)} → ${_fmtDateTime(d.data()['end'], t)}"
                                "${((d.data()['room'] ?? '').toString().trim().isEmpty) ? "" : t.isArabic ? " · ${t.room}: ${(d.data()['room'] ?? '').toString()}" : " · Room: ${(d.data()['room'] ?? '').toString()}"}",
                            red: false,
                            showCheck: true,
                            checked: false,
                            onCheck: () => _toggleDatedDone(d.id, true),
                            showRestore: false,
                            restoreTooltip: null,
                            onRestore: null,
                            onEdit: () => _showDatedDialog(doc: d),
                            onDelete: () => _delete(d.id),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      t.noCompletedAppointments,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  for (final d in completed) ...[
                    _DatedCard(
                      title: (d.data()['title'] ?? '').toString(),
                      subtitle:
                          "${_fmtDateTime(d.data()['start'], t)} → ${_fmtDateTime(d.data()['end'], t)}"
                          "${((d.data()['room'] ?? '').toString().trim().isEmpty) ? "" : t.isArabic ? " · ${t.room}: ${(d.data()['room'] ?? '').toString()}" : " · Room: ${(d.data()['room'] ?? '').toString()}"}",
                      red: false,
                      showCheck: false,
                      checked: false,
                      onCheck: null,
                      showRestore: true,
                      restoreTooltip: t.restore,
                      onRestore: () => _restoreDated(context, d),
                      onEdit: () => _showDatedDialog(doc: d),
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

class _DatedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool red;

  final bool showCheck;
  final bool checked;
  final VoidCallback? onCheck;

  final bool showRestore;
  final String? restoreTooltip;
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
    required this.restoreTooltip,
    required this.onRestore,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textColor = red ? AppTheme.overdueRed : AppTheme.textPrimary(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: red
            ? (isDark ? const Color(0xFF4A2323) : const Color(0xFFF6D1C9))
            : AppTheme.softCardColor(context),
        borderRadius: BorderRadius.circular(18),
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
                    color: red
                        ? AppTheme.overdueRed
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.70)
                            : AppTheme.dark),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
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