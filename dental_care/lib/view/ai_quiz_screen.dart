import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/quiz_provider.dart';
import '../providers/navigation_provider.dart';
import '../provider/auth_provider.dart';
import '../models/quiz.dart';
import '../service/quiz_pdf_service.dart';
import '../service/file_parser_service.dart';

class AIQuizScreen extends StatefulWidget {
  const AIQuizScreen({Key? key}) : super(key: key);

  @override
  State<AIQuizScreen> createState() => _AIQuizScreenState();
}

class _AIQuizScreenState extends State<AIQuizScreen> {
  int _currentStep = 0;

  // Quiz configuration
  DifficultyLevel _selectedDifficulty = DifficultyLevel.medium;
  int _totalQuestions = 10;
  final Set<QuestionType> _selectedQuestionTypes = {QuestionType.mcq};
  int _numberOfSections = 1;
  String _marksDistribution = 'equal';
  CognitiveLevel _cognitiveLevel = CognitiveLevel.mixed;
  String _contentCoverage = 'entire';
  int? _timeLimitMinutes = 30;
  bool _includeAnswerKey = true;
  String _explanationLevel = 'brief';
  QuizMode? _specialMode = QuizMode.practice;

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _questionsController.dispose();
    _sectionsController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 32),
                  _buildCurrentStep(quizProvider, authProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.quiz, color: Colors.blue.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Quiz Generator',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
              Text(
                'Create intelligent quizzes from your lecture notes',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepItem(0, 'Upload Notes', Icons.upload_file),
        _buildStepConnector(0),
        _buildStepItem(1, 'Configure', Icons.settings),
        _buildStepConnector(1),
        _buildStepItem(2, 'Generate', Icons.auto_awesome),
      ],
    );
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
              color: isActive || isCompleted
                  ? Colors.blue.shade700
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.blue.shade700 : Colors.grey[600],
            ),
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
        color: isCompleted ? Colors.blue.shade700 : Colors.grey.shade300,
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
        return _buildGenerateStep(quizProvider, authProvider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildUploadStep(
    QuizProvider quizProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Lecture Notes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your lecture notes or study materials',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Supported formats: ${FileParserService.getSupportedFormatsString()} (Max 25MB)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // File upload area
          InkWell(
            onTap: quizProvider.isLoading
                ? null
                : () => _pickFile(quizProvider, authProvider),
            child: Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                border: Border.all(
                  color: quizProvider.uploadedFileName != null
                      ? Colors.green.shade300
                      : Colors.blue.shade200,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: quizProvider.uploadedFileName != null
                    ? Colors.green.shade50
                    : Colors.blue.shade50,
              ),
              child: Column(
                children: [
                  Icon(
                    quizProvider.uploadedFileName != null
                        ? Icons.check_circle
                        : Icons.cloud_upload,
                    size: 64,
                    color: quizProvider.uploadedFileName != null
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    quizProvider.uploadedFileName ??
                        'Click to upload lecture notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: quizProvider.uploadedFileName != null
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quizProvider.uploadedFileName != null
                        ? 'File uploaded successfully! Click to change.'
                        : 'Supported formats: ${FileParserService.getSupportedFormatsString()} (Max 25MB)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  if (quizProvider.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: quizProvider.uploadProgress,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Uploading... ${(quizProvider.uploadProgress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Quiz title and description
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Quiz Title',
              hintText: 'e.g., Dental Anatomy Chapter 1 Quiz',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Brief description of the quiz...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  final hasUpload =
                      quizProvider.uploadedFile != null ||
                      quizProvider.uploadedBytes != null;
                  if (hasUpload && _titleController.text.isNotEmpty) {
                    setState(() => _currentStep = 1);
                  }
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next: Configure Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
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

  Widget _buildConfigurationStep() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Configuration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your quiz settings',
            style: TextStyle(color: Colors.grey[600]),
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
            'Question Types (Select multiple)',
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
                  activeColor: Colors.blue.shade700,
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
                  activeColor: Colors.blue.shade700,
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
                }).toList(),
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
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentStep = 2),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
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

  Widget _buildGenerateStep(
    QuizProvider quizProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Quiz',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your configuration and generate the quiz',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Configuration Summary
          _buildSummaryCard(),

          const SizedBox(height: 32),

          // AI Prompt Information
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The AI will analyze your notes and generate questions based on your configuration. This may take a few moments.',
                    style: TextStyle(color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Generated Quiz Output
          if (quizProvider.currentQuiz != null)
            _buildGeneratedQuizOutput(quizProvider.currentQuiz!),
          if (quizProvider.currentQuiz != null) const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Configuration'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              ElevatedButton.icon(
                onPressed: quizProvider.isLoading
                    ? null
                    : () => _generateQuiz(quizProvider, authProvider),
                icon: quizProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  quizProvider.isLoading
                      ? 'Generating...'
                      : 'Generate Quiz with AI',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
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

  Widget _buildConfigSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(
            'File',
            context.read<QuizProvider>().uploadedFileName ?? 'No file selected',
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
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz Generated Successfully!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    Text(
                      quiz.title,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
          _buildQuizDetailRow(
            'Question Types',
            quiz.config.questionTypes
                .map((t) => _getQuestionTypeLabel(t))
                .join(', '),
          ),
          _buildQuizDetailRow('Sections', '${quiz.config.numberOfSections}'),
          _buildQuizDetailRow(
            'Marks Distribution',
            quiz.config.marksDistribution,
          ),
          _buildQuizDetailRow(
            'Answer Key',
            quiz.config.includeAnswerKey ? 'Included' : 'Not included',
          ),
          _buildQuizDetailRow(
            'Explanation Level',
            quiz.config.explanationLevel.toUpperCase(),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Questions Preview
          Text(
            'Questions Preview:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 16),

          ...quiz.questions
              .take(5)
              .map((question) => _buildQuestionPreview(question))
              .toList(),

          if (quiz.questions.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '... and ${quiz.questions.length - 5} more questions',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ),

          const SizedBox(height: 24),

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
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade700),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await QuizPdfService.printQuiz(quiz);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Print failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await QuizPdfService.shareQuiz(quiz);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Share failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to My Quizzes page
                  final navProvider = Provider.of<NavigationProvider>(
                    context,
                    listen: false,
                  );
                  navProvider.setPage('My Quizzes');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quiz saved! Opening your quiz list...'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Full Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  question.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${question.marks} mark${question.marks > 1 ? "s" : ""}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (question.options != null && question.options!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...question.options!
                .map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '• $option',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                )
                .toList(),
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
      fillColor: Colors.grey.shade50,
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
                backgroundColor: Colors.red,
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
                backgroundColor: Colors.green,
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
                  backgroundColor: Colors.green,
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
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    );

    // Check if generation failed
    if (questions == null || questions.isEmpty) {
      final errorMsg = quizProvider.errorMessage ?? 'Unknown error';
      debugPrint('❌ Quiz generation failed: $errorMsg');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz generation failed: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Upload note file if present, but cap to ~8s to keep UX quick
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
      if (noteUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload skipped (timeout) — quiz saved without file'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (quizProvider.uploadedFile != null &&
        quizProvider.uploadedFileName != null) {
      noteUrl = await quizProvider
          .uploadNoteFile(
            user.uid,
            quizProvider.uploadedFile!,
            quizProvider.uploadedFileName!,
          )
          .timeout(uploadTimeout, onTimeout: () => null);
      if (noteUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload skipped (timeout) — quiz saved without file'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // Save quiz to Firebase
    final success = await quizProvider.createQuiz(
      dentistUid: user.uid,
      title: _titleController.text,
      description: _descriptionController.text,
      config: config,
      questions: questions,
      noteFileUrl: noteUrl,
      noteFileName: quizProvider.uploadedFileName,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Keep quiz locally so user still sees generated content
      quizProvider.setCurrentQuiz(
        Quiz(
          id: 'local-preview',
          title: _titleController.text,
          description: _descriptionController.text,
          dentistUid: user.uid,
          config: config,
          questions: questions,
          noteFileUrl: noteUrl,
          noteFileName: quizProvider.uploadedFileName,
          createdAt: DateTime.now(),
          totalMarks: questions.fold<int>(0, (sum, q) => sum + q.marks),
          sectionMarks: null,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            quizProvider.errorMessage ??
                'Saved locally. Firestore write failed (likely rules).',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // Stay on step 2 to show the generated quiz
    setState(() {});
  }
}
