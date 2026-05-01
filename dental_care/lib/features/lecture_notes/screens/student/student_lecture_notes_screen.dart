import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/features/lecture_notes/providers/lecture_note_provider.dart';
import 'package:dental_care/features/lecture_notes/models/lecture_note_model.dart';
import 'package:dental_care/features/lecture_notes/widgets/note_card.dart';

class StudentLectureNotesScreen extends StatelessWidget {
  const StudentLectureNotesScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LectureNoteProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Lecture Notes ($moduleId)'),
      ),
      body: StreamBuilder<List<LectureNoteModel>>(
        stream: provider.streamByModule(moduleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Could not load notes. Please try again.'));
          }

          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return const Center(child: Text('No lecture notes uploaded yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (_, i) => NoteCard(note: notes[i], canDelete: false),
          );
        },
      ),
    );
  }
}
