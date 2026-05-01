import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/core/constants/upload_constants.dart';
import 'package:dental_care/features/lecture_notes/providers/lecture_note_provider.dart';
import 'package:dental_care/features/lecture_notes/widgets/upload_progress_indicator.dart';

class UploadNoteDialog extends StatefulWidget {
  const UploadNoteDialog({super.key, required this.availableModules});
  final List<String> availableModules;

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
      withData: true, // THIS IS MANDATORY FOR FLUTTER WEB
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
        const SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser!;
    final provider = context.read<LectureNoteProvider>();

    final success = await provider.uploadNote(
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
    }
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                provider.errorMessage ?? 'Upload failed. Please try again.')),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LectureNoteProvider>();
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upload Lecture Note',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Title', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedModuleId,
                  decoration: const InputDecoration(
                      labelText: 'Module', border: OutlineInputBorder()),
                  items: _modules.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedModuleId = val);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Pick File'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pickedBytes != null
                            ? _pickedFileName
                            : 'No file selected',
                        style: TextStyle(
                          color: _pickedBytes != null
                              ? Colors.black87
                              : Colors.grey,
                          fontStyle: _pickedBytes == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (provider.isUploading) ...[
                  UploadProgressIndicator(progress: provider.uploadProgress),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: provider.isUploading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: provider.isUploading ? null : _submit,
                      child: const Text('Upload'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
