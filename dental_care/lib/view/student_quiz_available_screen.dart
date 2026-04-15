import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/quiz_provider.dart';
import 'student_quiz_taking_screen.dart';

class StudentQuizAvailableScreen extends StatefulWidget {
  const StudentQuizAvailableScreen({Key? key}) : super(key: key);

  @override
  State<StudentQuizAvailableScreen> createState() =>
      _StudentQuizAvailableScreenState();
}

class _StudentQuizAvailableScreenState
    extends State<StudentQuizAvailableScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Quizzes'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, _) {
          if (quizProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final quizzes = quizProvider.quizzes;

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

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              quiz.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Chip(
                            label: Text(
                                quiz.config.difficulty.name[0].toUpperCase() +
                                    quiz.config.difficulty.name.substring(1)),
                            backgroundColor: _getDifficultyColor(
                                quiz.config.difficulty.name[0].toUpperCase() +
                                    quiz.config.difficulty.name.substring(1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.timer,
                              size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            '${quiz.questions.length} Questions',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.score,
                              size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            '${quiz.totalMarks.toStringAsFixed(0)} Marks',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StudentQuizTakingScreen(quiz: quiz),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Start Quiz'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green.shade100;
      case 'Medium':
        return Colors.orange.shade100;
      case 'Hard':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
