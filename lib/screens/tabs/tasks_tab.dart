import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');

  //  لون كروت أغمق ومريح
  static const Color _tileColor = Color(0xFFE9C2B7);

  Future<void> _addTask(BuildContext context) async {
    final c = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add task"),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: "Task title"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final text = c.text.trim();
              if (text.isEmpty) return;

              await _tasksRef.add({
                'title': text,
                'done': false,
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _editTask(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final c = TextEditingController(text: (doc.data()['title'] ?? '').toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit task"),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: "Task title"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final text = c.text.trim();
              if (text.isEmpty) return;

              await _tasksRef.doc(doc.id).update({
                'title': text,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDone(String id, bool done) async {
    await _tasksRef.doc(id).update({'done': done});
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

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  const Text(
                    "Tasks",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),

                  if (docs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _tileColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: const Text(
                        "No tasks yet.\nPress + to add.",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                  for (final d in docs) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _tileColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleDone(d.id, !((d.data()['done'] ?? false) == true)),
                            child: Icon(
                              (d.data()['done'] ?? false) == true
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (d.data()['title'] ?? '').toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                decoration: ((d.data()['done'] ?? false) == true)
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _editTask(context, d),
                            icon: const Icon(Icons.edit),
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