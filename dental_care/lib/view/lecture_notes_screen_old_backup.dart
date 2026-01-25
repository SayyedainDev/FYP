import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../provider/auth_provider.dart';
import '../providers/lecture_notes_provider.dart';
import '../models/lecture_note.dart';

class LectureNotesScreen extends StatefulWidget {
  const LectureNotesScreen({Key? key}) : super(key: key);

  @override
  State<LectureNotesScreen> createState() => _LectureNotesScreenState();
}

class _LectureNotesScreenState extends State<LectureNotesScreen> {
  int _selectedTabIndex = 0;
  File? _selectedFile;
  String? _selectedFileName;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customNotesController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customNotesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notesProvider = Provider.of<LectureNotesProvider>(context);

    if (authProvider.user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildUploadSection(notesProvider, authProvider)
                : _buildNotesListSection(notesProvider, authProvider),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.library_books,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lecture Notes Management',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF212121),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload and manage your lecture notes and study materials',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _buildTabButton('Upload Notes', 0),
          const SizedBox(width: 16),
          _buildTabButton('My Notes', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue.shade700 : Colors.grey[600],
              fontSize: 15,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(
    LectureNotesProvider notesProvider,
    AuthProvider authProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload File Section
          _buildSectionCard(
            title: 'Upload Lecture File',
            icon: Icons.upload_file,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supported formats: PDF, DOCX, PPT, Images, Videos',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFileName ?? 'No file selected',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _selectedFileName != null
                              ? Colors.green
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Select File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // File Details Form
          _buildSectionCard(
            title: 'File Details',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormField(
                  label: 'Title',
                  controller: _titleController,
                  hint: 'e.g., Orthodontics Basics',
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  label: 'Description',
                  controller: _descriptionController,
                  hint: 'Provide details about this lecture note',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  label: 'Tags (comma separated)',
                  controller: _tagsController,
                  hint: 'e.g., orthodontics, basics, chapter1',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upload Button
          if (!notesProvider.isLoading)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _selectedFile != null && _titleController.text.isNotEmpty
                    ? () => _uploadFile(notesProvider, authProvider)
                    : null,
                icon: const Icon(Icons.check_circle),
                label: const Text('Upload File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else
            Column(
              children: [
                LinearProgressIndicator(
                  value: notesProvider.uploadProgress,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(notesProvider.uploadProgress * 100).toStringAsFixed(0)}% Uploading...',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
        ],
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notes Grid
              if (filteredNotes.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notes uploaded yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _selectedTabIndex = 0),
                        icon: const Icon(Icons.add),
                        label: const Text('Upload First Note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return _buildNoteCard(note, notesProvider, authProvider);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoteCard(
    LectureNote note,
    LectureNotesProvider notesProvider,
    AuthProvider authProvider,
  ) {
    return GestureDetector(
      onTap: () => _showNoteDetails(context, note, notesProvider, authProvider),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon/Preview
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  note.typeIcon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note.typeLabel,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 12,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${note.views}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              child: const Text('Delete'),
                              onTap: () => _showDeleteConfirmation(
                                context,
                                note,
                                notesProvider,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: maxLines,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Dialogs and helper methods
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
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _uploadFile(
    LectureNotesProvider notesProvider,
    AuthProvider authProvider,
  ) async {
    if (_selectedFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and enter a title')),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final success = await notesProvider.createLectureNoteWithFile(
      dentistUid: authProvider.user!.uid,
      title: _titleController.text,
      description: _descriptionController.text,
      file: _selectedFile!,
      fileName: _selectedFileName!,
      tags: tags,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lecture note uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _tagsController.clear();
        setState(() {
          _selectedFile = null;
          _selectedFileName = null;
        });
        // Switch to notes list
        setState(() => _selectedTabIndex = 1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${notesProvider.errorMessage}')),
        );
      }
    }
  }

  void _showNoteDetails(
    BuildContext context,
    LectureNote note,
    LectureNotesProvider notesProvider,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${note.typeLabel}'),
              const SizedBox(height: 8),
              Text('Description: ${note.description}'),
              if (note.fileUrl != null) ...[
                const SizedBox(height: 8),
                Text('File: ${note.fileName}'),
                Text('Size: ${note.formatFileSize()}'),
              ],
              if (note.customNotes != null) ...[
                const SizedBox(height: 8),
                Text('Notes: ${note.customNotes}'),
              ],
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: note.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (note.fileUrl != null)
            TextButton(
              onPressed: () {
                // Open file
                notesProvider.incrementViewCount(note.id);
              },
              child: const Text('Open File'),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    LectureNote note,
    LectureNotesProvider notesProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
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
                    content: Text(
                      success
                          ? 'Note deleted successfully'
                          : 'Error deleting note',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
