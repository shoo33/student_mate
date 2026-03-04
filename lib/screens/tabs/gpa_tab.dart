import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';

class GpaTab extends StatefulWidget {
  const GpaTab({super.key});

  @override
  State<GpaTab> createState() => _GpaTabState();
}

class _GpaTabState extends State<GpaTab> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _gpaDoc =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('gpa').doc('profile');

  static const Color _cardColor = Color(0xFFE4B8AC);
  static const Color _btnSoft = Color(0xFFC27C86);

  static const Map<String, double> _gp4 = {
    'A+': 4.0, 'A': 4.0, 'A-': 3.7,
    'B+': 3.3, 'B': 3.0, 'B-': 2.7,
    'C+': 2.3, 'C': 2.0, 'C-': 1.7,
    'D+': 1.3, 'D': 1.0,
    'F': 0.0,
  };

  double _toDouble(dynamic v) {
    if (v is int) return v.toDouble();
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  List<Map<String, dynamic>> _coursesFromDoc(Map<String, dynamic>? data) {
    final raw = data?['courses'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  double _semCredits(List<Map<String, dynamic>> courses) =>
      courses.fold(0.0, (sum, c) => sum + _toDouble(c['credits']));

  double _semQP(List<Map<String, dynamic>> courses) {
    double qp = 0.0;
    for (final c in courses) {
      final cr = _toDouble(c['credits']);
      final pts = _toDouble(c['points']); // out of 4
      qp += cr * pts;
    }
    return qp;
  }

  double _convert(double gpaOutOf4, int scaleOutOf) {
    if (scaleOutOf == 5) return gpaOutOf4 * (5.0 / 4.0);
    return gpaOutOf4;
  }

  Widget _softBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: _btnSoft, borderRadius: BorderRadius.circular(18)),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }

  Future<void> _saveAll({
    required List<Map<String, dynamic>> courses,
    required double prevCredits,
    required double prevGpaOutOf4,
    required int scaleOutOf,
  }) async {
    await _gpaDoc.set({
      'courses': courses,
      'prevCredits': prevCredits,
      'prevGpaOutOf4': prevGpaOutOf4,
      'scaleOutOf': scaleOutOf,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveCoursesOnly(List<Map<String, dynamic>> courses) async {
    await _gpaDoc.set({
      'courses': courses,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _addCourseDialog(BuildContext context, List<Map<String, dynamic>> current) async {
    final nameCtrl = TextEditingController();
    final creditsCtrl = TextEditingController(text: "3");
    String grade = 'A';
    double points = _gp4[grade] ?? 4.0;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Add course"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Course",
                  hintText: "مثال: SWE356",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: creditsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Credits",
                  hintText: "مثال: 3",
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: grade,
                items: _gp4.keys.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setLocal(() {
                    grade = v;
                    points = _gp4[v] ?? 0;
                  });
                },
                decoration: const InputDecoration(labelText: "Grade"),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Points (out of 4): ${points.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final cr = int.tryParse(creditsCtrl.text.trim()) ?? 0;
                if (cr <= 0) return;

                final next = List<Map<String, dynamic>>.from(current);
                next.add({'name': name, 'credits': cr, 'grade': grade, 'points': points});

                await _saveCoursesOnly(next);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPrevDialog(
    BuildContext context, {
    required List<Map<String, dynamic>> courses,
    required double prevCredits,
    required double prevGpaOutOf4,
    required int scaleOutOf,
  }) async {
    int selectedScale = scaleOutOf;

    final shownPrevGpa = _convert(prevGpaOutOf4, selectedScale);

    // ✅ بدون أصفار
    final creditsCtrl = TextEditingController(
      text: (prevCredits == 0) ? "" : prevCredits.toStringAsFixed(0),
    );
    final gpaCtrl = TextEditingController(
      text: (shownPrevGpa == 0) ? "" : shownPrevGpa.toStringAsFixed(2),
    );

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Cumulative settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedScale,
                items: const [
                  DropdownMenuItem(value: 4, child: Text("GPA out of 4")),
                  DropdownMenuItem(value: 5, child: Text("GPA out of 5")),
                ],
                onChanged: (v) => setLocal(() => selectedScale = v ?? 4),
                decoration: const InputDecoration(labelText: "Scale"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: creditsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Previous Credits",
                  hintText: "مثال: 60",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gpaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Previous GPA (out of $selectedScale)",
                  hintText: "مثال: 3.20",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final pc = _toDouble(creditsCtrl.text.trim());
                double pg = _toDouble(gpaCtrl.text.trim());

                final double fixedCredits = (pc < 0 ? 0 : pc).toDouble();

                final maxScale = selectedScale == 5 ? 5.0 : 4.0;
                if (pg < 0) pg = 0;
                if (pg > maxScale) pg = maxScale;

                final prevOutOf4 = (selectedScale == 4) ? pg : (pg * (4.0 / 5.0));

                await _saveAll(
                  courses: courses,
                  prevCredits: fixedCredits,
                  prevGpaOutOf4: prevOutOf4.toDouble(),
                  scaleOutOf: selectedScale,
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

  Future<void> _deleteCourse(List<Map<String, dynamic>> courses, int index) async {
    final next = List<Map<String, dynamic>>.from(courses);
    next.removeAt(index);
    await _saveCoursesOnly(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _gpaDoc.snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final courses = _coursesFromDoc(data);

              final double prevCredits = _toDouble(data?['prevCredits']);
              final double prevGpaOutOf4 = _toDouble(data?['prevGpaOutOf4']);

              final int savedScale = _toInt(data?['scaleOutOf']);
              final int scaleOutOf = (savedScale == 5) ? 5 : 4;

              final double semCredits = _semCredits(courses);
              final double semQP = _semQP(courses);

              final double semOutOf4 = (semCredits == 0) ? 0.0 : (semQP / semCredits).toDouble();
              final double semGpa = _convert(semOutOf4, scaleOutOf);

              final double prevQP = (prevCredits * prevGpaOutOf4).toDouble();
              final double totalCredits = (prevCredits + semCredits).toDouble();

              final double cumOutOf4 = (totalCredits == 0)
                  ? 0.0
                  : ((prevQP + semQP) / totalCredits).toDouble();
              final double cumulativeGpa = _convert(cumOutOf4, scaleOutOf);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("GPA (out of $scaleOutOf)",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      Row(
                        children: [
                          _softBtn(
                            "Prev",
                            () => _editPrevDialog(
                              context,
                              courses: courses,
                              prevCredits: prevCredits,
                              prevGpaOutOf4: prevGpaOutOf4,
                              scaleOutOf: scaleOutOf,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _softBtn("Add", () => _addCourseDialog(context, courses)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.dark, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Semester GPA", style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(semGpa.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text("Credits: ${semCredits.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.dark, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Cumulative GPA", style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(cumulativeGpa.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text("Previous credits: ${prevCredits.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (courses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: const Text(
                        "No courses yet.\nPress Add to start.",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                  for (int i = 0; i < courses.length; i++) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (courses[i]['name'] ?? '').toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Credits: ${(courses[i]['credits'] ?? 0)} • Grade: ${(courses[i]['grade'] ?? '')}"
                                  " • Points: ${(_toDouble(courses[i]['points'])).toStringAsFixed(2)}",
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteCourse(courses, i),
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
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