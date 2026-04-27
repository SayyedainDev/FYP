import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/lecture_notes_provider.dart';
import 'package:dental_care/core/theme/app_tokens.dart';

class StudentLectureNotesScreen extends StatefulWidget {
  const StudentLectureNotesScreen({super.key});

  @override
  State<StudentLectureNotesScreen> createState() =>
      _StudentLectureNotesScreenState();
}

class _StudentLectureNotesScreenState extends State<StudentLectureNotesScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture Notes'),
        elevation: 0,
        backgroundColor: AppColors.brandPrimary,
      ),
      body: Consumer<LectureNotesProvider>(
        builder: (context, lectureProvider, _) {
          if (lectureProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final lectures = lectureProvider.lectureNotes;

          if (lectures.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No lecture notes available',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lectures.length,
            itemBuilder: (context, index) {
              final lecture = lectures[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description, color: Colors.blue.shade700),
                  ),
                  title: Text(
                    lecture.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        lecture.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to lecture details
                    _showLectureDetails(context, lecture);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showLectureDetails(BuildContext context, dynamic lecture) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lecture.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Topic: ${lecture.topic}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              lecture.content ?? 'No description available',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
