import '../widgets/loading_button.dart';
import '../../providers/loading_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../provider/auth_provider.dart';
import '../providers/quiz_attempt_provider.dart';
import '../providers/quiz_provider.dart';
import '../core/adaptive_modal.dart';

import '../core/animation_constants.dart';
import '../core/responsive/app_breakpoints.dart';
import '../core/theme/app_semantic_colors.dart';
import '../utils/web_interop_stub.dart'
    if (dart.library.html) '../utils/web_interop_web.dart' as web;
import '../widgets/loaders/app_loader.dart';
import '../widgets/animation/pressable_widget.dart';
import 'student_quiz_result_screen.dart';

class StudentQuizTakingScreen extends StatefulWidget {
  final Quiz quiz;
  final bool isReview;

  const StudentQuizTakingScreen(
      {super.key, required this.quiz, this.isReview = false});

  @override
  State<StudentQuizTakingScreen> createState() =>
      _StudentQuizTakingScreenState();
}

class _StudentQuizTakingScreenState extends State<StudentQuizTakingScreen> {
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSubmitting = false;
  bool _attemptStarted = false;
  List<int> _questionOrder = [];
  final FocusNode _keyboardFocusNode = FocusNode();
  final Set<String> _flaggedQuestions = {};

  // Anti-cheating state
  Timer? _inactivityTimer;
  double _previousProgress = 0;

  // Web event subscriptions
  StreamSubscription? _visibilitySubscription;
  StreamSubscription? _blurSubscription;
  StreamSubscription? _fullscreenSubscription;
  StreamSubscription? _beforePrintSubscription;
  web.StyleElement? _printBlockStyle;
  web.StyleElement? _selectBlockStyle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAttempt();
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inactivityTimer?.cancel();
    _cleanupWebListeners();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  // ─── Anti-Cheating Setup ─────────────────────────────────────────────

  void _setupAntiCheating() {
    if (!kIsWeb) return;

    try {
      final dynamic doc = web.document;
      // 1. Tab switch detection via visibilitychange and blur
      _visibilitySubscription = (doc.onVisibilityChange as Stream).listen((_) {
        if ((doc.hidden as bool?) ?? false) {
          _onTabSwitch();
        }
      });

      _blurSubscription = web.window.onBlur.listen((_) {
        _onTabSwitch();
      });

      // 2. Text selection disabled via CSS
      _selectBlockStyle = web.StyleElement()
        ..text =
            '* { user-select: none !important; -webkit-user-select: none !important; }';
      (doc.head as dynamic)?.append(_selectBlockStyle!);

      // 3. Screenshot/Print block
      _printBlockStyle = web.StyleElement()
        ..text = '@media print { body { display: none !important; } }';
      (doc.head as dynamic)?.append(_printBlockStyle!);

      try {
        final printMedia = web.window.matchMedia('print');
        _beforePrintSubscription = printMedia.onChange.listen((_) {
          debugPrint('⚠️ Print attempt detected');
        });
      } catch (_) {
        // matchMedia print detection not available
      }

      // 4. Fullscreen change detection
      _fullscreenSubscription = web.document.onFullscreenChange.listen((_) {
        if (web.document.fullscreenElement == null && _attemptStarted) {
          _onFullscreenExit();
        }
      });

      // 5. Inactivity timer (3 minutes)
      _resetInactivityTimer();

      debugPrint('🔒 Anti-cheating measures activated');
    } catch (e) {
      debugPrint('⚠️ Error setting up anti-cheating: $e');
    }
  }

  void _cleanupWebListeners() {
    _visibilitySubscription?.cancel();
    _blurSubscription?.cancel();
    _fullscreenSubscription?.cancel();
    _beforePrintSubscription?.cancel();
    _printBlockStyle?.remove();
    _selectBlockStyle?.remove();
  }

  void _requestFullscreen() {
    if (!kIsWeb) return;
    try {
      web.document.documentElement?.requestFullscreen();
    } catch (e) {
      debugPrint('⚠️ Fullscreen request failed: $e');
    }
  }

