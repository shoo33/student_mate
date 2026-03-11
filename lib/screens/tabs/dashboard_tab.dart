import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../app_text.dart';

class DashboardTab extends StatefulWidget {
  final VoidCallback goToSchedule;
  final VoidCallback goToTasks;

  const DashboardTab({
    super.key,
    required this.goToSchedule,
    required this.goToTasks,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');

  CollectionReference<Map<String, dynamic>> get _schedRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('schedules');

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('app');

  String _weekdayName(int w, AppText text) {
    if (text.isArabic) {
      const names = [
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد'
      ];
      return names[w - 1];
    }
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return names[w - 1];
  }

  String _monthName(int m, AppText text) {
    if (text.isArabic) {
      const names = [
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
        'ديسمبر'
      ];
      return names[m - 1];
    }
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[m - 1];
  }

  String _shortDayName(int d, AppText text) {
    if (text.isArabic) {
      const names = ['أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];
      return names[(d - 1).clamp(0, 6)];
    }
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return names[(d - 1).clamp(0, 6)];
  }

  String _fmtTimeOfDayMinutes(int mins) {
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

  String _fmtDateTime(Timestamp ts, AppText text) {
    final d = ts.toDate();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = _monthName(d.month, text).substring(0, min(3, _monthName(d.month, text).length));
    return '$dd $mm · ${_fmt(d)}';
  }

  bool _isOverdueTask(Map<String, dynamic> t) {
    final done = (t['done'] ?? false) == true;
    if (done) return false;
    final due = t['dueAt'];
    if (due is! Timestamp) return false;
    return due.toDate().isBefore(DateTime.now());
  }

  bool _isOverdueDatedSchedule(Map<String, dynamic> s) {
    final type = (s['type'] ?? 'weekly').toString();
    if (type != 'dated') return false;
    final done = (s['done'] ?? false) == true;
    if (done) return false;
    final end = s['end'];
    if (end is! Timestamp) return false;
    return end.toDate().isBefore(DateTime.now());
  }

  Future<void> _markTaskDone(String id) async {
    await _tasksRef.doc(id).update({
      'done': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  List<String> _quotesFromSettings(Map<String, dynamic> settings, AppText text) {
    final raw = settings['customQuotes'];
    if (raw is List) {
      final list = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }
    return text.defaultQuotes;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = AppTheme.isDark(context);
    final pageTop = AppTheme.pageTop(context);
    final pageBottom = AppTheme.pageBottom(context);
    final textColor = AppTheme.textPrimary(context);
    final mutedText = AppTheme.textMuted(context);
    final quoteColor =
        isDark ? AppTheme.quoteCardDark : AppTheme.profileHeaderColor(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pageTop, pageBottom],
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _settingsDoc.snapshots(),
          builder: (context, settingsSnap) {
            final settings = settingsSnap.data?.data() ?? {};
            final text = AppText((settings['languageCode'] ?? 'en').toString());

            final quotesEnabled = (settings['quotesEnabled'] ?? true) == true;
            final weeklyHomeLimit = (settings['weeklyHomeLimit'] ?? 2) as int;
            final appointmentsHomeLimit =
                (settings['appointmentsHomeLimit'] ?? 3) as int;
            final tasksHomeLimit = (settings['tasksHomeLimit'] ?? 3) as int;
            final showAllWeeklyOnHome =
                (settings['showAllWeeklyOnHome'] ?? false) == true;
            final showAllDatedOnHome =
                (settings['showAllDatedOnHome'] ?? false) == true;

            final quotes = _quotesFromSettings(settings, text);
            final quote = quotes[Random().nextInt(quotes.length)];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.rose,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${_weekdayName(now.weekday, text)}, ${_monthName(now.month, text)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.beigeBtn,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.dark, width: 2),
                        ),
                        child: Text(
  "${now.day}",
  style: TextStyle(
    fontWeight: FontWeight.w900,
    color: AppTheme.isDark(context) ? AppTheme.dark : Colors.black87,
  ),
),
                      ),
                    ],
                  ),
                ),
                if (quotesEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: quoteColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      quote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _schedRef.snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }

                    final all = snap.data?.docs ?? [];

                    final weekly = all
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

                    final weeklyShown = showAllWeeklyOnHome
                        ? weekly
                        : weekly.take(weeklyHomeLimit).toList();

                    final dated = all
                        .where((d) {
                          final data = d.data();
                          return (data['type'] ?? 'weekly').toString() == 'dated' &&
                              (data['done'] ?? false) != true;
                        })
                        .toList();

                    dated.sort((a, b) {
                      final aStart = a.data()['start'];
                      final bStart = b.data()['start'];
                      if (aStart is Timestamp && bStart is Timestamp) {
                        return aStart.toDate().compareTo(bStart.toDate());
                      }
                      return 0;
                    });

                    final datedShown = showAllDatedOnHome
                        ? dated
                        : dated.take(appointmentsHomeLimit).toList();

                    return Column(
                      children: [
                        GestureDetector(
                          onTap: widget.goToSchedule,
                          child: _Card(
                            title: text.weekly,
                            actionText: weekly.isEmpty ? text.add : text.more,
                            onAction: widget.goToSchedule,
                            child: weeklyShown.isEmpty
                                ? Text(
                                    text.noWeeklyClasses,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (int i = 0; i < weeklyShown.length; i++) ...[
                                        Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 38,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppTheme.darkCardSoft
                                                    : const Color(0xFFE8A79A),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                _shortDayName(
                                                  (weeklyShown[i].data()['dayOfWeek'] ?? 1) as int,
                                                  text,
                                                ),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _Pill(
                                                text: (weeklyShown[i].data()['title'] ?? '')
                                                    .toString(),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            _TimePill(
                                              text:
                                                  "${_fmtTimeOfDayMinutes((weeklyShown[i].data()['startMin'] ?? 0) as int)}\n${_fmtTimeOfDayMinutes((weeklyShown[i].data()['endMin'] ?? 0) as int)}",
                                            ),
                                          ],
                                        ),
                                        if (i != weeklyShown.length - 1)
                                          const SizedBox(height: 10),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: widget.goToSchedule,
                          child: _Card(
                            title: text.appointments,
                            actionText: dated.isEmpty ? text.add : text.more,
                            onAction: widget.goToSchedule,
                            child: datedShown.isEmpty
                                ? Text(
                                    text.noDatedEvents,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (final d in datedShown) ...[
                                        _MiniLine(
                                          title: (d.data()['title'] ?? '').toString(),
                                          subtitle: _fmtDateTime(d.data()['start'], text),
                                          isOverdue: _isOverdueDatedSchedule(d.data()),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _tasksRef.where('done', isEqualTo: false).snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }

                    final docs = snap.data?.docs ?? [];

                    final withDue = docs.where((d) => d.data()['dueAt'] is Timestamp).toList();
                    final noDue = docs.where((d) => d.data()['dueAt'] is! Timestamp).toList();

                    withDue.sort((a, b) {
                      final ad = (a.data()['dueAt'] as Timestamp).toDate();
                      final bd = (b.data()['dueAt'] as Timestamp).toDate();
                      return ad.compareTo(bd);
                    });

                    final merged = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                    for (final x in withDue) {
                      if (merged.length >= tasksHomeLimit) break;
                      merged.add(x);
                    }
                    for (final x in noDue) {
                      if (merged.length >= tasksHomeLimit) break;
                      merged.add(x);
                    }

                    return GestureDetector(
                      onTap: widget.goToTasks,
                      child: _Card(
                        title: text.tasks,
                        actionText: docs.isEmpty ? text.add : text.more,
                        onAction: widget.goToTasks,
                        child: merged.isEmpty
                            ? Text(
                                text.noTasks,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              )
                            : Column(
                                children: [
                                  for (final d in merged) ...[
                                    Row(
                                      children: [
                                        if (!_isOverdueTask(d.data())) ...[
                                          GestureDetector(
                                            onTap: () => _markTaskDone(d.id),
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.70)
                                                      : AppTheme.dark,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Expanded(
                                          child: Text(
                                            (d.data()['title'] ?? '').toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: _isOverdueTask(d.data())
                                                  ? AppTheme.overdueRed
                                                  : mutedText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        if (d.data()['dueAt'] is Timestamp)
                                          Text(
                                            _fmtDateTime(d.data()['dueAt'], text),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: _isOverdueTask(d.data())
                                                  ? AppTheme.overdueRed
                                                  : mutedText,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 90),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onAction;
  final Widget child;

  const _Card({
    required this.title,
    required this.actionText,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textPrimary(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dark, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.rose,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Container(
      height: 38,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardSoft : const Color(0xFFF2B8A8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary(context),
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final String text;
  const _TimePill({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Container(
      width: 82,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardSoft : const Color(0xFFE8A79A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary(context),
        ),
      ),
    );
  }
}

class _MiniLine extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isOverdue;

  const _MiniLine({
    required this.title,
    required this.subtitle,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final normalColor = AppTheme.textMuted(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isOverdue ? AppTheme.overdueRed : normalColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          subtitle,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isOverdue ? AppTheme.overdueRed : normalColor,
          ),
        ),
      ],
    );
  }
}