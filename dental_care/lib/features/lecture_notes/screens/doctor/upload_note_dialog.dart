import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dental_care/features/lecture_notes/providers/lecture_note_provider.dart';
import 'package:dental_care/features/lecture_notes/widgets/upload_progress_indicator.dart';
import 'package:dental_care/core/theme/app_tokens.dart';

class UploadNoteDialog extends StatefulWidget {
  const UploadNoteDialog({
    super.key,
    required this.availableModules,
    required this.provider,
  });
  final List<String> availableModules;
  final LectureNoteProvider provider;

  @override
  State<UploadNoteDialog> createState() => _UploadNoteDialogState();
}

class _UploadNoteDialogState extends State<UploadNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  late String _selectedModuleId;
  late List<String> _modules;
  Uint8List? _pickedBytes;
  String _pickedFileName = '';
  String _pickedMimeType = 'application/octet-stream';

  @override
  void initState() {
    super.initState();
    _modules = widget.availableModules.isNotEmpty
        ? List.from(widget.availableModules)
        : ['general'];
    _selectedModuleId = _modules.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      withData: true,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _pickedBytes = result.files.first.bytes;
        _pickedFileName = result.files.first.name;
        final ext = result.files.first.extension?.toLowerCase() ?? '';
        _pickedMimeType = ext == 'pdf'
            ? 'application/pdf'
            : ext == 'doc' || ext == 'docx'
                ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                : 'application/octet-stream';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first'), backgroundColor: Colors.red),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser!;

    final success = await widget.provider.uploadNote(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      moduleId: _selectedModuleId,
      fileName: _pickedFileName,
      fileBytes: _pickedBytes!,
      mimeType: _pickedMimeType,
      uploadedByUid: currentUser.uid,
      uploadedByName: currentUser.displayName ?? 'Doctor',
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note uploaded successfully'), backgroundColor: AppColors.success),
      );
    }
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.provider.errorMessage ??
                'Upload failed. Please try again.'), backgroundColor: Colors.red),
      );
      widget.provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cloud_upload, color: AppColors.brandPrimary),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Upload Note', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Share materials with your students', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.provider.isUploading ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Form Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g., Week 1: Introduction',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandPrimary)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Add some details...',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandPrimary)),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedModuleId,
                        decoration: InputDecoration(
                          labelText: 'Module',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandPrimary)),
                        ),
                        items: _modules.map((m) {
                          return DropdownMenuItem(value: m, child: Text(m));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedModuleId = val);
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // File Picker Area
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _pickedBytes != null ? Colors.blue.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _pickedBytes != null ? AppColors.brandPrimary : Colors.grey.shade300,
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _pickedBytes != null ? Icons.description : Icons.upload_file,
                                size: 48,
                                color: _pickedBytes != null ? AppColors.brandPrimary : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _pickedBytes != null ? _pickedFileName : 'Tap to browse files',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _pickedBytes != null ? Colors.blue.shade900 : Colors.grey.shade700,
                                ),
                              ),
                              if (_pickedBytes == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'PDF, DOC, PPT supported',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      if (widget.provider.isUploading) ...[
                        const SizedBox(height: 24),
                        UploadProgressIndicator(progress: widget.provider.uploadProgress),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.provider.isUploading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: widget.provider.isUploading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: widget.provider.isUploading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Upload Note', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
