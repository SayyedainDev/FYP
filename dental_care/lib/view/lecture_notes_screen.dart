import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../provider/auth_provider.dart';
import '../providers/lecture_notes_provider.dart';
import '../models/lecture_note.dart';

class LectureNotesScreen extends StatefulWidget {
  const LectureNotesScreen({Key? key}) : super(key: key);

  @override
  State<LectureNotesScreen> createState() => _LectureNotesScreenState();
}

class _LectureNotesScreenState extends State<LectureNotesScreen>
    with SingleTickerProviderStateMixin {
  PlatformFile? _selectedPlatformFile;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notesProvider = Provider.of<LectureNotesProvider>(context);

    if (authProvider.user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildModernTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUploadSection(notesProvider, authProvider),
                _buildNotesListSection(notesProvider, authProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(LectureNotesProvider notesProvider) {
    return const SizedBox.shrink();
  }

  Widget _buildModernTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.grey[200],
        indicatorColor: const Color(0xFF4A90E2),
        labelColor: const Color(0xFF4A90E2),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Upload'),
          Tab(text: 'My Notes'),
        ],
      ),
    );
  }

  Widget _buildUploadSection(
    LectureNotesProvider notesProvider,
    AuthProvider authProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag and Drop Zone
              _buildModernUploadZone(),
              const SizedBox(height: 32),

              // Form Details
              _buildModernForm(),
              const SizedBox(height: 32),

              // Upload Button
              _buildUploadButton(notesProvider, authProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernUploadZone() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedPlatformFile != null
                        ? const Color(0xFF4A90E2)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 48,
                      color: _selectedPlatformFile != null
                          ? const Color(0xFF4A90E2)
                          : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedPlatformFile?.name ?? 'Click to upload file',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedPlatformFile != null
                            ? const Color(0xFF4A90E2)
                            : const Color(0xFF212121),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDF, DOCX, PPT, Images, Videos (Max 500MB)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernTextField(
              label: 'Title *',
              controller: _titleController,
              hint: 'e.g., Orthodontics Chapter 1: Basics',
              icon: Icons.title,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            _buildModernTextField(
              label: 'Description',
              controller: _descriptionController,
              hint: 'Provide details about this lecture note',
              icon: Icons.description,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            _buildModernTextField(
              label: 'Tags',
              controller: _tagsController,
              hint: 'orthodontics, basics, chapter1 (comma separated)',
              icon: Icons.label,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton(
    LectureNotesProvider notesProvider,
    AuthProvider authProvider,
  ) {
    final canUpload =
        _selectedPlatformFile != null && _titleController.text.isNotEmpty;

    if (notesProvider.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: notesProvider.uploadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(notesProvider.uploadProgress * 100).toStringAsFixed(0)}% Uploading...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: canUpload
          ? () => _uploadFile(notesProvider, authProvider)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[700],
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(
        canUpload ? 'Upload' : 'Select File & Enter Title',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildNotesListSection(
    LectureNotesProvider notesProvider,
    AuthProvider authProvider,
  ) {
    return StreamBuilder<List<LectureNote>>(
      stream: notesProvider.getLectureNotesStream(authProvider.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ],
            ),
          );
        }

        final notes = snapshot.data ?? [];
        final filteredNotes = _searchQuery.isEmpty
            ? notes
            : notes
                  .where(
                    (note) =>
                        note.title.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        note.description.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        return Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4A90E2),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF4A90E2),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Notes Grid or Empty State
            Expanded(
              child: filteredNotes.isEmpty
                  ? _buildEmptyState()
                  : _buildNotesGrid(filteredNotes, notesProvider, authProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No notes yet' : 'No matching notes found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Upload notes to get started'
                : 'Try different keywords',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesGrid(
    List<LectureNote> notes,
    LectureNotesProvider notesProvider,
    AuthProvider authProvider,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        return _buildModernNoteCard(notes[index], notesProvider, authProvider);
      },
    );
  }

  Widget _buildModernNoteCard(
    LectureNote note,
    LectureNotesProvider notesProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getTypeIcon(note.type),
                  size: 20,
                  color: const Color(0xFF4A90E2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () =>
                          Future.delayed(Duration.zero, () => _shareNote(note)),
                      child: const Row(
                        children: [
                          Icon(Icons.share, size: 18),
                          SizedBox(width: 8),
                          Text('Share', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _showDeleteConfirmation(
                          context,
                          note,
                          notesProvider,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${note.views}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        note.formatFileSize(),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(NoteType type) {
    switch (type) {
      case NoteType.pdf:
        return Icons.picture_as_pdf;
      case NoteType.doc:
      case NoteType.docx:
        return Icons.description;
      case NoteType.pptx:
        return Icons.slideshow;
      case NoteType.image:
        return Icons.image;
      case NoteType.video:
        return Icons.video_library;
      default:
        return Icons.note;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker().pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'pptx',
          'ppt',
          'txt',
          'jpg',
          'jpeg',
          'png',
          'mp4',
        ],
        withData: kIsWeb, // Important for web support
      );

      if (result != null) {
        setState(() {
          _selectedPlatformFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFile(
    LectureNotesProvider notesProvider,
    AuthProvider authProvider,
  ) async {
    if (_selectedPlatformFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file and enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    bool success = false;

    // Handle web vs mobile differently
    if (kIsWeb) {
      // For web, use bytes
      final bytes = _selectedPlatformFile!.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to read file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      success = await notesProvider.createLectureNoteWithFileBytes(
        dentistUid: authProvider.user!.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        bytes: bytes,
        fileName: _selectedPlatformFile!.name,
        tags: tags,
      );
    } else {
      // For mobile, use file path
      final path = _selectedPlatformFile!.path;
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to read file path'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      success = await notesProvider.createLectureNoteWithFile(
        dentistUid: authProvider.user!.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        file: File(path),
        fileName: _selectedPlatformFile!.name,
        tags: tags,
      );
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Lecture note uploaded successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _tagsController.clear();
        setState(() {
          _selectedPlatformFile = null;
        });
        // Switch to notes list
        _tabController.animateTo(1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${notesProvider.errorMessage}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareNote(LectureNote note) async {
    try {
      // Generate PDF with note details
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  note.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Description:',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(note.description),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Type: ${note.typeLabel}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                if (note.fileName != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'File: ${note.fileName}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
                if (note.tags.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Tags: ${note.tags.join(", ")}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${note.title}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    LectureNote note,
    LectureNotesProvider notesProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Delete Note?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await notesProvider.deleteLectureNote(
                noteId: note.id,
                dentistUid: note.dentistUid,
                fileName: note.fileName,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          success
                              ? 'Note deleted successfully'
                              : 'Error deleting note',
                        ),
                      ],
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
