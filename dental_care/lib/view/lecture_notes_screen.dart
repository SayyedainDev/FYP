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
          _buildModernHeader(notesProvider),
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
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.library_books,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lecture Notes Library',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload, organize, and share your study materials',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (notesProvider.lectureNotes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${notesProvider.lectureNotes.length} Notes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF6B7280),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.cloud_upload_outlined), text: 'Upload Notes'),
            Tab(icon: Icon(Icons.folder_open), text: 'My Library'),
          ],
        ),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.upload_file,
                  color: const Color(0xFF6366F1),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Upload Lecture File',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedPlatformFile != null
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE5E7EB),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: _selectedPlatformFile != null
                        ? const Color(0xFF10B981).withOpacity(0.05)
                        : const Color(0xFFF9FAFB),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _selectedPlatformFile != null
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : const Color(0xFF6366F1).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _selectedPlatformFile != null
                              ? Icons.check_circle
                              : Icons.cloud_upload_outlined,
                          size: 64,
                          color: _selectedPlatformFile != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _selectedPlatformFile?.name ?? 'No file selected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _selectedPlatformFile != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Supported: PDF, DOCX, PPT, Images, Videos',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: Text(
                          _selectedPlatformFile != null
                              ? 'Change File'
                              : 'Browse Files',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
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
              ],
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: const Color(0xFF8B5CF6), size: 24),
                const SizedBox(width: 12),
                const Text(
                  'File Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
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
        ],
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: notesProvider.uploadProgress,
                minHeight: 12,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(notesProvider.uploadProgress * 100).toStringAsFixed(0)}% Uploading...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: canUpload
            ? () => _uploadFile(notesProvider, authProvider)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          disabledForegroundColor: const Color(0xFF9CA3AF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canUpload ? 4 : 0,
          shadowColor: const Color(0xFF10B981).withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(canUpload ? Icons.cloud_upload : Icons.info_outline),
            const SizedBox(width: 12),
            Text(
              canUpload ? 'Upload Lecture Note' : 'Select File & Enter Title',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
              padding: const EdgeInsets.all(32),
              color: Colors.white,
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search your notes...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6366F1),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open,
              size: 80,
              color: const Color(0xFF6366F1).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty
                ? 'No lecture notes yet'
                : 'No matching notes found',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? 'Upload your first lecture note to get started'
                : 'Try different search keywords',
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          if (_searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(0);
              },
              icon: const Icon(Icons.add),
              label: const Text('Upload First Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTypeColor(note.type),
                  _getTypeColor(note.type).withOpacity(0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(note.type),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const Spacer(),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () =>
                          Future.delayed(Duration.zero, () => _shareNote(note)),
                      child: const Row(
                        children: [
                          Icon(Icons.share, size: 20),
                          SizedBox(width: 12),
                          Text('Share'),
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
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (note.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: note.tags
                          .take(3)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(
                                  note.type,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getTypeColor(note.type),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${note.views}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        note.formatFileSize(),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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

  Color _getTypeColor(NoteType type) {
    switch (type) {
      case NoteType.pdf:
        return const Color(0xFFEF4444);
      case NoteType.doc:
      case NoteType.docx:
        return const Color(0xFF3B82F6);
      case NoteType.pptx:
        return const Color(0xFFF59E0B);
      case NoteType.image:
        return const Color(0xFF10B981);
      case NoteType.video:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6366F1);
    }
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
      final result = await FilePicker.platform.pickFiles(
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
