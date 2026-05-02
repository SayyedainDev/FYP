import '../widgets/loading_button.dart';
import '../../widgets/student_screen_header.dart';
import '../../providers/loading_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dental_care/providers/quiz_provider.dart';
import 'package:dental_care/providers/quiz_attempt_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/models/quiz.dart';
import 'package:dental_care/models/quiz_attempt.dart';
import 'package:dental_care/utils/app_dialogs.dart';
import 'student_quiz_taking_screen.dart';

class StudentQuizAvailableScreenV2 extends StatefulWidget {
  const StudentQuizAvailableScreenV2({super.key});

  @override
  State<StudentQuizAvailableScreenV2> createState() =>
      _StudentQuizAvailableScreenV2State();
}

class _StudentQuizAvailableScreenV2State
    extends State<StudentQuizAvailableScreenV2> {
  ColorScheme get _studentColors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final studentId = auth.currentUserId ?? auth.uid ?? '';

      debugPrint('🔍 Fetching published quizzes for students...');
      // Load all published quizzes
      context.read<QuizProvider>().fetchPublishedQuizzes();
      // Load student's attempts
      context
          .read<QuizAttemptProvider>()
          .fetchStudentAttempts(studentId)
          .then((_) {
        if (mounted) {
          debugPrint(
              '✅ Fetched ${context.read<QuizAttemptProvider>().studentAttempts.length} attempts');
          debugPrint(
              '✅ Fetched ${context.read<QuizProvider>().publishedQuizzes.length} published quizzes');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _studentColors.primary.withValues(alpha: 0.08),
                _studentColors.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Consumer2<QuizProvider, QuizAttemptProvider>(
            builder: (context, quizProvider, attemptProvider, _) {
              if (quizProvider.isLoading || attemptProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final allQuizzes = quizProvider.publishedQuizzes;
              final studentAttempts = attemptProvider.studentAttempts;

              if (allQuizzes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz_outlined,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No Quizzes Available',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new quizzes',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              // Separate quizzes into available and completed
              final completedAttempts =
                  studentAttempts.where((a) => a.isSubmitted).toList();
              final completedQuizIds =
                  completedAttempts.map((a) => a.quizId).toSet();

              final availableQuizzes = allQuizzes
                  .where((q) => !completedQuizIds.contains(q.id))
                  .toList();

              final completedQuizzes = allQuizzes
                  .where((q) => completedQuizIds.contains(q.id))
                  .toList();

              return SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: StudentScreenHeader(
                        title: 'Available Quizzes',
                        subtitle: 'Take quizzes published by your instructor',
                        iconData: Icons.quiz,
                        colorScheme: _studentColors,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Available Quizzes Section
                              if (availableQuizzes.isNotEmpty) ...[
                                _buildSectionHeader('Available Quizzes',
                                    Icons.play_circle, Colors.teal),
                                const SizedBox(height: 12),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: availableQuizzes.length,
                                  itemBuilder: (context, index) {
                                    final quiz = availableQuizzes[index];
                                    return _buildQuizCard(
                                      context,
                                      quiz,
                                      isCompleted: false,
                                      onTap: () => _startQuiz(context, quiz),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Completed Quizzes Section
                              if (completedQuizzes.isNotEmpty) ...[
                                _buildSectionHeader('Completed Quizzes',
                                    Icons.done_all, Colors.blue),
                                const SizedBox(height: 12),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: completedQuizzes.length,
                                  itemBuilder: (context, index) {
                                    final quiz = completedQuizzes[index];
                                    final attempt =
                                        completedAttempts.firstWhere(
                                      (a) => a.quizId == quiz.id,
                                      orElse: () => QuizAttempt(
                                        id: '',
                                        quizId: quiz.id,
                                        quizTitle: quiz.title,
                                        studentId: '',
                                        studentName: '',
                                        startTime: DateTime.now(),
                                        totalMarks: quiz.totalMarks,
                                      ),
                                    );

                                    return _buildCompletedQuizCard(
                                      context,
                                      quiz,
                                      attempt,
                                      onReview: () =>
                                          _reviewQuiz(context, quiz, attempt),
                                    );
                                  },
                                ),
                              ],

                              if (availableQuizzes.isEmpty &&
                                  completedQuizzes.isEmpty)
                                const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(
    BuildContext context,
    Quiz quiz, {
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz Title & Stats
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quiz.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Quiz Stats
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.list_rounded,
                    label: '${quiz.config.totalQuestions} Questions',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.grade,
                    label: '${quiz.totalMarks} Marks',
                    color: Colors.orange,
                  ),
                  if (quiz.config.timeLimitMinutes != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildStatChip(
                        icon: Icons.timer,
                        label: '${quiz.config.timeLimitMinutes} min',
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedQuizCard(
    BuildContext context,
    Quiz quiz,
    QuizAttempt attempt, {
    required VoidCallback onReview,
  }) {
    final scoreColor = attempt.isPassed ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onReview,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Score
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quiz.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Score Badge
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${attempt.score}/${attempt.totalMarks}',
                          style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attempt.grade,
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.percent,
                    label: '${attempt.scorePercentage.toStringAsFixed(1)}%',
                    color: scoreColor,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.timer,
                    label: attempt.durationText,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Review Button
              SizedBox(
                width: double.infinity,
                child: Consumer<LoadingProvider>(
                  builder: (context, loadingState, _) {
                    return LoadingButton(
                      isLoading: loadingState.isLoading,
                      child: OutlinedButton.icon(
                        onPressed: loadingState.isLoading
                            ? null
                            : () => loadingState.runAsyncAction(() async {
                                  final op = onReview;
                                  await Future.sync(() => (op as dynamic)());
                                }),
                        icon: const Icon(Icons.preview, size: 18),
                        label: const Text('Review Answers'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuiz(BuildContext context, Quiz quiz) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attemptProvider =
          Provider.of<QuizAttemptProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      final studentId = authProvider.currentUserId ?? authProvider.uid ?? '';
      final studentName = authProvider.user?.displayName ?? 'Student';

      debugPrint('🎯 Starting new quiz: ${quiz.id}');

      // Create new attempt
      final attempt = await attemptProvider.startAttempt(
        quizId: quiz.id,
        quizTitle: quiz.title,
        studentId: studentId,
        studentName: studentName,
        totalMarks: quiz.totalMarks,
        questionCount: quiz.config.totalQuestions,
      );

      if (!mounted) return;

      if (attempt != null) {
        debugPrint('📖 Started attempt: ${attempt.id}');
        final quizAttemptProvider = attemptProvider;
        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        navigator.push(
          MaterialPageRoute(
            builder: (routeContext) => MultiProvider(
              providers: [
                ChangeNotifierProvider.value(
                  value: quizAttemptProvider,
                ),
                ChangeNotifierProvider.value(value: quizProvider),
                ChangeNotifierProvider.value(value: authProvider),
              ],
              child: StudentQuizTakingScreen(
                quiz: quiz,
                isReview: false,
              ),
            ),
          ),
        );
      } else {
        if (mounted) {
          AppDialogs.showErrorDialog(
            context,
            message: 'Failed to start quiz. Please try again.',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error starting quiz: $e');
      if (mounted) {
        AppDialogs.showErrorDialog(
          context,
          message: 'Error starting quiz: $e',
        );
      }
    }
  }

  Future<void> _reviewQuiz(
    BuildContext context,
    Quiz quiz,
    QuizAttempt attempt,
  ) async {
    try {
      debugPrint('📖 Loading attempt for review: ${attempt.id}');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attemptProvider =
          Provider.of<QuizAttemptProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      final studentId = authProvider.currentUserId ?? authProvider.uid ?? '';

      // Fetch the complete attempt with responses
      final completeAttempt = await attemptProvider.getAttemptForReview(
        quizId: quiz.id,
        studentId: studentId,
      );

      if (!mounted) return;

      if (completeAttempt != null) {
        final quizAttemptProvider = attemptProvider;
        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        navigator.push(
          MaterialPageRoute(
            builder: (routeContext) => MultiProvider(
              providers: [
                ChangeNotifierProvider.value(
                  value: quizAttemptProvider,
                ),
                ChangeNotifierProvider.value(value: quizProvider),
                ChangeNotifierProvider.value(value: authProvider),
              ],
              child: StudentQuizTakingScreen(
                quiz: quiz,
                isReview: true,
              ),
            ),
          ),
        );
      } else {
        if (mounted) {
          AppDialogs.showErrorDialog(
            context,
            message: 'Failed to load quiz attempt. Please try again.',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading attempt for review: $e');
      if (mounted) {
        AppDialogs.showErrorDialog(
          context,
          message: 'Error loading attempt: $e',
        );
      }
    }
  }
}
