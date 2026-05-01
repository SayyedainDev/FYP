import '../widgets/loading_button.dart';
import '../../providers/loading_provider.dart';
import 'package:provider/provider.dart';
import 'student_quiz_taking_screen.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:io';
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../provider/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/quiz_attempt_provider.dart';
import '../core/theme/app_semantic_colors.dart';
import '../utils/app_dialogs.dart';
import '../utils/global_error_handler.dart';
import '../widgets/loaders/app_loader.dart';
import '../widgets/animation/staggered_list_item.dart';
import '../widgets/animation/hover_card.dart';
import '../widgets/animation/pressable_widget.dart';

class StudentQuizListScreen extends StatefulWidget {
  const StudentQuizListScreen({super.key});

  @override
  State<StudentQuizListScreen> createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  Map<String, QuizAttempt?> _attemptCache = {};
  bool _attemptsLoaded = false;

  ColorScheme get _cs => Theme.of(context).colorScheme;
  AppSemanticColors? get _sem =>
      Theme.of(context).extension<AppSemanticColors>();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final quizProvider = context.read<QuizProvider>();
    final attemptProvider = context.read<QuizAttemptProvider>();
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.user?.uid ?? '';

    if (uid.isEmpty) {
      _showDialogAfterBuild(() {
        AppDialogs.showSessionExpiredDialog(
          context,
          onLoginAgain: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
        );
      });
      return;
    }

