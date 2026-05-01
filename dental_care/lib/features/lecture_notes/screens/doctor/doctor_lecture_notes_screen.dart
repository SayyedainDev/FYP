import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/features/lecture_notes/providers/lecture_note_provider.dart';
import 'package:dental_care/features/lecture_notes/widgets/note_card.dart';
import 'package:dental_care/core/theme/app_tokens.dart';
import 'upload_note_dialog.dart';

class DoctorLectureNotesScreen extends StatefulWidget {
  const DoctorLectureNotesScreen({super.key});

  @override
  State<DoctorLectureNotesScreen> createState() =>
      _DoctorLectureNotesScreenState();
}

class _DoctorLectureNotesScreenState extends State<DoctorLectureNotesScreen> {
  // Can be passed via constructor or fetched in the app. Using hardcoded for demo.
  final List<String> _availableModules = ['Module 1', 'Module 2', 'general'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LectureNoteProvider>().fetchAll();
    });
  }

  void _showAddNoteDialog() {
    final provider = context.read<LectureNoteProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UploadNoteDialog(
        availableModules: _availableModules,
        provider: provider,
      ),
    );
  }

  void _confirmDelete(BuildContext context, note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this lecture note? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<LectureNoteProvider>().deleteNote(note);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Lecture Notes'),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        backgroundColor: AppColors.brandPrimary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
      body: Consumer<LectureNoteProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
          }
          if (provider.status == LectureNoteStatus.error && provider.notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load notes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage ?? 'Please check your connection',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.read<LectureNoteProvider>().fetchAll(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            );
          }

          final allModules = ['All', ..._availableModules];
          final filteredNotes = _selectedFilter == 'All' 
              ? provider.notes 
              : provider.notes.where((n) => n.moduleId == _selectedFilter).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Filters
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Materials',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload and organize lecture notes for your students.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: allModules.map((module) {
                          final isSelected = _selectedFilter == module;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(module),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedFilter = module);
                              },
                              selectedColor: AppColors.brandPrimary.withOpacity(0.15),
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.brandPrimary : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              backgroundColor: Colors.grey.shade100,
                              side: BorderSide(
                                color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Notes List
              Expanded(
                child: filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: AppColors.brandPrimary.withOpacity(0.05), shape: BoxShape.circle),
                              child: Icon(Icons.library_books, size: 64, color: AppColors.brandPrimary.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 16),
                            Text('No notes found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                            const SizedBox(height: 8),
                            Text('Tap the + button to upload notes.', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<LectureNoteProvider>().fetchAll(),
                        color: AppColors.brandPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredNotes.length,
                          itemBuilder: (_, index) {
                            final note = filteredNotes[index];
                            return NoteCard(
                              note: note,
                              canDelete: true,
                              onDelete: () => _confirmDelete(context, note),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
