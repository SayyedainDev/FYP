import '../widgets/loading_button.dart';
import '../../providers/loading_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../core/animation_constants.dart';
import '../core/theme/app_semantic_colors.dart';
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../providers/quiz_attempt_provider.dart';
import '../widgets/loaders/app_loader.dart';

class StudentQuizResultScreen extends StatefulWidget {
  final Quiz quiz;
  final QuizAttempt attempt;

  const StudentQuizResultScreen({
    super.key,
    required this.quiz,
    required this.attempt,
  });

  @override
  State<StudentQuizResultScreen> createState() =>
      _StudentQuizResultScreenState();
}

class _StudentQuizResultScreenState extends State<StudentQuizResultScreen> {
  late final ConfettiController _confettiCtrl;
  bool _animateScore = false;
  late QuizAttempt _currentAttempt;
  Timer? _pollingTimer;
  bool _isGradingError = false;

  Quiz get quiz => widget.quiz;
  QuizAttempt get attempt => _currentAttempt;

  @override
  void initState() {
    super.initState();
    _currentAttempt = widget.attempt;
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));

    if (_currentAttempt.isGraded) {
      _startInitialAnimations();
    } else {
      _startPolling();
    }
  }

  void _startInitialAnimations() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _animateScore = true);
    });

    if (attempt.scorePercentage >= 50) {
      Future.delayed(AppDurations.normal, () {
        if (!mounted) return;
        _confettiCtrl.play();
      });
    }
  }

  void _startPolling() {
    int attempts = 0;
    bool isFetching = false;
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;
      if (attempts >= 15) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isGradingError = true;
          });
        }
        return;
      }

      if (!mounted || isFetching) return;
      isFetching = true;
      try {
        final provider = context.read<QuizAttemptProvider>();
        final latest = await provider.getAttemptResult(_currentAttempt.id);
        if (latest != null && mounted) {
          setState(() {
            _currentAttempt = latest;
          });
          if (latest.isGraded) {
            timer.cancel();
            _startInitialAnimations();
          }
        }
      } finally {
        isFetching = false;
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_currentAttempt.isGraded) {
      return Scaffold(
        body: Center(
          child: _isGradingError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    const Text('Grading takes longer than expected.'),
                    const SizedBox(height: 8),
                    Consumer<LoadingProvider>(
                      builder: (context, loadingState, _) {
                        return LoadingButton(
                          isLoading: loadingState.isLoading,
                          child: ElevatedButton(
                      onPressed: loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { op() {
                        setState(() {
                          _isGradingError = false;
                        });
                        _startPolling();
                      } await Future.sync(() => (op as dynamic)()); }),
                      child: const Text('Try Again'),
                    ),
                        );
                      },
                    ),
                  ],
                )
              : const AppLoader(message: 'Evaluating your answers...'),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final warning = semantic?.warning ?? colorScheme.secondary;
    final answeredCount = attempt.responses
        .where((r) => r.selectedOption != null && r.selectedOption! >= 0)
        .length;
    final correctCount =
        attempt.responses.where((r) => r.isCorrect == true).length;
    final incorrectCount = answeredCount - correctCount;
    final unansweredCount = quiz.questions.length - answeredCount;
    final pct = attempt.scorePercentage;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildScoreHero(pct),

                      const SizedBox(height: 20),

                      // Statistics row
                      _buildStatsRow(
                        correctCount,
                        incorrectCount,
                        unansweredCount,
                      ),

                      const SizedBox(height: 20),

                      if (attempt.totalViolations > 0) _buildViolationCard(),

                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Detailed Review',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...quiz.questions.asMap().entries.map(
                        (entry) {
                          final idx = entry.key;
                          final question = entry.value;
                          final response = attempt.responses.firstWhere(
                            (r) => r.questionId == question.id,
                            orElse: () => QuizResponse(
                              questionId: question.id,
                              selectedOption: null,
                              isCorrect: false,
                            ),
                          );
                          return _buildQuestionReview(
                            idx + 1,
                            question,
                            response,
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (attempt.scorePercentage >= 80)
            Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                child: ConfettiWidget(
                  confettiController: _confettiCtrl,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.08,
                  numberOfParticles: 20,
                  gravity: 0.2,
                ),
              ),
            )
          else if (attempt.scorePercentage >= 50)
            Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                child: ConfettiWidget(
                  confettiController: _confettiCtrl,
                  blastDirection: 1.57,
                  blastDirectionality: BlastDirectionality.directional,
                  shouldLoop: false,
                  emissionFrequency: 0.05,
                  numberOfParticles: 8,
                  gravity: 0.3,
                ),
              ),
            )
          else
            Positioned(
              top: 106,
              left: 24,
              right: 24,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppDurations.normal,
                curve: AppCurves.enter,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: warning.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'Keep going — every attempt builds mastery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final success = semantic?.success ?? colorScheme.primary;
    final danger = semantic?.danger ?? colorScheme.error;
    final headerBase = attempt.isPassed ? success : danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            headerBase.withValues(alpha: 0.92),
            headerBase,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: IconButton(
              onPressed: loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { op() => Navigator.pop(context); await Future.sync(() => (op as dynamic)()); }),
              icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
            ),
                );
              },
            ),
            const SizedBox(width: 8),
            Hero(
              tag: 'quiz-${quiz.id}',
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  color: colorScheme.onPrimary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Results',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attempt.quizTitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                attempt.isPassed ? '✓ PASSED' : '✗ FAILED',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHero(double percentage) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final success = semantic?.success ?? colorScheme.primary;
    final danger = semantic?.danger ?? colorScheme.error;
    final info = semantic?.info ?? colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular progress + Grade
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                      begin: 0, end: _animateScore ? percentage / 100 : 0),
                  duration: AppDurations.slow,
                  curve: AppCurves.smooth,
                  builder: (context, value, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(120, 120),
                          painter: _RingProgressPainter(
                            progress: value,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            progressColor: attempt.isPassed ? success : danger,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(value * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: attempt.isPassed ? success : danger,
                              ),
                            ),
                            Text(
                              attempt.grade,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 40),

              // Score details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedScoreDetailRow(),
                  const SizedBox(height: 10),
                  _buildScoreDetailRow(
                    Icons.schedule,
                    'Time Taken',
                    attempt.durationText,
                    info,
                  ),
                  const SizedBox(height: 10),
                  _buildScoreDetailRow(
                    Icons.help_outline,
                    'Questions',
                    '${quiz.questions.length}',
                    colorScheme.secondary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDetailRow(
      IconData icon, String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: colorScheme.onSurfaceVariant)),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface)),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedScoreDetailRow() {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: _animateScore ? attempt.score : 0),
      duration: AppDurations.slow,
      curve: AppCurves.smooth,
      builder: (context, value, _) {
        return _buildScoreDetailRow(
          Icons.grade_outlined,
          'Score',
          '$value / ${attempt.totalMarks}',
          semantic?.info ?? colorScheme.tertiary,
        );
      },
    );
  }

  Widget _buildStatsRow(
    int correct,
    int incorrect,
    int unanswered,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    return Row(
      children: [
        Expanded(
            child: _buildStatCard('Correct', correct,
                semantic?.success ?? colorScheme.primary, Icons.check_circle)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Incorrect', incorrect,
                semantic?.danger ?? colorScheme.error, Icons.cancel)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Unanswered',
                unanswered,
                semantic?.warning ?? colorScheme.secondary,
                Icons.remove_circle)),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final warning = semantic?.warning ?? colorScheme.secondary;
    final danger = semantic?.danger ?? colorScheme.error;
    final info = semantic?.info ?? colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: warning, size: 22),
              const SizedBox(width: 8),
              Text(
                'Monitoring Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (attempt.tabSwitchCount > 0)
            _buildViolationRow(
              Icons.tab,
              'Tab switches',
              '${attempt.tabSwitchCount} detected',
              warning,
            ),
          if (attempt.fullscreenExitCount > 0)
            _buildViolationRow(
              Icons.fullscreen_exit,
              'Fullscreen exits',
              '${attempt.fullscreenExitCount} detected',
              danger,
            ),
          if (attempt.inactivityCount > 0)
            _buildViolationRow(
              Icons.hourglass_empty,
              'Inactivity warnings',
              '${attempt.inactivityCount} detected',
              info,
            ),
        ],
      ),
    );
  }

  Widget _buildViolationRow(
      IconData icon, String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReview(
    int number,
    Question question,
    QuizResponse response,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final success = semantic?.success ?? colorScheme.primary;
    final danger = semantic?.danger ?? colorScheme.error;
    final warning = semantic?.warning ?? colorScheme.secondary;
    final info = semantic?.info ?? colorScheme.tertiary;
    final isCorrect = response.isCorrect == true;
    final wasAnswered =
        response.selectedOption != null && response.selectedOption! >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect
              ? success.withValues(alpha: 0.35)
              : wasAnswered
                  ? danger.withValues(alpha: 0.35)
                  : warning.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? success.withValues(alpha: 0.15)
                      : wasAnswered
                          ? danger.withValues(alpha: 0.15)
                          : warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q$number',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isCorrect
                        ? success
                        : wasAnswered
                            ? danger
                            : warning,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCorrect
                    ? Icons.check_circle
                    : wasAnswered
                        ? Icons.cancel
                        : Icons.remove_circle,
                size: 20,
                color: isCorrect
                    ? success
                    : wasAnswered
                        ? danger
                        : warning,
              ),
              const SizedBox(width: 4),
              Text(
                isCorrect
                    ? 'Correct'
                    : wasAnswered
                        ? 'Incorrect'
                        : 'Not Answered',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCorrect
                      ? success
                      : wasAnswered
                          ? danger
                          : warning,
                ),
              ),
              const Spacer(),
              Text(
                '${question.marks} mark${question.marks > 1 ? "s" : ""}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Question text
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // Options with correct/incorrect highlighting
          if (question.options != null)
            ...question.options!.asMap().entries.map((entry) {
              final idx = entry.key;
              final option = entry.value;
              final isCorrectOption = idx == question.correctIndex;
              final isStudentChoice = response.selectedOption == idx;
              final letter = String.fromCharCode(65 + idx);

              Color bgColor;
              Color borderColor;
              Color textColor;

              if (isCorrectOption) {
                bgColor = success.withValues(alpha: 0.10);
                borderColor = success.withValues(alpha: 0.4);
                textColor = success;
              } else if (isStudentChoice) {
                bgColor = danger.withValues(alpha: 0.10);
                borderColor = danger.withValues(alpha: 0.4);
                textColor = danger;
              } else {
                bgColor = colorScheme.surfaceContainerLowest;
                borderColor = colorScheme.outlineVariant;
                textColor = colorScheme.onSurfaceVariant;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isCorrectOption
                            ? success.withValues(alpha: 0.8)
                            : isStudentChoice
                                ? danger.withValues(alpha: 0.8)
                                : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: (isCorrectOption || isStudentChoice)
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: (isCorrectOption || isStudentChoice)
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isCorrectOption)
                      Icon(Icons.check_circle, color: success, size: 18),
                    if (isStudentChoice && !isCorrectOption)
                      Icon(Icons.cancel, color: danger, size: 18),
                  ],
                ),
              );
            }),

          // Explanation
          if (question.explanation != null &&
              question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: info.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _RingProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const stroke = 10.0;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
