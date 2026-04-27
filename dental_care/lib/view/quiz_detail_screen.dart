import '../widgets/loading_button.dart';
import '../../providers/loading_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../core/theme/app_semantic_colors.dart';
import '../service/quiz_pdf_service.dart';

class QuizDetailScreen extends StatelessWidget {
  final Quiz quiz;

  const QuizDetailScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Quiz Details'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          Consumer<LoadingProvider>(
            builder: (context, loadingState, _) {
              return LoadingButton(
                isLoading: loadingState.isLoading,
                child: IconButton(
            icon: const Icon(Icons.print),
            onPressed: loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { op() async {
              try {
                await QuizPdfService.printQuiz(quiz);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Print failed. Please try again.'),
                      backgroundColor:
                          semanticColors?.danger ?? colorScheme.error,
                    ),
                  );
                }
              }
            } await Future.sync(() => (op as dynamic)()); }),
            tooltip: 'Print Quiz',
          ),
              );
            },
          ),
          Consumer<LoadingProvider>(
            builder: (context, loadingState, _) {
              return LoadingButton(
                isLoading: loadingState.isLoading,
                child: IconButton(
            icon: const Icon(Icons.share),
            onPressed: loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { op() async {
              try {
                await QuizPdfService.shareQuiz(quiz);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Share failed. Please try again.'),
                      backgroundColor:
                          semanticColors?.danger ?? colorScheme.error,
                    ),
                  );
                }
              }
            } await Future.sync(() => (op as dynamic)()); }),
            tooltip: 'Share Quiz',
          ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildQuizInfo(context),
            _buildQuestionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colorScheme.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'quiz-${quiz.id}',
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.quiz_outlined,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (quiz.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        quiz.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatChip(
                context,
                Icons.quiz_outlined,
                '${quiz.questions.length} Questions',
                Theme.of(context).extension<AppSemanticColors>()?.info ??
                    Theme.of(context).colorScheme.primary,
              ),
              _buildStatChip(
                context,
                Icons.star_outline,
                '${quiz.totalMarks} Marks',
                Theme.of(context).extension<AppSemanticColors>()?.warning ??
                    Theme.of(context).colorScheme.tertiary,
              ),
              _buildStatChip(
                context,
                Icons.access_time,
                quiz.timeText,
                Theme.of(context).extension<AppSemanticColors>()?.success ??
                    Theme.of(context).colorScheme.secondary,
              ),
              _buildStatChip(
                context,
                Icons.speed,
                quiz.difficultyText,
                _getDifficultyColor(context, quiz.config.difficulty),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Cognitive Level', _getCognitiveLevelText()),
          _buildInfoRow(context, 'Question Types', _getQuestionTypesText()),
          _buildInfoRow(context, 'Sections', '${quiz.config.numberOfSections}'),
          _buildInfoRow(
            context,
            'Marks Distribution',
            quiz.config.marksDistribution,
          ),
          _buildInfoRow(
            context,
            'Answer Key',
            quiz.config.includeAnswerKey ? 'Included' : 'Not included',
          ),
          _buildInfoRow(
            context,
            'Explanations',
            quiz.config.explanationLevel.toUpperCase(),
          ),
          if (quiz.config.specialMode != null)
            _buildInfoRow(context, 'Quiz Mode', _getQuizModeText()),
          if (quiz.noteFileName != null)
            _buildInfoRow(context, 'Source File', quiz.noteFileName!),
          _buildInfoRow(
            context,
            'Created',
            '${quiz.createdAt.day}/${quiz.createdAt.month}/${quiz.createdAt.year} at ${quiz.createdAt.hour}:${quiz.createdAt.minute.toString().padLeft(2, '0')}',
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${quiz.questions.length} Total',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...quiz.questions.asMap().entries.map((entry) {
            return _buildQuestionCard(context, entry.key + 1, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
      BuildContext context, int number, Question question) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q$number',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getQuestionTypeColor(
                              context,
                              question.type,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  _getQuestionTypeColor(context, question.type),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getQuestionTypeLabel(question.type),
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  _getQuestionTypeColor(context, question.type),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (Theme.of(context)
                                        .extension<AppSemanticColors>()
                                        ?.warning ??
                                    Theme.of(context).colorScheme.tertiary)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${question.marks} mark${question.marks > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                      .extension<AppSemanticColors>()
                                      ?.warning ??
                                  Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (question.section != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              question.section!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Text
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Options (for MCQ and True/False)
          if (question.options != null && question.options!.isNotEmpty) ...[
            ...question.options!.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value;
              final optionLetter = String.fromCharCode(65 + optionIndex);
              final isCorrect = question.correctAnswer == option;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect && quiz.config.includeAnswerKey
                      ? (Theme.of(context)
                                  .extension<AppSemanticColors>()
                                  ?.success ??
                              Theme.of(context).colorScheme.secondary)
                          .withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect && quiz.config.includeAnswerKey
                        ? (Theme.of(context)
                                    .extension<AppSemanticColors>()
                                    ?.success ??
                                Theme.of(context).colorScheme.secondary)
                            .withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCorrect && quiz.config.includeAnswerKey
                            ? Theme.of(context)
                                    .extension<AppSemanticColors>()
                                    ?.success ??
                                Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          optionLetter,
                          style: TextStyle(
                            color: isCorrect && quiz.config.includeAnswerKey
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isCorrect && quiz.config.includeAnswerKey)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context)
                                .extension<AppSemanticColors>()
                                ?.success ??
                            Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // Answer (if not MCQ/True-False and answer key is included)
          if (quiz.config.includeAnswerKey &&
              (question.options == null || question.options!.isEmpty)) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (Theme.of(context)
                            .extension<AppSemanticColors>()
                            ?.success ??
                        Theme.of(context).colorScheme.secondary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (Theme.of(context)
                              .extension<AppSemanticColors>()
                              ?.success ??
                          Theme.of(context).colorScheme.secondary)
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context)
                            .extension<AppSemanticColors>()
                            ?.success ??
                        Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Answer:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                    .extension<AppSemanticColors>()
                                    ?.success ??
                                Theme.of(context).colorScheme.secondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.correctAnswerText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Explanation (if included)
          if (question.explanation != null &&
              question.explanation!.isNotEmpty &&
              quiz.config.includeAnswerKey) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explanation:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.explanation!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
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

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(BuildContext context, DifficultyLevel difficulty) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    switch (difficulty) {
      case DifficultyLevel.easy:
        return semanticColors?.success ?? colorScheme.secondary;
      case DifficultyLevel.medium:
        return semanticColors?.warning ?? colorScheme.tertiary;
      case DifficultyLevel.hard:
        return semanticColors?.danger ?? colorScheme.error;
      case DifficultyLevel.mixed:
        return colorScheme.secondary;
    }
  }

  Color _getQuestionTypeColor(BuildContext context, QuestionType type) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    switch (type) {
      case QuestionType.mcq:
        return semanticColors?.info ?? colorScheme.primary;
      case QuestionType.trueFalse:
        return semanticColors?.success ?? colorScheme.secondary;
      case QuestionType.shortAnswer:
        return semanticColors?.warning ?? colorScheme.tertiary;
      case QuestionType.longAnswer:
        return semanticColors?.danger ?? colorScheme.error;
      case QuestionType.fillInTheBlanks:
        return colorScheme.secondary;
      case QuestionType.scenarioBased:
        return colorScheme.tertiary;
    }
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        return 'MCQ';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.longAnswer:
        return 'Long Answer';
      case QuestionType.fillInTheBlanks:
        return 'Fill Blanks';
      case QuestionType.scenarioBased:
        return 'Scenario';
    }
  }

  String _getCognitiveLevelText() {
    switch (quiz.config.cognitiveLevel) {
      case CognitiveLevel.knowledge:
        return 'Knowledge (Recall)';
      case CognitiveLevel.understanding:
        return 'Understanding';
      case CognitiveLevel.application:
        return 'Application';
      case CognitiveLevel.analysis:
        return 'Analysis';
      case CognitiveLevel.mixed:
        return 'Mixed (Bloom\'s Taxonomy)';
    }
  }

  String _getQuestionTypesText() {
    return quiz.config.questionTypes
        .map((t) => _getQuestionTypeLabel(t))
        .join(', ');
  }

  String _getQuizModeText() {
    switch (quiz.config.specialMode!) {
      case QuizMode.exam:
        return 'Exam Mode (strict)';
      case QuizMode.practice:
        return 'Practice Mode';
      case QuizMode.adaptive:
        return 'Adaptive Mode';
      case QuizMode.conceptual:
        return 'Conceptual Mastery';
      case QuizMode.analytical:
        return 'Analytical/Critical Thinking';
    }
  }
}
