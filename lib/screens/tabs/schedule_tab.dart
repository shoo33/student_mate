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

  // ألوان (غامقة شوي ومريحة)
  static const Color _cardColor = Color(0xFFE4B8AC);
  static const Color _tabPink = Color(0xFFB76E79);
  static const Color _blockColor = Color(0xFFF2B8A8);

  // نطاق الوقت: 8AM -> 10PM
  static const int _startHour = 8;
  static const int _endHour = 22;

  // ارتفاع الساعة في الجدول (كل ما زاد صار أوضح)
  static const double _hourHeight = 70;

  // ترتيب الأعمدة في العرض: Sunday -> Saturday
  // لكن قيم Firestore عندك غالباً: 1=Mon ... 7=Sun
  // فـ Sunday=7, Monday=1 ... Saturday=6
  final List<int> _dayOrder = const [7, 1, 2, 3, 4, 5, 6];
  final List<String> _dayHeaders = const ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  // ---------------- Helpers ----------------
  String _dayNameFromMondayIndex(int dayOfWeek) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek < 1 || dayOfWeek > 7) return '';
    return names[dayOfWeek - 1];
  }

  String _fmtHourLabel(int h) {
    final ampm = h >= 12 ? 'PM' : 'AM';
    int hh = h % 12;
    if (hh == 0) hh = 12;
    return '$hh:00 $ampm';
  }

  String _fmtMin(int mins) {
    int h = mins ~/ 60;
    final m = (mins % 60).toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$m$ampm';
  }

  String _fmtDT(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = d.day.toString().padLeft(2, '0');
    final mon = months[d.month - 1];

    int h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    h = h % 12;
    if (h == 0) h = 12;

    return "$day $mon • $h:$m$ampm";
  }

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

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

  // ---------------- Firestore actions ----------------
  Future<void> addWeekly({
    required String title,
    required int dayOfWeek,
    required int startMin,
    required int endMin,
    required String room,
  }) async {
    await scheduleRef.add({
      'type': 'weekly',
      'title': title,
      'room': room,
      'dayOfWeek': dayOfWeek,
      'startMin': startMin,
      'endMin': endMin,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addDated({
    required String title,
    required DateTime start,
    required DateTime end,
    required String room,
  }) async {
    await scheduleRef.add({
      'type': 'dated',
      'title': title,
      'room': room,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'done': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateWeekly({
    required String id,
    required String title,
    required int dayOfWeek,
    required int startMin,
    required int endMin,
    required String room,
  }) async {
    await scheduleRef.doc(id).update({
      'title': title,
      'room': room,
      'dayOfWeek': dayOfWeek,
      'startMin': startMin,
      'endMin': endMin,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDated({
    required String id,
    required String title,
    required DateTime start,
    required DateTime end,
    required String room,
  }) async {
    await scheduleRef.doc(id).update({
      'title': title,
      'room': room,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setDone(String id, bool v) async {
    await scheduleRef.doc(id).update({
      'done': v,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(String id) async {
    await scheduleRef.doc(id).delete();
  }

  // ---------------- UI blocks ----------------
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
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

  // ---------------- Add dialog (زي قبل) ----------------
  void showAddDialog() {
    int tab = 0; // 0 weekly, 1 exams

    // weekly
    final wTitle = TextEditingController();
    final wRoom = TextEditingController();
    int wDay = 1;
    TimeOfDay wStart = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay wEnd = const TimeOfDay(hour: 9, minute: 0);

    // dated
    final eTitle = TextEditingController();
    final eRoom = TextEditingController();
    DateTime eStart = DateTime.now();
    DateTime eEnd = DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          Widget tabBtn(String text, int idx) {
            final selected = tab == idx;
            return Expanded(
              child: GestureDetector(
                onTap: () => setLocal(() => tab = idx),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _tabPink : _blockColor,
                    borderRadius: BorderRadius.circular(16),
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

          Widget weeklyForm() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  value: wDay,
                  items: List.generate(7, (i) {
                    final v = i + 1;
                    return DropdownMenuItem(
                      value: v,
                      child: Text(_dayNameFromMondayIndex(v)),
                    );
                  }),
                  onChanged: (v) => setLocal(() => wDay = v ?? 1),
                  decoration: const InputDecoration(labelText: "Day"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text("Start: ${wStart.format(context)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: wStart);
                        if (t != null) setLocal(() => wStart = t);
                      },
                      child: const Text("Choose"),
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text("End: ${wEnd.format(context)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: wEnd);
                        if (t != null) setLocal(() => wEnd = t);
                      },
                      child: const Text("Choose"),
                    )
                  ],
                ),
              ],
            );
          }

          Widget examForm() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      child: Text("Start: ${_fmtDT(eStart)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await _pickDateTime(context, eStart);
                        if (picked != null) setLocal(() => eStart = picked);
                      },
                      child: const Text("Choose"),
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text("End: ${_fmtDT(eEnd)}",
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await _pickDateTime(context, eEnd);
                        if (picked != null) setLocal(() => eEnd = picked);
                      },
                      child: const Text("Choose"),
                    )
                  ],
                ),
              ],
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
                const SizedBox(height: 12),
                if (tab == 0) weeklyForm() else examForm(),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (tab == 0) {
                    final t = wTitle.text.trim();
                    if (t.isEmpty) return;

                    final s = _toMin(wStart);
                    final e = _toMin(wEnd);
                    final startMin = s <= e ? s : e;
                    final endMin = s <= e ? e : s;

                    await addWeekly(
                      title: t,
                      room: wRoom.text.trim(),
                      dayOfWeek: wDay,
                      startMin: startMin,
                      endMin: endMin,
                    );
                  } else {
                    final t = eTitle.text.trim();
                    if (t.isEmpty) return;

                    DateTime s = eStart;
                    DateTime e = eEnd;
                    if (e.isBefore(s)) {
                      final tmp = s;
                      s = e;
                      e = tmp;
                    }

                    await addDated(
                      title: t,
                      room: eRoom.text.trim(),
                      start: s,
                      end: e,
                    );
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Save"),
              )
            ],
          );
        },
      ),
    );
  }

  // ---------------- Weekly BIG BLOCK Grid ----------------
  // بلوكات طويلة مثل جدول الجامعة (يغطي وقت البداية للنهاية)
  Widget _weeklyBigGrid(List<QueryDocumentSnapshot<Map<String, dynamic>>> weeklyDocs) {
    // نجمع حسب اليوم
    final Map<int, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byDay = {
      for (int i = 1; i <= 7; i++) i: <QueryDocumentSnapshot<Map<String, dynamic>>>[]
    };

    for (final d in weeklyDocs) {
      final data = d.data();
      final day = data['dayOfWeek'];
      if (day is int) byDay[day]!.add(d);
    }

    // ترتيب داخل كل يوم حسب startMin
    for (final k in byDay.keys) {
      byDay[k]!.sort((a, b) {
        final as = (a.data()['startMin'] ?? 0) as int;
        final bs = (b.data()['startMin'] ?? 0) as int;
        return as.compareTo(bs);
      });
    }

    final totalHours = (_endHour - _startHour);
    final gridHeight = totalHours * _hourHeight;

    const timeColW = 78.0;
    const dayColW = 130.0;
    const headerH = 42.0;

    Widget timeColumn() {
      return SizedBox(
        width: timeColW,
        height: gridHeight + headerH,
        child: Column(
          children: [
            const SizedBox(height: headerH),
            for (int h = _startHour; h < _endHour; h++)
              SizedBox(
                height: _hourHeight,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _fmtHourLabel(h),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget dayColumn(int dayOfWeek, String headerText) {
      // الخلفية (خطوط الساعات)
      Widget background() {
        return Column(
          children: [
            for (int h = _startHour; h < _endHour; h++)
              Container(
                height: _hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black.withOpacity(0.10)),
                  ),
                ),
              ),
          ],
        );
      }

      List<Widget> blocks = [];
      for (final doc in byDay[dayOfWeek]!) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString();
        final room = (data['room'] ?? '').toString().trim();

        final startMin = ((data['startMin'] ?? 0) as int).clamp(0, 24 * 60);
        final endMin = ((data['endMin'] ?? 0) as int).clamp(0, 24 * 60);

        final baseMin = _startHour * 60;
        final topMin = (startMin - baseMin).clamp(0, (_endHour * 60 - baseMin));
        final durMin = (endMin - startMin).clamp(15, 24 * 60);

        final top = (topMin / 60.0) * _hourHeight;
        final height = (durMin / 60.0) * _hourHeight;

        blocks.add(Positioned(
          top: top,
          left: 6,
          right: 6,
          height: height,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _blockColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dark, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_fmtMin(startMin)} - ${_fmtMin(endMin)}",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                ),
                if (room.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Room: $room",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ));
      }

      return SizedBox(
        width: dayColW,
        height: gridHeight + headerH,
        child: Column(
          children: [
            Container(
              height: headerH,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                border: Border(
                  bottom: BorderSide(color: Colors.black.withOpacity(0.12)),
                ),
              ),
              child: Text(headerText, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            Expanded(
              child: Stack(
                children: [
                  background(),
                  ...blocks,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dark, width: 2),
          color: Colors.white.withOpacity(0.25),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                timeColumn(),
                for (int i = 0; i < _dayOrder.length; i++)
                  dayColumn(_dayOrder[i], _dayHeaders[i]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Dated rows (Exams/Events) ----------------
  Widget _datedRow(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool expired,
  }) {
    final data = doc.data();
    final title = (data['title'] ?? '').toString();
    final room = (data['room'] ?? '').toString().trim();

    final start = (data['start'] as Timestamp).toDate();
    final end = (data['end'] as Timestamp).toDate();
    final done = (data['done'] ?? false) == true;

    final line = "${_fmtDT(start)} → ${_fmtDT(end)}${room.isEmpty ? "" : " • Room: $room"}";

    if (expired) {
      // Expired: بس حذف (بدون دائرة/قلم)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.dark, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  line,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.red),
                ),
              ]),
            ),
            IconButton(onPressed: () => deleteItem(doc.id), icon: const Icon(Icons.delete)),
          ],
        ),
      );
    }

    // Active/Completed: checkbox + delete فقط (بدون قلم إذا تبين — لكن خليته موجود للفعال)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setDone(doc.id, !done),
            child: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(line, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ]),
          ),
          IconButton(onPressed: () => _editDatedDialog(doc), icon: const Icon(Icons.edit)),
          IconButton(onPressed: () => deleteItem(doc.id), icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }

  void _editDatedDialog(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final titleCtrl = TextEditingController(text: (data['title'] ?? '').toString());
    final roomCtrl = TextEditingController(text: (data['room'] ?? '').toString());

    DateTime start = (data['start'] as Timestamp).toDate();
    DateTime end = (data['end'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Edit exam / event"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
              const SizedBox(height: 10),
              TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: "Room (optional)")),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text("Start: ${_fmtDT(start)}", style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await _pickDateTime(context, start);
                      if (picked != null) setLocal(() => start = picked);
                    },
                    child: const Text("Choose"),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text("End: ${_fmtDT(end)}", style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await _pickDateTime(context, end);
                      if (picked != null) setLocal(() => end = picked);
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

                DateTime s = start;
                DateTime e = end;
                if (e.isBefore(s)) {
                  final tmp = s;
                  s = e;
                  e = tmp;
                }

                await updateDated(
                  id: doc.id,
                  title: t,
                  room: roomCtrl.text.trim(),
                  start: s,
                  end: e,
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

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
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

              final weekly = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final datedActive = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final datedExpired = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final datedCompleted = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              for (final d in all) {
                final data = d.data();
                final type = (data['type'] ?? '').toString();

                if (type == 'weekly') {
                  weekly.add(d);
                  continue;
                }

                if (type == 'dated') {
                  final done = (data['done'] ?? false) == true;
                  final start = (data['start'] as Timestamp).toDate();
                  final expired = start.isBefore(now) && !done;

                  if (done) {
                    datedCompleted.add(d);
                  } else if (expired) {
                    datedExpired.add(d);
                  } else {
                    datedActive.add(d);
                  }
                }
              }

              // الأقرب فوق
              datedActive.sort((a, b) {
                final as = (a.data()['start'] as Timestamp).toDate();
                final bs = (b.data()['start'] as Timestamp).toDate();
                return as.compareTo(bs);
              });

              // Expired: الأحدث فوق
              datedExpired.sort((a, b) {
                final as = (a.data()['start'] as Timestamp).toDate();
                final bs = (b.data()['start'] as Timestamp).toDate();
                return bs.compareTo(as);
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  const Text("Schedule", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),

                  _sectionTitle("Weekly classes"),
                  _cardWrap(
                    weekly.isEmpty
                        ? const Text("No weekly classes yet.", style: TextStyle(fontWeight: FontWeight.w900))
                        : _weeklyBigGrid(weekly),
                  ),

                  _sectionTitle("Exams / Events"),
                  _cardWrap(
                    Column(
                      children: [
                        if (datedActive.isEmpty)
                          const Text("No exams/events.", style: TextStyle(fontWeight: FontWeight.w900))
                        else
                          for (int i = 0; i < datedActive.length; i++) ...[
                            _datedRow(datedActive[i], expired: false),
                            if (i != datedActive.length - 1) const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),

                  _sectionTitle("Expired"),
                  _cardWrap(
                    Column(
                      children: [
                        if (datedExpired.isEmpty)
                          const Text("No expired items.", style: TextStyle(fontWeight: FontWeight.w900))
                        else
                          for (int i = 0; i < datedExpired.length; i++) ...[
                            _datedRow(datedExpired[i], expired: true),
                            if (i != datedExpired.length - 1) const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),

                  _sectionTitle("Completed"),
                  _cardWrap(
                    Column(
                      children: [
                        if (datedCompleted.isEmpty)
                          const Text("No completed items.", style: TextStyle(fontWeight: FontWeight.w900))
                        else
                          for (int i = 0; i < datedCompleted.length; i++) ...[
                            _datedRow(datedCompleted[i], expired: false),
                            if (i != datedCompleted.length - 1) const SizedBox(height: 10),
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