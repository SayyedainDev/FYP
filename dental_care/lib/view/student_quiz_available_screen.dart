import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/providers/quiz_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/core/theme/app_tokens.dart';
import 'student_quiz_taking_screen.dart';

class StudentQuizAvailableScreen extends StatefulWidget {
  final String? quizId;
  const StudentQuizAvailableScreen({Key? key, this.quizId}) : super(key: key);

  @override
  State<StudentQuizAvailableScreen> createState() =>
      _StudentQuizAvailableScreenState();
}

class _StudentQuizAvailableScreenState
    extends State<StudentQuizAvailableScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final studentId = auth.currentUserId ?? auth.uid ?? '';
      context.read<QuizProvider>().fetchPublishedQuizzes(excludeStudentId: studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Quizzes'),
        backgroundColor: AppColors.brandPrimary,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, _) {
          if (quizProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final quizzes = quizProvider.publishedQuizzes;

          if (quizzes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No quizzes available',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Group quizzes by dentist UID (teacher)
          final Map<String, List> quizzesByTeacher = {};
          for (final q in quizzes) {
            final uid = q.dentistUid;
            quizzesByTeacher.putIfAbsent(uid, () => []).add(q);
          }

          // Cache for resolved display names
          final Map<String, String> uidToName = {};

          Future<void> _resolveName(String uid) async {
            if (uidToName.containsKey(uid)) return;
            try {
              final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
              if (doc.exists) {
                final data = doc.data();
                if (data != null) {
                  final first = (data['firstName'] as String?) ?? '';
                  final last = (data['lastName'] as String?) ?? '';
                  final display = (first.isNotEmpty || last.isNotEmpty) ? ('$first ${last}').trim() : (data['email'] as String?)?.split('@').first ?? uid;
                  uidToName[uid] = display;
                }
              }
            } catch (_) {
              uidToName[uid] = uid;
            }
            if (mounted) setState(() {});
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: quizzesByTeacher.entries.map((entry) {
              final uid = entry.key;
              final list = entry.value;

              // start resolving name (async) if not available
              if (!uidToName.containsKey(uid)) _resolveName(uid);

              final titleText = uidToName[uid] ?? 'Teacher';

              return ExpansionTile(
                title: Text(
                  titleText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                children: list.map<Widget>((quiz) {
                  return ListTile(
                    title: Text(quiz.title, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${quiz.questions.length} questions • ${quiz.totalMarks.toStringAsFixed(0)} marks'),
                    trailing: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentQuizTakingScreen(quiz: quiz))),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                      child: const Text('Start'),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
