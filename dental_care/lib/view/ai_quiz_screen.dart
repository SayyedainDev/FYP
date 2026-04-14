// ignore_for_file: unused_field, unused_element

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/quiz_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/lecture_notes_provider.dart';
import '../provider/auth_provider.dart';
import '../models/quiz.dart';
import '../models/lecture_note.dart';
import '../service/quiz_pdf_service.dart';
import '../service/file_parser_service.dart';
import '../core/theme/app_semantic_colors.dart';
import '../widgets/loaders/app_loader.dart';

class AIQuizScreen extends StatefulWidget {
  const AIQuizScreen({super.key});

  @override
  State<AIQuizScreen> createState() => _AIQuizScreenState();
}

class _AIQuizScreenState extends State<AIQuizScreen> {
  int _currentStep = 0;
  List<Question> _generatedQuestions = [];
  String _generationStatusText = 'Analyzing your PDF content...';
  Timer? _statusTimer;

  // Quiz configuration
  DifficultyLevel _selectedDifficulty = DifficultyLevel.medium;
  int _totalQuestions = 10;
  final Set<QuestionType> _selectedQuestionTypes = {QuestionType.mcq};
  final int _numberOfSections = 1;
  final String _marksDistribution = 'equal';
  CognitiveLevel _cognitiveLevel = CognitiveLevel.mixed;
  final String _contentCoverage = 'entire';
  int? _timeLimitMinutes = 30;
  bool _includeAnswerKey = true;
  String _explanationLevel = 'brief';
  QuizMode? _specialMode = QuizMode.practice;

  // Lecture Notes Management
  final List<String> _selectedLectureNoteIds = [];
  String? _additionalNotesFileName;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _questionsController = TextEditingController(
    text: '10',
  );
  final TextEditingController _sectionsController = TextEditingController(
    text: '1',
  );
  final TextEditingController _timeLimitController = TextEditingController(
    text: '30',
  );

