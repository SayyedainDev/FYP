import '../widgets/loading_button.dart';
import '../../providers/loading_provider.dart';
import 'package:provider/provider.dart';
import 'student_quiz_result_screen.dart';
import 'student_quiz_taking_screen.dart';
import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../provider/auth_provider.dart';
import '../providers/quiz_attempt_provider.dart';
import '../providers/quiz_provider.dart';
import '../service/student_bookmark_service.dart';
import '../widgets/loaders/app_loader.dart';

class StudentQuizDetailScreen extends StatefulWidget {
  const StudentQuizDetailScreen({super.key, required this.quizId});

  final String quizId;

  @override
  State<StudentQuizDetailScreen> createState() =>
      _StudentQuizDetailScreenState();
}

class _StudentQuizDetailScreenState extends State<StudentQuizDetailScreen> {
  Quiz? _quiz;
  bool _loading = true;
  bool _actionLoading = false;
  Set<String> _bookmarks = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final quizProvider = context.read<QuizProvider>();
    final attemptProvider = context.read<QuizAttemptProvider>();
    final authProvider = context.read<AuthProvider>();
    final studentId = authProvider.user?.uid;

    _bookmarks = await StudentBookmarkService.load();

    if (quizProvider.publishedQuizzes.isEmpty) {
      await quizProvider.fetchPublishedQuizzes();
    }

    if (studentId != null && studentId.isNotEmpty) {
      await attemptProvider.fetchStudentAttempts(studentId);
    }

    final quiz = quizProvider.publishedQuizzes
        .where((q) => q.id == widget.quizId)
        .cast<Quiz?>()
        .firstWhere((q) => q != null, orElse: () => null);

