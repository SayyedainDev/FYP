import 'student_profile_screen.dart';
import 'student_quiz_detail_screen.dart';
import 'student_notifications_screen.dart';
import 'student_analytics_screen.dart';
import 'student_3d_disease_models_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../provider/auth_provider.dart';
import '../providers/quiz_attempt_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/loaders/skeletons.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _loading = true;
  String? _loadError;
  final Map<String, QuizAttempt?> _attemptMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final quizProvider = context.read<QuizProvider>();
    final attemptProvider = context.read<QuizAttemptProvider>();
    final uid = auth.user?.uid ?? '';

    if (uid.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      _loadError = null;
      await quizProvider
          .fetchPublishedQuizzes()
          .timeout(const Duration(seconds: 30));
      await attemptProvider
          .fetchStudentAttempts(uid)
          .timeout(const Duration(seconds: 30));
      _attemptMap.clear();
      for (final quiz in quizProvider.publishedQuizzes) {
        final attempts = attemptProvider.studentAttempts
            .where((a) => a.quizId == quiz.id)
            .toList();
        attempts.sort((a, b) => b.startTime.compareTo(a.startTime));
        _attemptMap[quiz.id] = attempts.isEmpty ? null : attempts.first;
      }
    } on TimeoutException {
      _loadError = 'Loading timed out. Please check your connection.';
    } catch (_) {
      _loadError = 'Unable to load dashboard data right now.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final quizzes = context.watch<QuizProvider>().publishedQuizzes;
    final attempts = context.watch<QuizAttemptProvider>().studentAttempts;
    final firstName = (auth.userName ?? 'Student').split(' ').first;

    if (_loading) {
      return const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                ProfileSkeleton(),
                SizedBox(height: 16),
                DashboardStatsSkeleton(),
                SizedBox(height: 16),
                QuizCardSkeleton(),
                SizedBox(height: 12),
                QuizCardSkeleton(),
              ],
            ),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 52),
                  const SizedBox(height: 12),
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final completed = attempts.where((a) => a.isSubmitted).toList();
    final avgScore = completed.isEmpty
        ? 0.0
        : completed.map((a) => a.scorePercentage).reduce((a, b) => a + b) /
            completed.length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(firstName: firstName, greeting: _greeting()),
                const SizedBox(height: 20),
                const _ThreeDDiseaseModelsCard(),
                const SizedBox(height: 20),
                _AssignedQuizzesPanel(quizzes: quizzes, attempts: _attemptMap),
                const SizedBox(height: 20),
                _QuickStats(
                  completed: completed.length,
                  average: avgScore,
                ),
                const SizedBox(height: 20),
                _RecentActivity(attempts: attempts),
                const SizedBox(height: 20),
                _Recommended(quizzes: quizzes, attempts: attempts),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.firstName, required this.greeting});

  final String firstName;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $firstName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StudentNotificationsScreen())),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StudentProfileScreen())),
          child: CircleAvatar(
            radius: 20,
            child: Text(firstName.isEmpty ? 'S' : firstName[0].toUpperCase()),
          ),
        ),
      ],
    );
  }
}

class _ThreeDDiseaseModelsCard extends StatelessWidget {
  const _ThreeDDiseaseModelsCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.view_in_ar_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3D Disease Models',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Open the 360 degree tooth disease viewer with pinch and zoom controls.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Student3DDiseaseModelsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _AssignedQuizzesPanel extends StatelessWidget {
  const _AssignedQuizzesPanel({required this.quizzes, required this.attempts});

  final List<Quiz> quizzes;
  final Map<String, QuizAttempt?> attempts;

  String _dueText(Quiz quiz) {
    // Better logic: Instead of a strict 7-day rule, just show when it was created unless quiz has an actual due date
    return 'Posted on: ${DateFormat('d MMM yyyy').format(quiz.createdAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Available Quizzes',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Chip(label: Text('${quizzes.length}')),
            ],
          ),
          const SizedBox(height: 12),
          if (quizzes.isEmpty)
            const _SimpleEmpty(
              icon: Icons.assignment_outlined,
              title: 'No quizzes available right now.',
            )
          else
            ...quizzes.take(4).map((quiz) {
              final attempt = attempts[quiz.id];
              final submitted = attempt?.isSubmitted ?? false;
              final inProgress = attempt != null && !submitted;
              final label = submitted
                  ? 'Completed'
                  : inProgress
                      ? 'In progress'
                      : 'Not started';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.surfaceContainerLow,
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quiz.difficultyText,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dueText(quiz),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: submitted
                            ? Colors.green.withValues(alpha: 0.2)
                            : inProgress
                                ? Colors.amber.withValues(alpha: 0.25)
                                : Colors.grey.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    StudentQuizDetailScreen(quizId: quiz.id)));
                      },
                      child: Text(submitted
                          ? 'View Result'
                          : inProgress
                              ? 'Continue'
                              : 'Start'),
                    )
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.completed,
    required this.average,
  });

  final int completed;
  final double average;

  Widget _tile(BuildContext context, String label, String value) {
    return Expanded(
      child: InkWell(
        onTap: () {
          final quizAttemptProvider = context.read<QuizAttemptProvider>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: quizAttemptProvider),
                ],
                child: const StudentAnalyticsScreen(),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tile(context, 'Quizzes Completed', '$completed'),
        const SizedBox(width: 12),
        _tile(context, 'Average Score', '${average.toStringAsFixed(1)}%'),
      ],
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.attempts});

  final List<QuizAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final submitted = attempts.where((a) => a.isSubmitted).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudentAnalyticsScreen())),
                child: const Text('View logic'),
              ),
            ],
          ),
          if (submitted.isEmpty)
            const _SimpleEmpty(
              icon: Icons.history_toggle_off,
              title: 'No activity yet',
            )
          else
            ...submitted.take(5).map((a) => ListTile(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              StudentQuizDetailScreen(quizId: a.quizId))),
                  contentPadding: EdgeInsets.zero,
                  title: Text(a.quizTitle),
                  subtitle:
                      Text(DateFormat('d MMM, HH:mm').format(a.startTime)),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: a.isPassed
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${a.scorePercentage.toStringAsFixed(0)}%'),
                  ),
                )),
        ],
      ),
    );
  }
}

class _Recommended extends StatelessWidget {
  const _Recommended({required this.quizzes, required this.attempts});

  final List<Quiz> quizzes;
  final List<QuizAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final attemptedQuizIds = attempts.map((e) => e.quizId).toSet();
    final recommended =
        quizzes.where((q) => !attemptedQuizIds.contains(q.id)).take(5).toList();

    if (recommended.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended for you',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommended
                .map((q) => ActionChip(
                      label: Text(q.title),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  StudentQuizDetailScreen(quizId: q.id))),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SimpleEmpty extends StatelessWidget {
  const _SimpleEmpty({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: colorScheme.outline),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