  ColorScheme get _cs => Theme.of(context).colorScheme;
  AppSemanticColors? get _sem =>
      Theme.of(context).extension<AppSemanticColors>();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _questionsController.dispose();
    _sectionsController.dispose();
    _timeLimitController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _cs.surface,
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildCurrentStep(quizProvider, authProvider)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return const SizedBox.shrink();
  }

  Widget _buildStepItem(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? _cs.primary
                  : (isCompleted ? _cs.outline : _cs.surfaceContainerHighest),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check
                  : (isActive ? icon : Icons.circle_outlined),
              color: isActive || isCompleted
                  ? _cs.onPrimary
                  : _cs.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? _cs.primary : _cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 40),
        color: isCompleted ? _cs.primary : _cs.outlineVariant,
      ),
    );
  }

  Widget _buildCurrentStep(
    QuizProvider quizProvider,
    AuthProvider authProvider,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildUploadStep(quizProvider, authProvider);
      case 1:
        return _buildConfigurationStep();
      case 2:
        return _buildGenerationStep(quizProvider, authProvider);
      case 3:
        return _buildReviewStep(quizProvider, authProvider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildUploadStep(
    QuizProvider quizProvider,
    AuthProvider authProvider,
  ) {
    final lectureNotesProvider = Provider.of<LectureNotesProvider>(context);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cs.outlineVariant, width: 1),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Your Lecture Notes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _cs.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose existing notes or upload new ones to generate a quiz',
              style: TextStyle(color: _cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // === SELECT EXISTING LECTURE NOTES ===
            Text(
              'Available Lecture Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<LectureNote>>(
              stream: lectureNotesProvider.getLectureNotesStream(
                authProvider.user?.uid ?? '',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoader(size: 48));
                }

                final notes = snapshot.data ?? [];

                if (notes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _cs.outlineVariant, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        'No lecture notes yet. Upload notes to get started.',
                        style: TextStyle(
                          color: _cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _cs.outlineVariant, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    children: notes.map((note) {
                      final isSelected = _selectedLectureNoteIds.contains(
                        note.id,
                      );
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedLectureNoteIds.remove(note.id);
                              } else {
                                _selectedLectureNoteIds.add(note.id);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _cs.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              border: Border(
                                right: BorderSide(
                                  color: _cs.outlineVariant,
                                  width: 1,
                                ),
                                bottom: BorderSide(
                                  color: _cs.outlineVariant,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? _cs.primary
                                          : _cs.outline,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? _cs.primary
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: _cs.onPrimary,
                                          size: 12,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  note.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? _cs.primary
                                        : _cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // === UPLOAD NEW NOTES ===
            Text(
              'Upload New Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: quizProvider.isLoading
                  ? null
                  : () => _pickFile(quizProvider, authProvider),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: quizProvider.uploadedFileName != null
                        ? _cs.primary
                        : _cs.outlineVariant,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _cs.surfaceContainerLowest,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 48,
                      color: quizProvider.uploadedFileName != null
                          ? _cs.primary
                          : _cs.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      quizProvider.uploadedFileName ?? 'Click to upload file',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: quizProvider.uploadedFileName != null
                            ? _cs.primary
                            : _cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDF, DOCX, PPTX, Images (Max 25MB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (quizProvider.isLoading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: quizProvider.uploadProgress,
                        backgroundColor: _cs.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _cs.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploading... ${(quizProvider.uploadProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: _cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // === QUIZ DETAILS ===
            Text(
              'Quiz Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Quiz Title',
                hintText: 'e.g., Dental Anatomy Quiz',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: _cs.surfaceContainerLowest,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: _cs.surfaceContainerLowest,
              ),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final hasUpload = quizProvider.uploadedFile != null ||
                        quizProvider.uploadedBytes != null;
                    final hasLectureNotes =
                        _selectedLectureNoteIds.isNotEmpty || hasUpload;
                    if (hasLectureNotes && _titleController.text.isNotEmpty) {
                      setState(() => _currentStep = 1);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select or upload lecture notes and enter a quiz title',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cs.primary,
                    foregroundColor: _cs.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationStep() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure Your Quiz',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _cs.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize the quiz settings to match your needs',
            style: TextStyle(color: _cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 32),

          // Difficulty Level
          _buildConfigSection(
            'Difficulty Level',
            DropdownButtonFormField<DifficultyLevel>(
              value: _selectedDifficulty,
              decoration: _inputDecoration('Select difficulty'),
              items: DifficultyLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedDifficulty = value!),
            ),
          ),

          // Number of Questions
          _buildConfigSection(
            'Number of Questions',
            DropdownButtonFormField<int>(
              value: _totalQuestions,
              decoration: _inputDecoration('Select number of questions'),
              items: [5, 10, 15, 20, 25, 30, 40, 50].map((count) {
                return DropdownMenuItem(
                  value: count,
                  child: Text('$count Questions'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _totalQuestions = value!),
            ),
          ),

          // Question Types
          _buildConfigSection(
            'Question Types',
            Column(
              children: QuestionType.values.map((type) {
                return CheckboxListTile(
                  title: Text(_getQuestionTypeLabel(type)),
                  value: _selectedQuestionTypes.contains(type),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedQuestionTypes.add(type);
                      } else {
                        if (_selectedQuestionTypes.length > 1) {
                          _selectedQuestionTypes.remove(type);
                        }
                      }
                    });
                  },
                  activeColor: _cs.primary,
                  dense: true,
                );
              }).toList(),
            ),
          ),

          // Cognitive Level
          _buildConfigSection(
            'Cognitive Level',
            DropdownButtonFormField<CognitiveLevel>(
              value: _cognitiveLevel,
              decoration: _inputDecoration('Select cognitive level'),
              items: CognitiveLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(_getCognitiveLevelLabel(level)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _cognitiveLevel = value!),
            ),
          ),

          // Time Limit
          _buildConfigSection(
            'Time Limit',
            DropdownButtonFormField<int?>(
              value: _timeLimitMinutes,
              decoration: _inputDecoration('Select time limit'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No Time Limit'),
                ),
                const DropdownMenuItem(value: 15, child: Text('15 Minutes')),
                const DropdownMenuItem(value: 30, child: Text('30 Minutes')),
                const DropdownMenuItem(value: 45, child: Text('45 Minutes')),
                const DropdownMenuItem(value: 60, child: Text('1 Hour')),
                const DropdownMenuItem(value: 90, child: Text('1.5 Hours')),
                const DropdownMenuItem(value: 120, child: Text('2 Hours')),
              ],
              onChanged: (value) => setState(() => _timeLimitMinutes = value),
            ),
          ),

          // Answer Key Options
          _buildConfigSection(
            'Answer Key & Explanations',
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Include Answer Key'),
                  value: _includeAnswerKey,
                  onChanged: (value) =>
                      setState(() => _includeAnswerKey = value),
                  activeColor: _cs.primary,
                  dense: true,
                ),
                DropdownButtonFormField<String>(
                  value: _explanationLevel,
                  decoration: _inputDecoration('Explanation level'),
                  items: const [
                    DropdownMenuItem(
                      value: 'none',
                      child: Text('No Explanations'),
                    ),
                    DropdownMenuItem(
                      value: 'brief',
                      child: Text('Brief Explanations'),
                    ),
                    DropdownMenuItem(
                      value: 'detailed',
                      child: Text('Detailed Explanations'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _explanationLevel = value!),
                ),
              ],
            ),
          ),

          // Special Mode
          _buildConfigSection(
            'Quiz Mode',
            DropdownButtonFormField<QuizMode?>(
              value: _specialMode,
              decoration: _inputDecoration('Select quiz mode'),
              items: [
                const DropdownMenuItem<QuizMode?>(
                  value: null,
                  child: Text('No Special Mode'),
                ),
                ...QuizMode.values.map((mode) {
                  return DropdownMenuItem<QuizMode?>(
                    value: mode,
                    child: Text(_getQuizModeLabel(mode)),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _specialMode = value),
            ),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: TextButton.styleFrom(
                  foregroundColor: _cs.onSurfaceVariant,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentStep = 2),
                icon: const Icon(Icons.check),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cs.primary,
                  foregroundColor: _cs.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 2: AI Generation (animated progress) ─────────────────────

  Widget _buildGenerationStep(
    QuizProvider quizProvider,
    AuthProvider authProvider,
  ) {
    final isGenerating = quizProvider.isGeneratingWithAI;
    final hasError = quizProvider.groqError != null;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Generation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _cs.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is generating your quiz questions',
            style: TextStyle(color: _cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 32),

          // Summary card
          _buildSummaryCard(quizProvider),

          const SizedBox(height: 32),

          // Generation state
          if (isGenerating) ...[
            // Animated generation progress
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _cs.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const AppLoader(size: 52),
                  const SizedBox(height: 20),
                  Text(
                    'AI is generating your questions...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _generationStatusText,
                      key: ValueKey(_generationStatusText),
                      style: TextStyle(
                        fontSize: 13,
                        color: _cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (hasError) ...[
            // Error state
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (_sem?.danger ?? _cs.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_sem?.danger ?? _cs.error).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: _sem?.danger ?? _cs.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Generation Failed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _sem?.danger ?? _cs.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quizProvider.groqError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: _sem?.danger ?? _cs.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      quizProvider.clearGroqError();
                      _generateQuiz(quizProvider, authProvider);
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry Generation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cs.primary,
                      foregroundColor: _cs.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Ready to generate
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _generateQuiz(quizProvider, authProvider),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text('Generate Questions with AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cs.primary,
                  foregroundColor: _cs.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          if (!isGenerating)
            TextButton.icon(
              onPressed: () => setState(() => _currentStep = 1),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Settings'),
              style: TextButton.styleFrom(
                foregroundColor: _cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  void _startStatusTextCycling() {
    _statusTimer?.cancel();
    final statuses = [
      'Analyzing your PDF content...',
      'Identifying key concepts...',
      'Generating MCQ questions...',
      'Creating answer explanations...',
      'Validating answers...',
    ];
    int idx = 0;
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      idx = (idx + 1) % statuses.length;
      setState(() => _generationStatusText = statuses[idx]);
    });
  }

  // ─── Step 3: Review & Edit ─────────────────────────────────────────

  Widget _buildReviewStep(
    QuizProvider quizProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review & Edit Questions',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _cs.onSurface,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_generatedQuestions.length} questions generated',
                      style: TextStyle(
                        color: _cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Add question button
              OutlinedButton.icon(
                onPressed: _addManualQuestion,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Question'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _cs.primary,
                  side: BorderSide(color: _cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Editable question cards
          ..._generatedQuestions.asMap().entries.map((entry) {
            final idx = entry.key;
            final question = entry.value;
            return _buildEditableQuestionCard(idx, question);
          }),

          const SizedBox(height: 24),

          // Validation warning
          if (_generatedQuestions.length < 3)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: (_sem?.warning ?? _cs.tertiary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      (_sem?.warning ?? _cs.tertiary).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: _sem?.warning ?? _cs.tertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Minimum 3 questions required to publish.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _sem?.warning ?? _cs.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _currentStep = 2),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Regenerate'),
                style: TextButton.styleFrom(
                  foregroundColor: _cs.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _generatedQuestions.isEmpty
                        ? null
                        : () => _saveQuiz(quizProvider, authProvider,
                            asDraft: true),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save as Draft'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cs.primary,
                      side: BorderSide(color: _cs.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _generatedQuestions.length < 3
                        ? null
                        : () => _saveQuiz(quizProvider, authProvider,
                            asDraft: false),
                    icon: const Icon(Icons.publish, size: 18),
                    label: const Text('Publish Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sem?.success ?? _cs.secondary,
                      foregroundColor: _cs.onSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableQuestionCard(int index, Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _cs.primary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _deleteQuestion(index),
                icon: Icon(
                  Icons.delete_outline,
                  color: _sem?.danger ?? _cs.error,
                  size: 20,
                ),
                tooltip: 'Delete question',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question text
          TextFormField(
            initialValue: question.questionText,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Question',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: _cs.surface,
            ),
            onChanged: (val) {
              _generatedQuestions[index] = question.copyWith(questionText: val);
            },
          ),
          const SizedBox(height: 16),

          // Options
          if (question.options != null)
            ...question.options!.asMap().entries.map((entry) {
              final optIdx = entry.key;
              final option = entry.value;
              final letter = String.fromCharCode(65 + optIdx);
              final isCorrect = question.correctIndex == optIdx;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // Radio button for correct answer
                    Radio<int>(
                      value: optIdx,
                      groupValue: question.correctIndex,
                      onChanged: (val) {
                        setState(() {
                          _generatedQuestions[index] = question.copyWith(
                            correctIndex: val!,
                          );
                        });
                      },
                      activeColor: _sem?.success ?? _cs.secondary,
                    ),
                    // Letter badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? (_sem?.success ?? _cs.secondary)
                            : _cs.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: isCorrect
                                ? _cs.onSecondary
                                : _cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Option text field
                    Expanded(
                      child: TextFormField(
                        initialValue: option,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: isCorrect
                              ? (_sem?.success ?? _cs.secondary)
                                  .withValues(alpha: 0.1)
                              : _cs.surface,
                        ),
                        onChanged: (val) {
                          final newOptions = List<String>.from(
                            question.options!,
                          );
                          newOptions[optIdx] = val;
                          _generatedQuestions[index] = question.copyWith(
                            options: newOptions,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),

          // Explanation
          if (question.explanation != null &&
              question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: _cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
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

  void _addManualQuestion() {
    setState(() {
      _generatedQuestions.add(Question(
        id: 'q_manual_${DateTime.now().millisecondsSinceEpoch}',
        questionText: '',
        type: QuestionType.mcq,
        options: ['', '', '', ''],
        correctIndex: 0,
        explanation: '',
        marks: 1,
        difficulty: _selectedDifficulty,
      ));
    });
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: Text('Remove question ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _generatedQuestions.removeAt(index));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _sem?.danger ?? _cs.error,
              foregroundColor: _cs.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuiz(
    QuizProvider quizProvider,
    AuthProvider authProvider, {
    required bool asDraft,
  }) async {
    final user = authProvider.user;
    if (user == null) return;

    // Upload note file
    String? noteUrl;
    const uploadTimeout = Duration(seconds: 8);
    if (quizProvider.uploadedBytes != null &&
        quizProvider.uploadedFileName != null) {
      noteUrl = await quizProvider
          .uploadNoteBytes(
            user.uid,
            quizProvider.uploadedBytes!,
            quizProvider.uploadedFileName!,
          )
          .timeout(uploadTimeout, onTimeout: () => null);
    } else if (quizProvider.uploadedFile != null &&
        quizProvider.uploadedFileName != null) {
      noteUrl = await quizProvider
          .uploadNoteFile(
            user.uid,
            quizProvider.uploadedFile!,
            quizProvider.uploadedFileName!,
          )
          .timeout(uploadTimeout, onTimeout: () => null);
    }

    final config = QuizConfig(
      difficulty: _selectedDifficulty,
      totalQuestions: _generatedQuestions.length,
      questionTypes: _selectedQuestionTypes.toList(),
      numberOfSections: _numberOfSections,
      marksDistribution: _marksDistribution,
      cognitiveLevel: _cognitiveLevel,
      contentCoverage: _contentCoverage,
      timeLimitMinutes: _timeLimitMinutes,
      includeAnswerKey: _includeAnswerKey,
      explanationLevel: _explanationLevel,
      specialMode: _specialMode,
    );

    final success = await quizProvider.createQuiz(
      dentistUid: user.uid,
      title: _titleController.text,
      description: _descriptionController.text,
      config: config,
      questions: _generatedQuestions,
      noteFileUrl: noteUrl,
      noteFileName: quizProvider.uploadedFileName,
      status: asDraft ? QuizStatus.draft : QuizStatus.published,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(asDraft
              ? 'Quiz saved as draft!'
              : 'Quiz published successfully!'),
          backgroundColor: _sem?.success ?? _cs.secondary,
        ),
      );

      // Navigate to quiz list
      final navProvider = Provider.of<NavigationProvider>(
        context,
        listen: false,
      );
      navProvider.setPage('My Quizzes');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            quizProvider.errorMessage ?? 'Failed to save quiz',
          ),
          backgroundColor: _sem?.danger ?? _cs.error,
        ),
      );
    }
  }

  Widget _buildConfigSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryCard(QuizProvider quizProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(
            'File',
            quizProvider.uploadedFileName ?? 'Not selected',
          ),
          _buildSummaryRow(
            'Difficulty',
            _selectedDifficulty.name.toUpperCase(),
          ),
          _buildSummaryRow('Questions', _totalQuestions.toString()),
          _buildSummaryRow(
            'Question Types',
            _selectedQuestionTypes
                .map((t) => _getQuestionTypeLabel(t))
                .join(', '),
          ),
          _buildSummaryRow(
            'Cognitive Level',
            _getCognitiveLevelLabel(_cognitiveLevel),
          ),
          _buildSummaryRow(
            'Time Limit',
            _timeLimitMinutes != null
                ? '$_timeLimitMinutes minutes'
                : 'No limit',
          ),
          _buildSummaryRow('Answer Key', _includeAnswerKey ? 'Yes' : 'No'),
          _buildSummaryRow('Explanations', _explanationLevel.toUpperCase()),
          if (_specialMode != null)
            _buildSummaryRow('Mode', _getQuizModeLabel(_specialMode!)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildGeneratedQuizOutput(Quiz quiz) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: _sem?.success ?? _cs.secondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz Generated Successfully',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _sem?.success ?? _cs.secondary,
                      ),
                    ),
                    Text(
                      quiz.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: _cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quiz Details
          _buildQuizDetailRow('Total Questions', '${quiz.questions.length}'),
          _buildQuizDetailRow('Total Marks', '${quiz.totalMarks}'),
          _buildQuizDetailRow('Difficulty', quiz.difficultyText),
          _buildQuizDetailRow('Time Limit', quiz.timeText),
          _buildQuizDetailRow(
            'Cognitive Level',
            _getCognitiveLevelLabel(quiz.config.cognitiveLevel),
          ),
          if (quiz.config.specialMode != null)
            _buildQuizDetailRow(
              'Mode',
              _getQuizModeLabel(quiz.config.specialMode!),
            ),

          const SizedBox(height: 16),
          Divider(color: _cs.outlineVariant),
          const SizedBox(height: 16),

          // Questions Preview
          Text(
            'Question Preview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          ...quiz.questions
              .take(3)
              .map((question) => _buildQuestionPreview(question)),

          if (quiz.questions.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '+ ${quiz.questions.length - 3} more questions',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: _cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _titleController.clear();
                    _descriptionController.clear();
                  });
                  Provider.of<QuizProvider>(
                    context,
                    listen: false,
                  ).clearCurrentQuiz();
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Another'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _cs.primary,
                  side: BorderSide(color: _cs.primary),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await QuizPdfService.printQuiz(quiz);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Print failed. Please try again.'),
                        backgroundColor: _sem?.danger ?? _cs.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cs.primary,
                  foregroundColor: _cs.onPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await QuizPdfService.shareQuiz(quiz);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Share failed. Please try again.'),
                        backgroundColor: _sem?.danger ?? _cs.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cs.primary,
                  foregroundColor: _cs.onPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final navProvider = Provider.of<NavigationProvider>(
                    context,
                    listen: false,
                  );
                  navProvider.setPage('My Quizzes');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Opening your quiz list...'),
                      backgroundColor: _cs.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sem?.success ?? _cs.secondary,
                  foregroundColor: _cs.onSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildQuestionPreview(Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  question.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${question.marks} mark${question.marks > 1 ? "s" : ""}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (question.options != null && question.options!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...question.options!
                .map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '• $option',
                      style: TextStyle(
                        fontSize: 12,
                        color: _cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: _cs.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        return 'Multiple Choice Questions (MCQs)';
      case QuestionType.trueFalse:
        return 'True / False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.longAnswer:
        return 'Long Answer';
      case QuestionType.fillInTheBlanks:
        return 'Fill in the Blanks';
      case QuestionType.scenarioBased:
        return 'Scenario-based / Case Study';
    }
  }

  String _getCognitiveLevelLabel(CognitiveLevel level) {
    switch (level) {
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

  String _getQuizModeLabel(QuizMode mode) {
    switch (mode) {
      case QuizMode.exam:
        return 'Exam Mode (strict, no hints)';
      case QuizMode.practice:
        return 'Practice Mode (with hints)';
      case QuizMode.adaptive:
        return 'Adaptive Mode (difficulty increases)';
      case QuizMode.conceptual:
        return 'Conceptual Mastery Mode';
      case QuizMode.analytical:
        return 'Analytical / Critical-thinking Mode';
    }
  }

  Future<void> _pickFile(
    QuizProvider quizProvider,
    AuthProvider authProvider,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true, // Important for web
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final fileName = pickedFile.name;
        final fileSize = pickedFile.size;

        debugPrint('📄 File picked: $fileName');
        debugPrint('📏 File size: $fileSize bytes');

        // Validate file format and size
        final validationError = FileParserService.getValidationError(
          fileName,
          fileSize,
        );
        if (validationError.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ $validationError'),
                backgroundColor: _sem?.danger ?? _cs.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        // File type is valid, proceed with upload
        final fileType = FileParserService.getFileTypeDescription(fileName);
        debugPrint('✅ Valid format: $fileType');

        // Handle web and mobile differently
        if (kIsWeb) {
          // For web, keep bytes in memory and treat as temp
          debugPrint('🌐 Web platform detected - storing bytes in memory');
          final bytes = pickedFile.bytes;
          if (bytes != null) {
            quizProvider.setUploadedBytes(bytes, fileName);
            await quizProvider.saveToTemp(bytes: bytes, fileName: fileName);
          } else {
            quizProvider.setUploadedFile(null, fileName);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ $fileType uploaded: $fileName'),
                backgroundColor: _sem?.success ?? _cs.secondary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // For mobile/desktop, use the actual file path
          if (pickedFile.path != null) {
            debugPrint('📱 Mobile/Desktop platform - using file path');

            final file = File(pickedFile.path!);
            await quizProvider.saveToTemp(file: file, fileName: fileName);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ $fileType uploaded: $fileName'),
                  backgroundColor: _sem?.success ?? _cs.secondary,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            // Skipping cloud upload while Firebase is unavailable
          }
        }
      } else {
        debugPrint('❌ No file selected or file picker cancelled');
      }
    } catch (e) {
      debugPrint('❌ File picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to process selected file. Please try again.'),
            backgroundColor: _sem?.danger ?? _cs.error,
          ),
        );
      }
    }
  }

  Future<void> _generateQuiz(
    QuizProvider quizProvider,
    AuthProvider authProvider,
  ) async {
    final user = authProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    // Start status text cycling
    _startStatusTextCycling();

    // Create quiz configuration
    final config = QuizConfig(
      difficulty: _selectedDifficulty,
      totalQuestions: _totalQuestions,
      questionTypes: _selectedQuestionTypes.toList(),
      numberOfSections: _numberOfSections,
      marksDistribution: _marksDistribution,
      cognitiveLevel: _cognitiveLevel,
      contentCoverage: _contentCoverage,
      timeLimitMinutes: _timeLimitMinutes,
      includeAnswerKey: _includeAnswerKey,
      explanationLevel: _explanationLevel,
      specialMode: _specialMode,
    );

    // Generate questions
    List<Question>? questions = await quizProvider.generateQuestionsWithAI(
      config: config,
      topic: _titleController.text.isNotEmpty
          ? _titleController.text
          : 'Dental Quiz',
      uid: user.uid,
    );

    // Stop status cycling
    _statusTimer?.cancel();

    // Check if generation failed
    if (questions == null || questions.isEmpty) {
      // Error is shown in the generation step UI via groqError
      if (mounted) setState(() {});
      return;
    }

    // Success! Store questions and advance to review step
    if (mounted) {
      setState(() {
        _generatedQuestions = List.from(questions);
        _currentStep = 3; // Advance to Review & Edit
      });
    }
  }
}
