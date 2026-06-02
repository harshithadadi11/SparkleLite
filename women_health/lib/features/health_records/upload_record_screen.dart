import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/health_record.dart';
import 'health_record_controller.dart';

class UploadRecordScreen extends ConsumerStatefulWidget {
  const UploadRecordScreen({super.key});

  @override
  ConsumerState<UploadRecordScreen> createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends ConsumerState<UploadRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();
  
  RecordType _recordType = RecordType.labReport;
  DateTime _recordDate = DateTime.now();
  File? _selectedFile;
  String? _selectedFileName;
  bool _isPrivate = false;

  @override
  void dispose() {
    _titleController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _recordDate = picked;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file to upload')));
        return;
      }
      
      try {
        await ref.read(healthRecordControllerProvider.notifier).uploadRecord(
          title: _titleController.text,
          recordType: _recordType,
          recordDate: _recordDate,
          isPrivate: _isPrivate,
          doctorName: _doctorController.text,
          file: _selectedFile,
          notes: _notesController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record uploaded successfully')));
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthRecordControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Health Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Document Title',
                controller: _titleController,
                validator: (v) => v!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              
              const Text('Document Type', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<RecordType>(
                value: _recordType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: RecordType.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => _recordType = v!),
              ),
              const SizedBox(height: 16),

              const Text('Record Date', style: TextStyle(fontWeight: FontWeight.bold)),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_recordDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Doctor / Facility Name (Optional)',
                controller: _doctorController,
              ),
              const SizedBox(height: 16),

              const Text('Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_selectedFileName ?? 'Select File (PDF, JPG)'),
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Notes (Optional)',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Mark as Private'),
                subtitle: const Text('Only visible to you (hidden from family profile)'),
                value: _isPrivate,
                onChanged: (val) => setState(() => _isPrivate = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              
              AppButton(
                label: 'Upload Record',
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
