import 'quiz_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/quiz.dart';
import '../provider/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/quiz_provider.dart';
import '../service/quiz_pdf_service.dart';
import '../core/responsive/app_breakpoints.dart';
import '../core/theme/app_semantic_colors.dart';
import '../widgets/loaders/app_loader.dart';
import '../widgets/animation/staggered_list_item.dart';
import '../widgets/animation/hover_card.dart';
import '../widgets/animation/pressable_widget.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final Set<String> _busyQuizIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final authProvider = context.read<AuthProvider>();
    final quizProvider = context.read<QuizProvider>();

    if (authProvider.user != null) {
      await quizProvider.fetchQuizzes(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final quizProvider = Provider.of<QuizProvider>(context);

    if (authProvider.user == null) {
      return const Center(child: Text('Please login to view quizzes'));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildContent(quizProvider, authProvider)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = AppBreakpoints.horizontalPadding(context) + 12;
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.quiz, color: colorScheme.onPrimary, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Library',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate, review, and share assessments with your students.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NavigationProvider>().setPage('Create Quiz');
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.secondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(QuizProvider quizProvider, AuthProvider authProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    if (quizProvider.isLoading) {
      return const Center(
        child: AppLoader(message: 'Loading quizzes...'),
      );
    }

    if (quizProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading quizzes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              quizProvider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadQuizzes,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (quizProvider.quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Quizzes Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first quiz to get started',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NavigationProvider>().setPage('Create Quiz');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final device = AppBreakpoints.fromWidth(width);
    final crossAxisCount = switch (device) {
      AppDeviceType.mobile => 1,
      AppDeviceType.tablet => 2,
      AppDeviceType.desktop => 2,
      AppDeviceType.largeDesktop => 3,
    };
    final mainAxisExtent = switch (device) {
      AppDeviceType.mobile => 220.0,
      AppDeviceType.tablet => 205.0,
      AppDeviceType.desktop => 190.0,
      AppDeviceType.largeDesktop => 185.0,
    };

    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(
          AppBreakpoints.horizontalPadding(context),
          12,
          AppBreakpoints.horizontalPadding(context),
          20,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          mainAxisExtent: mainAxisExtent,
        ),
        itemCount: quizProvider.quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizProvider.quizzes[index];
          return StaggeredListItem(
            index: index,
            child: _buildQuizCard(quiz, quizProvider, authProvider),
          );
        },
      ),
    );
  }

  Widget _buildQuizCard(
    Quiz quiz,
    QuizProvider quizProvider,
    AuthProvider authProvider,
  ) {
    final difficultyColor = _getDifficultyColor(quiz.config.difficulty);
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final publishColor = semantic?.success ?? colorScheme.primary;
    final closeColor = semantic?.warning ?? colorScheme.secondary;
    final infoColor = semantic?.info ?? colorScheme.secondary;
    final isBusy = _busyQuizIds.contains(quiz.id);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: HoverCard(
        borderRadius: BorderRadius.circular(18),
        child: PressableWidget(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => QuizDetailScreen(quiz: quiz)));
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'quiz-${quiz.id}',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: difficultyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.quiz_outlined,
                          color: difficultyColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quiz.description.isNotEmpty
                                ? quiz.description
                                : 'No description added',
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: difficultyColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: difficultyColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        quiz.difficultyText,
                        style: TextStyle(
                          color: difficultyColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildStatusBadge(context, quiz.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.help_outline,
                      '${quiz.questions.length} Questions',
                      infoColor,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.grade_outlined,
                      '${quiz.totalMarks} Marks',
                      closeColor,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.schedule, quiz.timeText, publishColor),
                    const Spacer(),
                    if (quiz.isDraft)
                      _buildActionButton(
                        isBusy ? 'Publishing...' : 'Publish',
                        Icons.publish,
                        publishColor,
                        () => _publishQuiz(quiz, quizProvider),
                        isLoading: isBusy,
                      ),
                    if (quiz.isPublished)
                      _buildActionButton(
                        isBusy ? 'Closing...' : 'Close',
                        Icons.lock_outline,
                        closeColor,
                        () => _closeQuiz(quiz, quizProvider),
                        isLoading: isBusy,
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Share',
                      onPressed: isBusy
                          ? null
                          : () async {
                              try {
                                await QuizPdfService.shareQuiz(quiz);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Share failed. Please try again.'),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: Icon(
                        Icons.share,
                        color: colorScheme.secondary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: semantic?.danger ?? colorScheme.error,
                      ),
                      tooltip: 'Delete',
                      onPressed: isBusy
                          ? null
                          : () => _confirmDelete(
                                context,
                                quiz,
                                quizProvider,
                                authProvider,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Created ${_formatDate(quiz.createdAt)}',
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    if (quiz.noteFileName != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.attach_file,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          quiz.noteFileName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Theme.of(context).extension<AppSemanticColors>()?.success ??
            Theme.of(context).colorScheme.primary;
      case DifficultyLevel.medium:
        return Theme.of(context).extension<AppSemanticColors>()?.warning ??
            Theme.of(context).colorScheme.secondary;
      case DifficultyLevel.hard:
        return Theme.of(context).extension<AppSemanticColors>()?.danger ??
            Theme.of(context).colorScheme.error;
      case DifficultyLevel.mixed:
        return Theme.of(context).extension<AppSemanticColors>()?.info ??
            Theme.of(context).colorScheme.tertiary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Quiz quiz,
    QuizProvider quizProvider,
    AuthProvider authProvider,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text(
          'Are you sure you want to delete "${quiz.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: semantic?.danger ?? colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await quizProvider.deleteQuiz(quiz.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Quiz deleted successfully'
                  : 'Failed to delete quiz: ${quizProvider.errorMessage}',
            ),
            backgroundColor: success
                ? (semantic?.success ?? colorScheme.primary)
                : colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(BuildContext context, QuizStatus status) {
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final colorScheme = Theme.of(context).colorScheme;
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case QuizStatus.draft:
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        label = 'Draft';
        icon = Icons.edit_outlined;
        break;
      case QuizStatus.published:
        textColor = semantic?.success ?? colorScheme.primary;
        bgColor = textColor.withValues(alpha: 0.16);
        label = 'Published';
        icon = Icons.check_circle_outline;
        break;
      case QuizStatus.closed:
        textColor = semantic?.danger ?? colorScheme.error;
        bgColor = textColor.withValues(alpha: 0.16);
        label = 'Closed';
        icon = Icons.lock_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap,
      {bool isLoading = false}) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      splashColor: color.withValues(alpha: 0.2),
      highlightColor: color.withValues(alpha: 0.1),
      hoverColor: color.withValues(alpha: 0.08),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishQuiz(Quiz quiz, QuizProvider quizProvider) async {
    if (_busyQuizIds.contains(quiz.id)) return;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Publish Quiz?'),
        content: Text(
          'Publishing "${quiz.title}" will make it available to all students. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: semantic?.success ?? colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        setState(() => _busyQuizIds.add(quiz.id));
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => PopScope(
            canPop: false,
            child: const AlertDialog(
              content: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 14),
                  Expanded(child: Text('Publishing quiz...')),
                ],
              ),
            ),
          ),
        );
      }

      final success = await quizProvider.publishQuiz(quiz.id);
      if (mounted) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        setState(() => _busyQuizIds.remove(quiz.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Quiz published successfully!'
                : 'Failed to publish quiz'),
            backgroundColor: success
                ? (semantic?.success ?? colorScheme.primary)
                : colorScheme.error,
          ),
        );
        if (success) _loadQuizzes();
      }
    }
  }

  Future<void> _closeQuiz(Quiz quiz, QuizProvider quizProvider) async {
    if (_busyQuizIds.contains(quiz.id)) return;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Close Quiz?'),
        content: Text(
          'Closing "${quiz.title}" will prevent students from taking it. Existing results will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: semantic?.warning ?? colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        setState(() => _busyQuizIds.add(quiz.id));
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => PopScope(
            canPop: false,
            child: const AlertDialog(
              content: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 14),
                  Expanded(child: Text('Closing quiz...')),
                ],
              ),
            ),
          ),
        );
      }

      final success = await quizProvider.closeQuiz(quiz.id);
      if (mounted) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        setState(() => _busyQuizIds.remove(quiz.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Quiz closed successfully' : 'Failed to close quiz'),
            backgroundColor: success
                ? (semantic?.success ?? colorScheme.primary)
                : colorScheme.error,
          ),
        );
        if (success) _loadQuizzes();
      }
    }
  }
}
