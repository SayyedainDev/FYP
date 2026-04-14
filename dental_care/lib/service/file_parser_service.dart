import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';

/// Service to extract text content from various file formats
class FileParserService {
  /// Supported file extensions
  static const List<String> supportedExtensions = [
    'txt',
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'csv',
    'md',
  ];

  static const Map<String, String> fileTypeDescriptions = {
    'txt': 'Text File',
    'pdf': 'PDF Document',
    'doc': 'Microsoft Word 97-2003',
    'docx': 'Microsoft Word Document',
    'ppt': 'PowerPoint Presentation 97-2003',
    'pptx': 'PowerPoint Presentation',
    'xls': 'Excel Spreadsheet 97-2003',
    'xlsx': 'Excel Spreadsheet',
    'csv': 'Comma-Separated Values',
    'md': 'Markdown File',
  };

  /// Extract text from file bytes based on extension
  static Future<String> extractTextFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    final ext = _getExtension(fileName).toLowerCase();

    try {
      switch (ext) {
        case 'txt':
        case 'md':
          return _extractFromText(bytes);

        case 'pdf':
          return await _extractFromPdf(bytes);

        case 'docx':
        case 'doc':
          return await _extractFromDocx(bytes);

        case 'pptx':
        case 'ppt':
          return await _extractFromPptx(bytes);

        case 'xlsx':
        case 'xls':
          return await _extractFromXlsx(bytes);

        case 'csv':
          return _extractFromCsv(bytes);

        default:
          debugPrint('⚠️ Unsupported format: $ext');
          return '';
      }
    } catch (e) {
      debugPrint('❌ Error parsing $ext file: $e');
      return '';
    }
  }

  /// Extract text from file path
  static Future<String> extractTextFromFile(File file) async {
    final bytes = await file.readAsBytes();
    return extractTextFromBytes(bytes, file.path);
  }

  /// Extract plain text (UTF-8 encoded)
  static String _extractFromText(Uint8List bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (e) {
      debugPrint('Error decoding text: $e');
      return '';
    }
  }

  /// Extract text from PDF (basic implementation)
  /// Note: For production, use pub.dev:pdfx or pdf package
  static Future<String> _extractFromPdf(Uint8List bytes) async {
    try {
      // Basic PDF text extraction
      // For now, extract text between common PDF markers
      final content = String.fromCharCodes(bytes);

      // Remove binary data and extract readable text
      final cleaned = content
          .replaceAll(
            RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]'),
            ' ',
          ) // Remove control chars
          .replaceAll(RegExp(r'BT.*?ET'), '') // Remove PDF text objects
          .replaceAll(RegExp(r'<<.*?>>'), '') // Remove dictionary objects
          .replaceAll(RegExp(r'stream.*?endstream'), '') // Remove streams
          .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
          .trim();

      // Return cleaned content if substantial, otherwise placeholder
      return cleaned.length > 100
          ? cleaned.substring(0, cleaned.length)
          : 'PDF content extracted but may need proper PDF parser';
    } catch (e) {
      debugPrint('Error extracting from PDF: $e');
      return 'Unable to extract from PDF. Please use a text-based format (TXT) or install a PDF parser library.';
    }
  }

  /// Extract text from DOCX (Word document)
  /// DOCX is a ZIP archive containing XML files
  static Future<String> _extractFromDocx(Uint8List bytes) async {
    try {
      debugPrint('🔍 Extracting text from DOCX...');

      // Decode the ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);

      final textParts = <String>[];

      // Look for document.xml which contains the main text
      for (final file in archive.files) {
        if (file.name.contains('word/document.xml') ||
            file.name.contains('word/header') ||
            file.name.contains('word/footer')) {
          if (file.isFile) {
            final content = utf8.decode(file.content as List<int>);

            // Extract text from <w:t> tags (Word text tags)
            final textRegex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
            final matches = textRegex.allMatches(content);

            for (final match in matches) {
              final text = match.group(1)?.trim() ?? '';
              if (text.isNotEmpty) {
                textParts.add(text);
              }
            }
          }
        }
      }

      final extractedText =
          textParts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

      debugPrint('✅ DOCX extraction: ${extractedText.length} characters');

      return extractedText.isNotEmpty
          ? extractedText
          : 'DOCX file processed but no text content found.';
    } catch (e) {
      debugPrint('❌ Error extracting from DOCX: $e');
      return 'Unable to extract text from DOCX. File may be corrupted or password-protected.';
    }
  }

  /// Extract text from PPTX (PowerPoint presentation)
  /// PPTX is a ZIP archive containing XML files for each slide
  static Future<String> _extractFromPptx(Uint8List bytes) async {
    try {
      debugPrint('🔍 Extracting text from PPTX...');

      // Decode the ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);

      final textParts = <String>[];

      // Look for slide XML files which contain the text content
      for (final file in archive.files) {
        // Slide content is in ppt/slides/slide*.xml files
        if (file.name.contains('ppt/slides/slide') &&
            file.name.endsWith('.xml')) {
          if (file.isFile) {
            final content = utf8.decode(file.content as List<int>);

            // Extract text from <a:t> tags (PowerPoint text tags)
            final textRegex = RegExp(r'<a:t>([^<]*)</a:t>');
            final matches = textRegex.allMatches(content);

            for (final match in matches) {
              final text = match.group(1)?.trim() ?? '';
              if (text.isNotEmpty) {
                textParts.add(text);
              }
            }
          }
        }

        // Also check notes (ppt/notesSlides/notesSlide*.xml)
        if (file.name.contains('ppt/notesSlides/notesSlide') &&
            file.name.endsWith('.xml')) {
          if (file.isFile) {
            final content = utf8.decode(file.content as List<int>);

            final textRegex = RegExp(r'<a:t>([^<]*)</a:t>');
            final matches = textRegex.allMatches(content);

            for (final match in matches) {
              final text = match.group(1)?.trim() ?? '';
              if (text.isNotEmpty) {
                textParts.add(text);
              }
            }
          }
        }
      }

      final extractedText =
          textParts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

      debugPrint(
        '✅ PPTX extraction: ${extractedText.length} characters from ${textParts.length} text elements',
      );

      return extractedText.isNotEmpty
          ? extractedText
          : 'PPTX file processed but no text content found.';
    } catch (e) {
      debugPrint('❌ Error extracting from PPTX: $e');
      return 'Unable to extract text from PPTX. File may be corrupted or password-protected.';
    }
  }

  /// Extract text from Excel files (XLSX)
  /// XLSX is a ZIP archive containing XML files
  static Future<String> _extractFromXlsx(Uint8List bytes) async {
    try {
      debugPrint('🔍 Extracting text from XLSX...');

      // Decode the ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);

      final textParts = <String>[];

      // Look for sharedStrings.xml which contains the text values
      for (final file in archive.files) {
        if (file.name.contains('xl/sharedStrings.xml')) {
          if (file.isFile) {
            final content = utf8.decode(file.content as List<int>);

            // Extract text from <t> tags (Excel text tags)
            final textRegex = RegExp(r'<t[^>]*>([^<]*)</t>');
            final matches = textRegex.allMatches(content);

            for (final match in matches) {
              final text = match.group(1)?.trim() ?? '';
              if (text.isNotEmpty) {
                textParts.add(text);
              }
            }
          }
        }

        // Also check worksheets for inline strings
        if (file.name.contains('xl/worksheets/sheet') &&
            file.name.endsWith('.xml')) {
          if (file.isFile) {
            final content = utf8.decode(file.content as List<int>);

            // Extract inline string values
            final textRegex = RegExp(r'<is><t[^>]*>([^<]*)</t></is>');
            final matches = textRegex.allMatches(content);

            for (final match in matches) {
              final text = match.group(1)?.trim() ?? '';
              if (text.isNotEmpty) {
                textParts.add(text);
              }
            }
          }
        }
      }

      final extractedText =
          textParts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

      debugPrint('✅ XLSX extraction: ${extractedText.length} characters');

      return extractedText.isNotEmpty
          ? extractedText
          : 'XLSX file processed but no text content found.';
    } catch (e) {
      debugPrint('❌ Error extracting from XLSX: $e');
      return 'Unable to extract text from XLSX. File may be corrupted or password-protected.';
    }
  }

  /// Extract text from CSV
  static String _extractFromCsv(Uint8List bytes) {
    try {
      final content = String.fromCharCodes(bytes);
      // CSV content is readable as text, just remove extra whitespace
      return content
          .replaceAll(RegExp(r','), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    } catch (e) {
      debugPrint('Error extracting from CSV: $e');
      return '';
    }
  }

  /// Get file extension
  static String _getExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.isNotEmpty ? parts.last : '';
  }

  /// Validate if file is supported
  static bool isSupported(String fileName) {
    final ext = _getExtension(fileName).toLowerCase();
    return supportedExtensions.contains(ext);
  }

  /// Get human-readable file type
  static String getFileTypeDescription(String fileName) {
    final ext = _getExtension(fileName).toLowerCase();
    return fileTypeDescriptions[ext] ?? 'Unknown file type ($ext)';
  }

  /// Get all supported formats as readable string
  static String getSupportedFormatsString() {
    return supportedExtensions.map((ext) => '.${ext.toUpperCase()}').join(', ');
  }

  /// Validate file size (max 25MB for most formats)
  static bool isValidFileSize(int sizeInBytes) {
    const maxSize = 25 * 1024 * 1024; // 25MB
    return sizeInBytes <= maxSize;
  }

  /// Get user-friendly error message for file
  static String getValidationError(String fileName, int fileSizeBytes) {
    if (!isSupported(fileName)) {
      return 'Unsupported file format. Supported formats: ${getSupportedFormatsString()}';
    }

    if (!isValidFileSize(fileSizeBytes)) {
      return 'File too large. Maximum file size is 25MB.';
    }

    return '';
  }
}
