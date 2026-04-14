import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import '../models/quiz.dart';

class QuizPdfService {
  /// Generate PDF from quiz
  static Future<Uint8List> generateQuizPdf(Quiz quiz) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  quiz.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  quiz.description,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Quiz Configuration Details
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: PdfColors.blue50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Quiz Configuration',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildPdfDetailRow(
                  'Total Questions',
                  '${quiz.questions.length}',
                ),
                _buildPdfDetailRow('Total Marks', '${quiz.totalMarks}'),
                _buildPdfDetailRow('Difficulty', quiz.difficultyText),
                _buildPdfDetailRow('Time Limit', quiz.timeText),
                _buildPdfDetailRow(
                  'Cognitive Level',
                  _getCognitiveLevelText(quiz.config.cognitiveLevel),
                ),
                if (quiz.config.specialMode != null)
                  _buildPdfDetailRow(
                    'Mode',
                    _getQuizModeText(quiz.config.specialMode!),
                  ),
                _buildPdfDetailRow(
                  'Question Types',
                  quiz.config.questionTypes.map((t) => t.name).join(', '),
                ),
                _buildPdfDetailRow(
                  'Answer Key Included',
                  quiz.config.includeAnswerKey ? 'Yes' : 'No',
                ),
                _buildPdfDetailRow(
                  'Explanation Level',
                  quiz.config.explanationLevel,
                ),
                _buildPdfDetailRow(
                  'Created',
                  '${quiz.createdAt.day}/${quiz.createdAt.month}/${quiz.createdAt.year}',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Section Marks (if applicable)
          if (quiz.sectionMarks != null && quiz.sectionMarks!.isNotEmpty) ...[
            pw.Text(
              'Section-wise Marks Distribution',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: quiz.sectionMarks!.entries
                    .map(
                      (e) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(e.key),
                            pw.Text('${e.value} marks'),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            pw.SizedBox(height: 24),
          ],

          // Questions
          pw.Text(
            'Questions',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),

          ...quiz.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildPdfQuestion(
              index + 1,
              question,
              quiz.config.includeAnswerKey,
            );
          }),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfQuestion(
    int number,
    Question question,
    bool includeAnswers,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Question Header
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  'Q$number',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                  borderRadius: pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  question.type.name.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.orange100,
                  borderRadius: pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  '${question.marks} mark${question.marks > 1 ? "s" : ""}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              if (question.section != null) ...[
                pw.SizedBox(width: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Text(
                    question.section!,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 8),

          // Question Text
          pw.Text(
            question.questionText,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          // Options (for MCQ/True-False)
          if (question.options != null && question.options!.isNotEmpty) ...[
            ...question.options!.asMap().entries.map((entry) {
              final optIndex = entry.key;
              final option = entry.value;
              final isCorrect =
                  includeAnswers && option == question.correctAnswerText;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                child: pw.Row(
                  children: [
                    pw.Text(
                      '${String.fromCharCode(65 + optIndex)}. ',
                      style: pw.TextStyle(
                        fontWeight: isCorrect
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                        color: isCorrect ? PdfColors.green900 : PdfColors.black,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        option,
                        style: pw.TextStyle(
                          fontWeight: isCorrect
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                          color:
                              isCorrect ? PdfColors.green900 : PdfColors.black,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      pw.Text(
                        ' ✓',
                        style: pw.TextStyle(
                          color: PdfColors.green900,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8),
          ],

          // Answer (for open-ended questions)
          if (includeAnswers &&
              (question.options == null || question.options!.isEmpty)) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Answer:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    question.correctAnswerText,
                    style: const pw.TextStyle(color: PdfColors.green900),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
          ],

          // Explanation
          if (includeAnswers && question.explanation != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Explanation:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    question.explanation!,
                    style: const pw.TextStyle(
                      color: PdfColors.blue900,
                      fontSize: 11,
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

  static String _getCognitiveLevelText(CognitiveLevel level) {
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

  static String _getQuizModeText(QuizMode mode) {
    switch (mode) {
      case QuizMode.exam:
        return 'Exam Mode';
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

  /// Print the quiz PDF
  static Future<void> printQuiz(Quiz quiz) async {
    final pdfBytes = await generateQuizPdf(quiz);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  /// Share the quiz PDF
  static Future<void> shareQuiz(Quiz quiz) async {
    try {
      final pdfBytes = await generateQuizPdf(quiz);
      final fileName =
          '${quiz.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Use web-friendly sharing via `printing` package since `dart:io` file
      // access and `path_provider` temporary directories are not available on web.
      if (kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        return;
      }

      // Create an in-memory XFile from bytes so sharing works across
      // platforms (including web and mobile) without needing local file IO.
      final xfile = XFile.fromData(
        pdfBytes,
        name: fileName,
        mimeType: 'application/pdf',
      );

      await Share.shareXFiles(
        [xfile],
        subject: quiz.title,
        text: 'Quiz: ${quiz.title}\n${quiz.description}',
      );
    } catch (e) {
      throw Exception('Failed to share quiz. Please try again.');
    }
  }
}