  void _onTabSwitch() {
    if (!_attemptStarted || _isSubmitting) return;
    final attemptProvider = context.read<QuizAttemptProvider>();
    final attempt = attemptProvider.currentAttempt;
    if (attempt == null || attempt.isSubmitted) return;

    attemptProvider.incrementViolation('tabSwitch');
    final count = attempt.tabSwitchCount + 1;

    if (count >= 3) {
      // Auto-submit
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAutoSubmitDialog(
              'Too many tab switches! Your quiz has been auto-submitted.');
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showAdaptiveAppDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: (Theme.of(ctx)
                                .extension<AppSemanticColors>()
                                ?.warning ??
                            Theme.of(ctx).colorScheme.tertiary)
                        .withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  const Text('Warning'),
                ],
              ),
              content: Text(
                'Leaving the quiz tab has been recorded ($count/3 times).\n\nAfter 3 violations, your quiz will be auto-submitted.',
              ),
              actions: [
                Consumer<LoadingProvider>(
                  builder: (context, loadingState, _) {
                    return LoadingButton(
                      isLoading: loadingState.isLoading,
                      child: ElevatedButton(
                        onPressed: loadingState.isLoading
                            ? null
                            : () => loadingState.runAsyncAction(() async {
                                  op() => Navigator.pop(ctx);
                                  await Future.sync(() => (op as dynamic)());
                                }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.primary,
                          foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
                        ),
                        child: const Text('I Understand'),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
      });
    }
  }

  void _onFullscreenExit() {
    if (!_attemptStarted || _isSubmitting) return;
    final attemptProvider = context.read<QuizAttemptProvider>();
    attemptProvider.incrementViolation('fullscreenExit');
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();

    _inactivityTimer = Timer(const Duration(minutes: 3), () {
      if (!mounted || _isSubmitting) return;
      final attemptProvider = context.read<QuizAttemptProvider>();
      attemptProvider.incrementViolation('inactivity');

      showAdaptiveAppDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Are you still there?'),
          content: const Text(
            'No activity has been detected for 3 minutes. Please click below to continue your quiz.',
          ),
          actions: [
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: ElevatedButton(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              op() {
                                Navigator.pop(ctx);
                                _resetInactivityTimer();
                              }

                              await Future.sync(() => (op as dynamic)());
                            }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(ctx).colorScheme.primary,
                      foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
                    ),
                    child: const Text('I\'m Here'),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  void _recordInteraction() {
    _resetInactivityTimer();
  }

  void _selectOption(
      Question question, int optionIndex, QuizAttemptProvider attemptProvider) {
    if (widget.isReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This is a review. You cannot modify answers.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _recordInteraction();
    attemptProvider.saveResponse(question.id, optionIndex);
  }

  // ─── Quiz Logic ──────────────────────────────────────────────────────

  Future<void> _startAttempt() async {
    final authProvider = context.read<AuthProvider>();
    final attemptProvider = context.read<QuizAttemptProvider>();
    final user = authProvider.user;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session expired. Please log in again.'),
            backgroundColor:
                Theme.of(context).extension<AppSemanticColors>()?.danger ??
                    Theme.of(context).colorScheme.error,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    QuizAttempt? attempt;
    try {
      // If reviewing a previous attempt, don't start a new one
      if (widget.isReview) {
        attempt = await attemptProvider.getAttemptForReview(
          quizId: widget.quiz.id,
          studentId: user.uid,
        );
        if (attempt == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Could not load this attempt.'),
                backgroundColor:
                    Theme.of(context).extension<AppSemanticColors>()?.danger ??
                        Theme.of(context).colorScheme.error,
              ),
            );
            Navigator.pop(context);
          }
          return;
        }
      } else {
        // Start a new attempt
        attempt = await attemptProvider.startAttempt(
          quizId: widget.quiz.id,
          quizTitle: widget.quiz.title,
          studentId: user.uid,
          studentName: authProvider.userName ?? 'Student',
          totalMarks: widget.quiz.totalMarks,
          questionCount: widget.quiz.questions.length,
        );
      }
    } catch (e) {
      debugPrint('❌ Error in _startAttempt: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to load quiz. Please try again.'),
          backgroundColor:
              Theme.of(context).extension<AppSemanticColors>()?.danger ??
                  Theme.of(context).colorScheme.error,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (attempt == null && attemptProvider.errorMessage != null) {
      // If already completed, show results
      if (attemptProvider.currentAttempt != null &&
          attemptProvider.currentAttempt!.isSubmitted == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentQuizResultScreen(
                quiz: widget.quiz,
                attempt: attemptProvider.currentAttempt!,
              ),
            ),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(attemptProvider.errorMessage ?? 'Failed to start quiz'),
            backgroundColor:
                Theme.of(context).extension<AppSemanticColors>()?.danger ??
                    Theme.of(context).colorScheme.error,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    if (attempt == null) return;

    // Set question order
    _questionOrder = attempt.questionOrder.isNotEmpty
        ? attempt.questionOrder
        : List<int>.generate(widget.quiz.questions.length, (i) => i);

    setState(() => _attemptStarted = true);

    // Only setup security measures and timer for NEW attempts, not reviews
    if (!widget.isReview) {
      _setupAntiCheating();

      // Show fullscreen prompt
      if (kIsWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showFullscreenPrompt();
        });
      }

      // Start timer if quiz has time limit
      if (widget.quiz.config.timeLimitMinutes != null) {
        final elapsed = DateTime.now().difference(attempt.startTime).inSeconds;
        final totalSeconds = widget.quiz.config.timeLimitMinutes! * 60;
        debugPrint('⏱ Timer init: elapsed=$elapsed total=$totalSeconds');
        _remainingSeconds = (totalSeconds - elapsed).clamp(0, totalSeconds);

        debugPrint('⏱ Remaining seconds after init: $_remainingSeconds');
        if (_remainingSeconds <= 0) {
          debugPrint('⏱ Remaining seconds <= 0, auto-submitting');
          _autoSubmit();
          return;
        }

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            debugPrint('⏱ Timer cancelled: widget unmounted');
            timer.cancel();
            return;
          }
          setState(() {
            _remainingSeconds--;
            if (_remainingSeconds <= 0) {
              debugPrint('⏱ Timer reached zero, auto-submitting');
              timer.cancel();
              _autoSubmit();
            }
          });
        });
      }
    }
  }

  void _showFullscreenPrompt() {
    showAdaptiveAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.fullscreen,
              color: Theme.of(ctx).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Quiz Mode'),
          ],
        ),
        content: const Text(
          'For the best experience and to prevent distractions, '
          'please go fullscreen during the quiz.\n\n'
          'Note: Tab switching and other activities will be monitored.',
        ),
        actions: [
          Consumer<LoadingProvider>(
            builder: (context, loadingState, _) {
              return LoadingButton(
                isLoading: loadingState.isLoading,
                child: TextButton(
                  onPressed: loadingState.isLoading
                      ? null
                      : () => loadingState.runAsyncAction(() async {
                            op() => Navigator.pop(ctx);
                            await Future.sync(() => (op as dynamic)());
                          }),
                  child: const Text('Skip'),
                ),
              );
            },
          ),
          Consumer<LoadingProvider>(
            builder: (context, loadingState, _) {
              return LoadingButton(
                isLoading: loadingState.isLoading,
                child: ElevatedButton.icon(
                  onPressed: loadingState.isLoading
                      ? null
                      : () => loadingState.runAsyncAction(() async {
                            op() {
                              Navigator.pop(ctx);
                              _requestFullscreen();
                            }

                            await Future.sync(() => (op as dynamic)());
                          }),
                  icon: const Icon(Icons.fullscreen, size: 18),
                  label: const Text('Go Fullscreen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                    foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _autoSubmit() {
    if (!mounted) return;
    _showAutoSubmitDialog("⏰ Time's up! Your quiz has been submitted.");
  }

  void _showAutoSubmitDialog(String message) {
    showAdaptiveAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quiz Submitted'),
        content: Text(message),
        actions: [
          Consumer<LoadingProvider>(
            builder: (context, loadingState, _) {
              return LoadingButton(
                isLoading: loadingState.isLoading,
                child: ElevatedButton(
                  onPressed: loadingState.isLoading
                      ? null
                      : () => loadingState.runAsyncAction(() async {
                            op() {
                              Navigator.pop(ctx);
                              _submitQuiz();
                            }

                            await Future.sync(() => (op as dynamic)());
                          }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                    foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
                  ),
                  child: const Text('View Results'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();
    _inactivityTimer?.cancel();

    final attemptProvider = context.read<QuizAttemptProvider>();
    final result = await attemptProvider.submitAttempt(quiz: widget.quiz);

    if (result != null && mounted) {
      // Refresh available quizzes so this quiz is removed from the student's list
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final studentId = auth.currentUserId ?? auth.uid ?? '';
      quizProvider.fetchPublishedQuizzes(excludeStudentId: studentId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentQuizResultScreen(
            quiz: widget.quiz,
            attempt: result,
          ),
        ),
      );
    } else if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            attemptProvider.errorMessage ?? 'Failed to submit quiz',
          ),
          backgroundColor:
              Theme.of(context).extension<AppSemanticColors>()?.danger ??
                  Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_attemptStarted) {
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(
          child: AppLoader(message: 'Starting quiz...'),
        ),
      );
    }

    final attemptProvider = Provider.of<QuizAttemptProvider>(context);
    final questions = widget.quiz.questions;
    final realIndex = _questionOrder.isNotEmpty &&
            _currentQuestionIndex < _questionOrder.length
        ? _questionOrder[_currentQuestionIndex]
        : _currentQuestionIndex;
    final currentProgress = (_currentQuestionIndex + 1) / questions.length;
    final currentQuestion = questions[realIndex];
    final selectedOption = attemptProvider.currentResponses[currentQuestion.id];
    final isSplitLayout = AppBreakpoints.isDesktop(context);

    // Mark as visited
    attemptProvider.markVisited(currentQuestion.id);

    // Block right-click and keyboard shortcuts
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Listener(
            onPointerDown: (event) {
              if (event.buttons == 2) {
                // Right click
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        const Text('Right-click is disabled during the quiz.'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
              _recordInteraction();
            },
            child: KeyboardListener(
              focusNode: _keyboardFocusNode,
              onKeyEvent: (event) {
                _recordInteraction();
                // Block Ctrl+C, Ctrl+V, Ctrl+A
                if (event is KeyDownEvent) {
                  final isCtrl = HardwareKeyboard.instance.isControlPressed;
                  if (isCtrl) {
                    final key = event.logicalKey;
                    if (key == LogicalKeyboardKey.keyC ||
                        key == LogicalKeyboardKey.keyV ||
                        key == LogicalKeyboardKey.keyA) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Copy/Paste is disabled during the quiz.'),
                          duration: const Duration(seconds: 2),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }
                  }
                }
              },
              child: Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Column(
                  children: [
                    // Top bar
                    _buildTopBar(
                        questions.length, attemptProvider, isSplitLayout),

                    // Split panel layout
                    Expanded(
                      child: isSplitLayout
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 280,
                                  child: _buildLeftPanel(
                                      questions, attemptProvider),
                                ),
                                Container(
                                  width: 1,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                                Expanded(
                                  child: _buildRightPanel(
                                    currentQuestion,
                                    selectedOption,
                                    questions.length,
                                    attemptProvider,
                                    currentProgress,
                                  ),
                                ),
                              ],
                            )
                          : _buildRightPanel(
                              currentQuestion,
                              selectedOption,
                              questions.length,
                              attemptProvider,
                              currentProgress,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // BONUS: Temporary Debug Panel
        Positioned(
          top: 40,
          right: 16,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🛠 DEBUG PANEL',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10)),
                  const Text('Screen: Quiz Taking',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                  Text(
                      'Attempt ID: ${attemptProvider.currentAttempt?.id ?? "null"}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10)),
                  Text('Index: $_currentQuestionIndex / ${questions.length}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10)),
                  Text('Submitting: $_isSubmitting',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(
    int totalQuestions,
    QuizAttemptProvider attemptProvider,
    bool isSplitLayout,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    final hasTimeLimit =
        !widget.isReview && widget.quiz.config.timeLimitMinutes != null;
    final isLowTime = _remainingSeconds < 300 && _remainingSeconds > 60;
    final isCriticalTime = _remainingSeconds <= 60 && _remainingSeconds > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: IconButton(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              op() => _showExitConfirmation();
                              await Future.sync(() => (op as dynamic)());
                            }),
                    icon:
                        Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            Hero(
              tag: 'quiz-${widget.quiz.id}',
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Quiz title + Review badge
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.quiz.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isReview) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Auto-save status
            if (isSplitLayout) _buildSaveIndicator(attemptProvider),
            if (isSplitLayout) const SizedBox(width: 12),

            // Timer
            if (hasTimeLimit)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isCriticalTime
                      ? (semanticColors?.danger ?? colorScheme.error)
                          .withValues(alpha: 0.12)
                      : isLowTime
                          ? (semanticColors?.warning ?? colorScheme.tertiary)
                              .withValues(alpha: 0.12)
                          : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCriticalTime
                        ? (semanticColors?.danger ?? colorScheme.error)
                            .withValues(alpha: 0.45)
                        : isLowTime
                            ? (semanticColors?.warning ?? colorScheme.tertiary)
                                .withValues(alpha: 0.45)
                            : colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: isCriticalTime
                          ? semanticColors?.danger ?? colorScheme.error
                          : isLowTime
                              ? semanticColors?.warning ?? colorScheme.tertiary
                              : colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isCriticalTime
                            ? semanticColors?.danger ?? colorScheme.error
                            : isLowTime
                                ? semanticColors?.warning ??
                                    colorScheme.tertiary
                                : colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            if (hasTimeLimit) const SizedBox(width: 12) else const Spacer(),

            // Submit Button moved to Top Bar
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: ElevatedButton.icon(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              final op = _isSubmitting
                                  ? null
                                  : () => _showSubmitConfirmation(
                                        attemptProvider.currentResponses.length,
                                        totalQuestions,
                                      );
                              if (op != null) {
                                await Future.sync(() => (op as dynamic)());
                              }
                            }),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16, height: 16, child: AppLoader(size: 16))
                        : const Icon(Icons.send, size: 16),
                    label: Text(AppBreakpoints.isDesktop(context)
                        ? 'Submit Quiz'
                        : 'Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          semanticColors?.success ?? colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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

  Widget _buildSaveIndicator(QuizAttemptProvider attemptProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    switch (attemptProvider.saveStatus) {
      case SaveStatus.saving:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12, height: 12, child: AppLoader(size: 12)),
            const SizedBox(width: 4),
            Text('Saving...',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                )),
          ],
        );
      case SaveStatus.saved:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: semanticColors?.success ?? colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Text('Saved ✓',
                style: TextStyle(
                  fontSize: 11,
                  color: semanticColors?.success ?? colorScheme.secondary,
                )),
          ],
        );
      case SaveStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 14,
              color: semanticColors?.danger ?? colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text('Error',
                style: TextStyle(
                  fontSize: 11,
                  color: semanticColors?.danger ?? colorScheme.error,
                )),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLeftPanel(
      List<Question> questions, QuizAttemptProvider attemptProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          // Quiz info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.04),
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question Navigator',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildLegendDot(
                      colorScheme.outlineVariant,
                      'Not visited',
                    ),
                    _buildLegendDot(colorScheme.surface, 'Visited'),
                    _buildLegendDot(colorScheme.primary, 'Answered'),
                    _buildLegendDot(Colors.orange, 'Review'),
                  ],
                ),
              ],
            ),
          ),

          // Question grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(questions.length, (displayIdx) {
                  final realIdx = _questionOrder.isNotEmpty &&
                          displayIdx < _questionOrder.length
                      ? _questionOrder[displayIdx]
                      : displayIdx;
                  final question = questions[realIdx];
                  final isAnswered =
                      attemptProvider.currentResponses.containsKey(question.id);
                  final isVisited =
                      attemptProvider.visitedQuestions.contains(question.id);
                  final isCurrent = displayIdx == _currentQuestionIndex;

                  Color bgColor;
                  Color textColor;
                  Color borderColor;

                  final isFlagged = _flaggedQuestions.contains(question.id);

                  if (isFlagged && !isAnswered) {
                    bgColor = Colors.orange.shade50;
                    textColor = Colors.orange.shade900;
                    borderColor = Colors.orange;
                  } else if (isAnswered) {
                    bgColor = colorScheme.primary;
                    textColor = colorScheme.onPrimary;
                    borderColor = colorScheme.primary;
                  } else if (isVisited) {
                    bgColor = colorScheme.surface;
                    textColor = colorScheme.onSurface;
                    borderColor = colorScheme.outlineVariant;
                  } else {
                    bgColor = colorScheme.surfaceContainerHighest;
                    textColor = colorScheme.onSurfaceVariant;
                    borderColor = colorScheme.outlineVariant;
                  }

                  return InkWell(
                    onTap: () {
                      _recordInteraction();
                      setState(() => _currentQuestionIndex = displayIdx);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isCurrent ? colorScheme.primary : borderColor,
                              width: isCurrent ? 2.5 : 1.5,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${displayIdx + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                        if (isFlagged)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flag,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              children: [
                _buildStatRow(
                  'Answered',
                  '${attemptProvider.currentResponses.length}/${questions.length}',
                  colorScheme.primary,
                ),
                const SizedBox(height: 6),
                _buildStatRow(
                  'Remaining',
                  '${questions.length - attemptProvider.currentResponses.length}',
                  semanticColors?.warning ?? colorScheme.tertiary,
                ),
                if (widget.quiz.config.timeLimitMinutes != null) ...[
                  const SizedBox(height: 6),
                  _buildStatRow(
                    'Time Left',
                    _formatTime(_remainingSeconds),
                    _remainingSeconds < 60
                        ? semanticColors?.danger ?? colorScheme.error
                        : _remainingSeconds < 300
                            ? semanticColors?.warning ?? colorScheme.tertiary
                            : semanticColors?.success ?? colorScheme.secondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: colorScheme.outline, width: 0.5),
          ),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            )),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }

  Widget _buildRightPanel(
    Question currentQuestion,
    int? selectedOption,
    int totalQuestions,
    QuizAttemptProvider attemptProvider,
    double currentProgress,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    final beginProgress = _previousProgress;
    _previousProgress = currentProgress;

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (selectedOption == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (semanticColors?.warning ?? colorScheme.tertiary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              (semanticColors?.warning ?? colorScheme.tertiary)
                                  .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'Not Answered',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              semanticColors?.warning ?? colorScheme.tertiary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: beginProgress, end: currentProgress),
                  duration: AppDurations.normal,
                  curve: AppCurves.smooth,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Question content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: SingleChildScrollView(
              key: ValueKey(currentQuestion.id),
              padding: const EdgeInsets.all(24),
              child: _buildQuestionCard(currentQuestion, selectedOption),
            ),
          ),
        ),

        // Navigation buttons
        _buildBottomNav(totalQuestions, attemptProvider),
      ],
    );
  }

  Widget _buildQuestionCard(Question question, int? selectedOption) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number and marks
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q${_currentQuestionIndex + 1}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (semanticColors?.warning ?? colorScheme.tertiary)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${question.marks} mark${question.marks > 1 ? "s" : ""}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: semanticColors?.warning ?? colorScheme.tertiary,
                  ),
                ),
              ),
              const Spacer(),
              // Flag for Review toggle button
              Consumer<LoadingProvider>(
                builder: (context, loadingState, _) {
                  return LoadingButton(
                    isLoading: loadingState.isLoading,
                    child: IconButton(
                      onPressed: loadingState.isLoading
                          ? null
                          : () => loadingState.runAsyncAction(() async {
                                op() {
                                  setState(() {
                                    if (_flaggedQuestions
                                        .contains(question.id)) {
                                      _flaggedQuestions.remove(question.id);
                                    } else {
                                      _flaggedQuestions.add(question.id);
                                    }
                                  });
                                  _recordInteraction();
                                }

                                await Future.sync(() => (op as dynamic)());
                              }),
                      icon: Icon(
                        _flaggedQuestions.contains(question.id)
                            ? Icons.flag
                            : Icons.flag_outlined,
                      ),
                      color: _flaggedQuestions.contains(question.id)
                          ? Colors.orange
                          : colorScheme.onSurfaceVariant,
                      tooltip: _flaggedQuestions.contains(question.id)
                          ? 'Remove from Review'
                          : 'Flag for Review',
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Question text
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          if (question.options != null)
            ...question.options!.asMap().entries.map((entry) {
              final idx = entry.key;
              final option = entry.value;
              final isSelected = selectedOption == idx;
              final letter = String.fromCharCode(65 + idx);
              final colorScheme = Theme.of(context).colorScheme;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PressableWidget(
                  onTap: () {
                    _selectOption(
                        question, idx, context.read<QuizAttemptProvider>());
                  },
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    curve: AppCurves.snappy,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (widget.isReview
                              ? Colors.green.withValues(alpha: 0.08)
                              : colorScheme.primary.withValues(alpha: 0.08))
                          : colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (widget.isReview
                                ? Colors.green.shade600
                                : colorScheme.primary)
                            : colorScheme.outlineVariant.withValues(alpha: 0.6),
                        width: 1.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (widget.isReview
                                    ? Colors.green.shade600
                                    : colorScheme.primary)
                                : colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        AnimatedSlide(
                          duration: AppDurations.fast,
                          curve: AppCurves.enter,
                          offset:
                              isSelected ? Offset.zero : const Offset(0.3, 0),
                          child: AnimatedOpacity(
                            duration: AppDurations.fast,
                            opacity: isSelected ? 1 : 0,
                            child: Icon(
                              Icons.check_circle,
                              color: widget.isReview
                                  ? Colors.green.shade600
                                  : colorScheme.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
      int totalQuestions, QuizAttemptProvider attemptProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLastQuestion = _currentQuestionIndex == totalQuestions - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          if (_currentQuestionIndex > 0)
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: OutlinedButton.icon(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              op() {
                                _recordInteraction();
                                setState(() => _currentQuestionIndex--);
                              }

                              await Future.sync(() => (op as dynamic)());
                            }),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      side: BorderSide(color: colorScheme.outlineVariant),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                );
              },
            ),

          const Spacer(),

          // Review mode: show "Close Review" on last question, disabled on earlier questions
          if (widget.isReview) ...[
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: ElevatedButton.icon(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              final op = isLastQuestion
                                  ? () => _showExitConfirmation()
                                  : null;
                              if (op != null) {
                                await Future.sync(() => (op as dynamic)());
                              }
                            }),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastQuestion
                          ? Colors.blue.shade600
                          : colorScheme.outlineVariant.withValues(alpha: 0.3),
                      foregroundColor: isLastQuestion
                          ? Colors.white
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                );
              },
            )
          ]
          // Normal mode: Next button or Submit button
          else if (_currentQuestionIndex < totalQuestions - 1) ...[
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: ElevatedButton.icon(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              op() {
                                _recordInteraction();
                                setState(() => _currentQuestionIndex++);
                              }

                              await Future.sync(() => (op as dynamic)());
                            }),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                );
              },
            )
          ] else ...[
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: ElevatedButton.icon(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              op() {
                                final answered = attemptProvider
                                        .currentAttempt?.responses.length ??
                                    0;
                                _showSubmitConfirmation(
                                    answered, totalQuestions);
                              }

                              await Future.sync(() => (op as dynamic)());
                            }),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Submit Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                );
              },
            )
          ],
        ],
      ),
    );
  }

  void _showSubmitConfirmation(int answered, int total) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    final unanswered = total - answered;

    showAdaptiveAppDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit Quiz?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have answered $answered out of $total questions.'),
            if (unanswered > 0) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ $unanswered question${unanswered > 1 ? "s" : ""} unanswered',
                style: TextStyle(
                  color: semanticColors?.warning ?? colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Once submitted, you cannot change your answers.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
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
                  onPressed: loadingState.isLoading
                      ? null
                      : () => loadingState.runAsyncAction(() async {
                            op() => Navigator.pop(context);
                            await Future.sync(() => (op as dynamic)());
                          }),
                  child: const Text('Review Answers'),
                ),
              );
            },
          ),
          Consumer<LoadingProvider>(
            builder: (context, loadingState, _) {
              return LoadingButton(
                isLoading: loadingState.isLoading,
                child: ElevatedButton(
                  onPressed: loadingState.isLoading
                      ? null
                      : () => loadingState.runAsyncAction(() async {
                            op() {
                              Navigator.pop(context);
                              _submitQuiz();
                            }

                            await Future.sync(() => (op as dynamic)());
                          }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        semanticColors?.success ?? colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                  child: const Text('Submit'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();

    if (widget.isReview) {
      // Review mode: simple close dialog
      showAdaptiveAppDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Close Review?'),
          content: const Text(
              'You are viewing a completed quiz. Your answers cannot be changed.'),
          actions: [
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: TextButton(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              op() => Navigator.pop(context);
                              await Future.sync(() => (op as dynamic)());
                            }),
                    child: const Text('Keep Reviewing'),
                  ),
                );
              },
            ),
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: ElevatedButton(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              op() {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }

                              await Future.sync(() => (op as dynamic)());
                            }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close Review'),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } else {
      // Normal mode: quiz exit with timer warning
      showAdaptiveAppDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Leave Quiz?'),
          content: const Text(
            'Your progress has been saved. You can continue later, but the timer will keep running.',
          ),
          actions: [
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: TextButton(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              op() => Navigator.pop(context);
                              await Future.sync(() => (op as dynamic)());
                            }),
                    child: const Text('Stay'),
                  ),
                );
              },
            ),
            Consumer<LoadingProvider>(
              builder: (context, loadingState, _) {
                return LoadingButton(
                  isLoading: loadingState.isLoading,
                  child: ElevatedButton(
                    onPressed: loadingState.isLoading
                        ? null
                        : () => loadingState.runAsyncAction(() async {
                              op() {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }

                              await Future.sync(() => (op as dynamic)());
                            }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          semanticColors?.danger ?? colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    child: const Text('Leave'),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
