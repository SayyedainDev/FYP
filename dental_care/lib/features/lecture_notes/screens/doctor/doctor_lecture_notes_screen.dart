import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/features/lecture_notes/providers/lecture_note_provider.dart';
import 'package:dental_care/features/lecture_notes/widgets/note_card.dart';
import 'upload_note_dialog.dart';

class DoctorLectureNotesScreen extends StatefulWidget {
  const DoctorLectureNotesScreen({super.key});

  @override
  State<DoctorLectureNotesScreen> createState() =>
      _DoctorLectureNotesScreenState();
}

class _DoctorLectureNotesScreenState extends State<DoctorLectureNotesScreen> {
  // Can be passed via constructor or fetched in the app. Using hardcoded for demo.
  final List<String> _availableModules = ['Module 1', 'Module 2', 'general'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LectureNoteProvider>().fetchAll();
    });
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UploadNoteDialog(availableModules: _availableModules),
    );
  }

  void _confirmDelete(BuildContext context, note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Delete this note? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<LectureNoteProvider>().deleteNote(note);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture Notes (Manage)'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<LectureNoteProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.status == LectureNoteStatus.error &&
              provider.notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Something went wrong loading notes.',
                      style: TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<LectureNoteProvider>().fetchAll(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.notes.isEmpty) {
            return const Center(
                child: Text('No lecture notes found. Tap + to upload.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notes.length,
            itemBuilder: (_, index) {
              final note = provider.notes[index];
              return NoteCard(
                note: note,
                canDelete: true,
                onDelete: () => _confirmDelete(context, note),
              );
            },
          );
        },
      ),
    );
  }
}