    if (mounted) {
      setState(() {
        _quiz = quiz;
        _loading = false;
      });
    }
  }

  Future<void> _openResult(Quiz quiz, QuizAttempt attempt) async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentQuizResultScreen(
          quiz: quiz,
          attempt: attempt,
        ),
      ),
    );
    if (mounted) {
      await _load();
      setState(() => _actionLoading = false);
    }
  }

  Future<void> _startOrResume(Quiz quiz) async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(
                      value: Provider.of<QuizAttemptProvider>(context,
                          listen: false),
                    ),
                    ChangeNotifierProvider.value(
                      value: Provider.of<QuizProvider>(context, listen: false),
                    ),
                    ChangeNotifierProvider.value(
                      value: Provider.of<AuthProvider>(context, listen: false),
                    ),
                  ],
                  child: StudentQuizTakingScreen(quiz: quiz),
                )));
    if (mounted) {
      await _load();
      setState(() => _actionLoading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final quiz = _quiz;
    if (quiz == null) return;

    setState(() {
      if (_bookmarks.contains(quiz.id)) {
        _bookmarks.remove(quiz.id);
      } else {
        _bookmarks.add(quiz.id);
      }
    });
    await StudentBookmarkService.save(_bookmarks);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: AppLoader(message: 'Loading quiz details...')),
      );
    }

    final quiz = _quiz;
    if (quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz detail')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined, size: 54),
              const SizedBox(height: 12),
              const Text('This quiz is no longer available'),
              const SizedBox(height: 12),
              Consumer<LoadingProvider>(
                builder: (context, loadingState, _) {
                  return LoadingButton(
                    isLoading: loadingState.isLoading,
                    child: ElevatedButton(
                      onPressed: loadingState.isLoading
                          ? null
                          : () => loadingState.runAsyncAction(() async {
                                op() => Navigator.pushReplacementNamed(
                                    context, '/dashboard');
                                await Future.sync(() => (op as dynamic)());
                              }),
                      child: const Text('Go to dashboard'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    final attempts = context
        .watch<QuizAttemptProvider>()
        .studentAttempts
        .where((a) => a.quizId == quiz.id)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final inProgressAttempt =
        attempts.where((a) => !a.isSubmitted).cast<QuizAttempt?>().firstWhere(
              (a) => a != null,
              orElse: () => null,
            );
    final submittedAttempts = attempts.where((a) => a.isSubmitted).toList();
    final best = submittedAttempts.isEmpty
        ? null
        : submittedAttempts.reduce(
            (a, b) => a.scorePercentage >= b.scorePercentage ? a : b,
          );
    const attemptLimit = 1;
    final reachedLimit = submittedAttempts.length >= attemptLimit;
    final latestSubmitted =
        submittedAttempts.isEmpty ? null : submittedAttempts.first;
    final canStartNew = !reachedLimit && inProgressAttempt == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz detail'),
        actions: [
          Consumer<LoadingProvider>(
            builder: (context, loadingState, _) {
              return LoadingButton(
                isLoading: loadingState.isLoading,
                child: IconButton(
                  onPressed: loadingState.isLoading
                      ? null
                      : () => loadingState.runAsyncAction(() async {
                            final op = _toggleBookmark;
                            await Future.sync(() => (op as dynamic)());
                          }),
                  icon: Icon(
                    _bookmarks.contains(quiz.id)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quiz.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              quiz.description.isEmpty
                  ? 'No description provided'
                  : quiz.description,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Difficulty: ${quiz.difficultyText}')),
                Chip(label: Text('${quiz.questions.length} questions')),
                Chip(label: Text('Time: ${quiz.timeText}')),
                Chip(
                    label: Text(
                        'Attempts: ${submittedAttempts.length}/$attemptLimit')),
                if (best != null)
                  Chip(
                      label:
                          Text('Best score: ${best.score}/${best.totalMarks}')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                inProgressAttempt != null
                    ? 'You have an in-progress attempt. Continue where you left off.'
                    : reachedLimit
                        ? 'Attempt limit reached. You can view your submitted result.'
                        : 'You can start this quiz now.',
              ),
            ),
            const SizedBox(height: 16),
            if (quiz.config.specificTopics != null &&
                quiz.config.specificTopics!.isNotEmpty) ...[
              Text(
                'Topic tags',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quiz.config.specificTopics!
                    .map((topic) => Chip(label: Text(topic)))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Your previous attempts',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (attempts.isEmpty)
              const Text('No previous attempts')
            else
              ...attempts.map(
                (a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    a.isSubmitted
                        ? Icons.check_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  trailing: a.isSubmitted
                      ? Consumer<LoadingProvider>(
                          builder: (context, loadingState, _) {
                            return LoadingButton(
                              isLoading: loadingState.isLoading,
                              child: TextButton(
                                onPressed: loadingState.isLoading
                                    ? null
                                    : () =>
                                        loadingState.runAsyncAction(() async {
                                          op() => _openResult(quiz, a);
                                          await Future.sync(
                                              () => (op as dynamic)());
                                        }),
                                child: const Text('View'),
                              ),
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                  title: Text('${a.score}/${a.totalMarks} • ${a.durationText}'),
                  subtitle: Text(
                    '${a.startTime.day}/${a.startTime.month}/${a.startTime.year}',
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Consumer<LoadingProvider>(
                builder: (context, loadingState, _) {
                  return LoadingButton(
                    isLoading: loadingState.isLoading,
                    child: ElevatedButton(
                      onPressed: loadingState.isLoading
                          ? null
                          : () => loadingState.runAsyncAction(() async {
                                final op = _actionLoading
                                    ? null
                                    : inProgressAttempt != null
                                        ? () => _startOrResume(quiz)
                                        : reachedLimit &&
                                                latestSubmitted != null
                                            ? () => _openResult(
                                                quiz, latestSubmitted)
                                            : canStartNew
                                                ? () => _startOrResume(quiz)
                                                : null;
                                if (op != null)
                                  await Future.sync(() => (op as dynamic)());
                              }),
                      child: Text(
                        _actionLoading
                            ? 'Opening...'
                            : inProgressAttempt != null
                                ? 'Continue Quiz'
                                : reachedLimit
                                    ? 'View Results'
                                    : 'Start Quiz',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
