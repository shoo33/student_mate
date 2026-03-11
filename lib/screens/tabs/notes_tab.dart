import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../app_text.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('notes');

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _showAddOrEditNoteDialog({
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final t = AppText(Localizations.localeOf(context).languageCode);
    final data = doc?.data();
    final titleCtrl = TextEditingController(text: (data?['title'] ?? '').toString());
    final bodyCtrl = TextEditingController(text: (data?['body'] ?? '').toString());

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(doc == null ? t.addNote : t.editNote),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: t.title,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: t.writeYourNote,
                    alignLabelWithHint: true,
                  ),
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
                final body = bodyCtrl.text.trim();

                if (title.isEmpty && body.isEmpty) return;

                if (doc == null) {
                  await _notesRef.add({
                    'title': title,
                    'body': body,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  _toast(t.noteSaved);
                } else {
                  await _notesRef.doc(doc.id).update({
                    'title': title,
                    'body': body,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  _toast(t.noteUpdated);
                }

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: Text(t.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote(String id) async {
    final t = AppText(Localizations.localeOf(context).languageCode);
    await _notesRef.doc(id).delete();
    _toast(t.noteDeleted);
  }

  bool _matchesSearch(Map<String, dynamic> note) {
    if (_searchText.trim().isEmpty) return true;

    final q = _searchText.toLowerCase().trim();
    final title = (note['title'] ?? '').toString().toLowerCase();
    final body = (note['body'] ?? '').toString().toLowerCase();

    return title.contains(q) || body.contains(q);
  }

  String _previewBody(String text, AppText t) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return t.noContent;
    return cleaned;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppText(Localizations.localeOf(context).languageCode);
    final pageTop = AppTheme.pageTop(context);
    final pageBottom = AppTheme.pageBottom(context);
    final cardColor = AppTheme.cardColor(context);
    final textColor = AppTheme.textPrimary(context);
    final mutedText = AppTheme.textMuted(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.rose,
        foregroundColor: Colors.white,
        onPressed: () => _showAddOrEditNoteDialog(),
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
            stream: _notesRef.orderBy('updatedAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final allDocs = snapshot.data?.docs ?? [];
              final filteredDocs = allDocs.where((d) => _matchesSearch(d.data())).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  Text(
                    t.notes,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.dark, width: 2),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: t.searchNotes,
                        hintStyle: TextStyle(
                          color: mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                        icon: Icon(Icons.search, color: mutedText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (allDocs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: Text(
                        t.noNotesYet,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    )
                  else if (filteredDocs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.dark, width: 2),
                      ),
                      child: Text(
                        t.noNoteFound,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    )
                  else
                    ...filteredDocs.map(
                      (doc) {
                        final data = doc.data();
                        final title = (data['title'] ?? '').toString().trim();
                        final body = (data['body'] ?? '').toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.dark, width: 2),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showAddOrEditNoteDialog(doc: doc),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title.isEmpty ? t.untitledNote : title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _previewBody(body, t),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            height: 1.3,
                                            color: mutedText,
                                          ),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () => _showAddOrEditNoteDialog(doc: doc),
                                    icon: Icon(Icons.edit, color: textColor),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteNote(doc.id),
                                    icon: Icon(Icons.delete, color: textColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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