    try {
      await quizProvider
          .fetchPublishedQuizzes()
          .timeout(const Duration(seconds: 30));
      await attemptProvider
          .fetchStudentAttempts(uid)
          .timeout(const Duration(seconds: 30));
      _buildAttemptCache(attemptProvider, quizProvider);
    } on TimeoutException catch (_) {
      _showDialogAfterBuild(() {
        AppDialogs.showErrorDialog(
          context,
          message:
              "The request timed out. Check your connection and try again.",
          onRetry: _loadData,
        );
      });
    } on SocketException catch (_) {
      _showDialogAfterBuild(() {
        AppDialogs.showNoInternetDialog(context, onRetry: _loadData);
      });
    } catch (e, stack) {
      GlobalErrorHandler.instance.handleError(e, stack);
    }
  }

  void _showDialogAfterBuild(VoidCallback action) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  void _buildAttemptCache(
      QuizAttemptProvider attemptProvider, QuizProvider quizProvider) {
    _attemptCache = {};
    for (final quiz in quizProvider.publishedQuizzes) {
      final attempt = attemptProvider.studentAttempts
          .where((a) => a.quizId == quiz.id)
          .fold<QuizAttempt?>(null, (prev, a) {
        if (prev == null) return a;
        // Prefer in-progress over submitted
        if (!a.isSubmitted) return a;
        return prev;
      });
      _attemptCache[quiz.id] = attempt;
    }
    setState(() => _attemptsLoaded = true);
  }

  List<Quiz> get _filteredQuizzes {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    var quizzes = quizProvider.publishedQuizzes;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      quizzes = quizzes
          .where((q) =>
              q.title.toLowerCase().contains(_searchQuery) ||
              q.description.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Apply status filter
    if (_selectedFilter != 'All') {
      quizzes = quizzes.where((q) {
        final attempt = _attemptCache[q.id];
        switch (_selectedFilter) {
          case 'Not Started':
            return attempt == null;
          case 'In Progress':
            return attempt != null && !attempt.isSubmitted;
          case 'Completed':
            return attempt != null && attempt.isSubmitted;
          default:
            return true;
        }
      }).toList();
    }

    return quizzes;
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);

    return Scaffold(
      backgroundColor: _cs.surface,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          Expanded(child: _buildContent(quizProvider)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cs.primary, _cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _cs.shadow.withValues(alpha: 0.12),
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
                color: _cs.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.quiz, color: _cs.onPrimary, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Quizzes',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Take quizzes published by your professors',
                    style: TextStyle(
                      fontSize: 14,
                      color: _cs.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            // Refresh button
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: IconButton(
              onPressed: loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { final op = _loadData; await Future.sync(() => (op as dynamic)()); }),
              icon: Icon(Icons.refresh, color: _cs.onPrimary),
              tooltip: 'Refresh',
              style: IconButton.styleFrom(
                backgroundColor: _cs.onPrimary.withValues(alpha: 0.15),
              ),
            ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final filters = ['All', 'Not Started', 'In Progress', 'Completed'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search quizzes by title...',
              hintStyle:
                  TextStyle(color: _cs.onSurfaceVariant.withValues(alpha: 0.8)),
              prefixIcon:
                  Icon(Icons.search, color: _cs.onSurfaceVariant, size: 22),
              suffixIcon: _searchQuery.isNotEmpty
                  ? Consumer<LoadingProvider>(
                    builder: (context, loadingState, _) {
                      return LoadingButton(
                        isLoading: loadingState.isLoading,
                        child: IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { op() {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      } await Future.sync(() => (op as dynamic)()); }),
                    ),
                      );
                    },
                  )
                  : null,
              filled: true,
              fillColor: _cs.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    backgroundColor: _cs.surface,
                    selectedColor: _cs.primary.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: isSelected ? _cs.primary : _cs.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    checkmarkColor: _cs.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? _cs.primary.withValues(alpha: 0.4)
                            : _cs.outlineVariant,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(QuizProvider quizProvider) {
    if (quizProvider.isLoading && !_attemptsLoaded) {
      return const Center(
        child: AppLoader(message: 'Loading quizzes...'),
      );
    }

    final quizzes = _filteredQuizzes;

    if (quizProvider.publishedQuizzes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.quiz_outlined,
        title: 'No Quizzes Available',
        subtitle: "Your professors haven't published any quizzes yet",
        showRefresh: true,
      );
    }

    if (quizzes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No Quizzes Found',
        subtitle: 'Try a different search or filter',
        showRefresh: false,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          final attempt = _attemptCache[quiz.id];
          return StaggeredListItem(
            index: index,
            child: _buildQuizCard(quiz, attempt),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showRefresh,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: _cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: _cs.onSurfaceVariant, fontSize: 14),
          ),
          if (showRefresh) ...[
            const SizedBox(height: 24),
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: ElevatedButton.icon(
              onPressed: loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { final op = _loadData; await Future.sync(() => (op as dynamic)()); }),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cs.primary,
                foregroundColor: _cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz, QuizAttempt? existingAttempt) {
    final isCompleted = existingAttempt?.isSubmitted ?? false;
    final isInProgress =
        existingAttempt != null && !existingAttempt.isSubmitted;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _cs.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isCompleted
              ? (_sem?.success ?? _cs.secondary).withValues(alpha: 0.35)
              : isInProgress
                  ? (_sem?.warning ?? _cs.tertiary).withValues(alpha: 0.35)
                  : _cs.outlineVariant,
          width: 1.5,
        ),
      ),
      child: HoverCard(
        borderRadius: BorderRadius.circular(16),
        child: PressableWidget(
          onTap: () => _handleQuizTap(quiz, existingAttempt, authProvider),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Hero(
                      tag: 'quiz-${quiz.id}',
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(quiz.config.difficulty)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.quiz_outlined,
                          color: _getDifficultyColor(quiz.config.difficulty),
                          size: 24,
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _cs.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (quiz.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                quiz.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(
                        isCompleted, isInProgress, existingAttempt),
                  ],
                ),

                const SizedBox(height: 16),

                // Info chips
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.help_outline,
                      '${quiz.questions.length} Questions',
                      _cs.primary,
                    ),
                    _buildInfoChip(
                      Icons.grade_outlined,
                      '${quiz.totalMarks} Marks',
                      _sem?.warning ?? _cs.tertiary,
                    ),
                    _buildInfoChip(
                      Icons.schedule,
                      quiz.timeText,
                      _sem?.success ?? _cs.secondary,
                    ),
                    _buildInfoChip(
                      Icons.speed,
                      quiz.difficultyText,
                      _getDifficultyColor(quiz.config.difficulty),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: Consumer<LoadingProvider>(
                    builder: (context, loadingState, _) {
                      return LoadingButton(
                        isLoading: loadingState.isLoading,
                        child: ElevatedButton.icon(
                    onPressed: loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { op() => _handleQuizTap(
                      quiz,
                      existingAttempt,
                      authProvider,
                    ); await Future.sync(() => (op as dynamic)()); }),
                    icon: Icon(
                      isCompleted
                          ? Icons.visibility
                          : isInProgress
                              ? Icons.play_arrow
                              : Icons.start,
                      size: 20,
                    ),
                    label: Text(
                      isCompleted
                          ? 'View Results (${existingAttempt!.score}/${existingAttempt.totalMarks})'
                          : isInProgress
                              ? 'Continue Quiz'
                              : 'Start Quiz',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? (_sem?.success ?? _cs.secondary)
                          : _cs.primary,
                      foregroundColor: _cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
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
      ),
    );
  }

  Widget _buildStatusBadge(
    bool isCompleted,
    bool isInProgress,
    QuizAttempt? attempt,
  ) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (_sem?.success ?? _cs.secondary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (_sem?.success ?? _cs.secondary).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: _sem?.success ?? _cs.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              attempt?.grade ?? 'Done',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _sem?.success ?? _cs.secondary,
              ),
            ),
          ],
        ),
      );
    }

    if (isInProgress) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (_sem?.warning ?? _cs.tertiary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (_sem?.warning ?? _cs.tertiary).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle,
              size: 14,
              color: _sem?.warning ?? _cs.tertiary,
            ),
            const SizedBox(width: 4),
            Text(
              'In Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _sem?.warning ?? _cs.tertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cs.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        'New',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _cs.primary,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
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
        return _sem?.success ?? _cs.secondary;
      case DifficultyLevel.medium:
        return _sem?.warning ?? _cs.tertiary;
      case DifficultyLevel.hard:
        return _sem?.danger ?? _cs.error;
      case DifficultyLevel.mixed:
        return _sem?.info ?? _cs.primary;
    }
  }

  void _handleQuizTap(
    Quiz quiz,
    QuizAttempt? existingAttempt,
    AuthProvider authProvider,
  ) {
    if (existingAttempt != null && existingAttempt.isSubmitted) {
      // View results
      context.push(
        '/student/quiz/result',
        extra: {'quiz': quiz, 'attempt': existingAttempt},
      );
    } else if (existingAttempt != null && !existingAttempt.isSubmitted) {
      // Resume directly
      Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => StudentQuizTakingScreen(quiz: quiz)))
          .then((_) => _loadData());
    } else {
      // Show start confirmation
      _showStartConfirmation(quiz);
    }
  }

  void _showStartConfirmation(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start Quiz?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quiz.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildDialogInfo(
                Icons.help_outline, '${quiz.questions.length} questions'),
            _buildDialogInfo(
                Icons.grade_outlined, '${quiz.totalMarks} total marks'),
            _buildDialogInfo(Icons.schedule, quiz.timeText),
            _buildDialogInfo(Icons.speed, 'Difficulty: ${quiz.difficultyText}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_sem?.warning ?? _cs.tertiary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      (_sem?.warning ?? _cs.tertiary).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: _sem?.warning ?? _cs.tertiary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tab switching and other activities will be monitored during the quiz.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<LoadingProvider>(
            builder: (context, loadingState, _) {
              return LoadingButton(
                isLoading: loadingState.isLoading,
                child: TextButton(
            onPressed: loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { op() => Navigator.pop(context); await Future.sync(() => (op as dynamic)()); }),
            child: const Text('Cancel'),
          ),
              );
            },
          ),
          Consumer<LoadingProvider>(
            builder: (context, loadingState, _) {
              return LoadingButton(
                isLoading: loadingState.isLoading,
                child: ElevatedButton.icon(
            onPressed: loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { op() {
              Navigator.pop(context);
              context
                  .push('/student/quiz/take', extra: quiz)
                  .then((_) => _loadData());
            } await Future.sync(() => (op as dynamic)()); }),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Start Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cs.primary,
              foregroundColor: _cs.onPrimary,
            ),
          ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(fontSize: 14, color: _cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
