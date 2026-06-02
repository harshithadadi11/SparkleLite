import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/repositories/mock_backend.dart';
import '../domain/reminder_model.dart';
import '../providers/reminder_providers.dart';

class AddReminderBottomSheet extends ConsumerStatefulWidget {
  final ReminderModel? existingReminder;

  const AddReminderBottomSheet({super.key, this.existingReminder});

  @override
  ConsumerState<AddReminderBottomSheet> createState() => _AddReminderBottomSheetState();
}

class _AddReminderBottomSheetState extends ConsumerState<AddReminderBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  ReminderCategory? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  ReminderRepeat _selectedRepeat = ReminderRepeat.none;

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      _titleController.text = widget.existingReminder!.title;
      _descController.text = widget.existingReminder!.description ?? '';
      _selectedCategory = widget.existingReminder!.category;
      _selectedDate = widget.existingReminder!.scheduledTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingReminder!.scheduledTime);
      _selectedRepeat = widget.existingReminder!.repeat;
    } else {
      _selectedDate = DateTime.now();
      
      // Round to next 30 mins
      final now = DateTime.now();
      int minute = now.minute;
      if (minute < 30) {
        minute = 30;
      } else {
        minute = 0;
      }
      _selectedTime = TimeOfDay(hour: minute == 0 ? (now.hour + 1) % 24 : now.hour, minute: minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _titleController.text.trim().isNotEmpty &&
           _selectedCategory != null &&
           _selectedDate != null &&
           _selectedTime != null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_isValid) return;

    final userId = ref.read(authRepoProvider).currentUser?.uid ?? 'mock_user_123';
    
    final scheduledTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final reminder = ReminderModel(
      id: widget.existingReminder?.id ?? const Uuid().v4(),
      userId: userId,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      scheduledTime: scheduledTime,
      repeat: _selectedRepeat,
      category: _selectedCategory!,
      isActive: widget.existingReminder?.isActive ?? true,
      createdAt: widget.existingReminder?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.existingReminder != null) {
        await ref.read(remindersNotifierProvider.notifier).updateReminder(reminder);
      } else {
        await ref.read(remindersNotifierProvider.notifier).addReminder(reminder);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reminder: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && widget.existingReminder != null) {
      try {
        await ref.read(remindersNotifierProvider.notifier).deleteReminder(widget.existingReminder!.id);
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting reminder: $e')),
          );
        }
      }
    }
  }

  IconData _getCategoryIcon(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.medication: return Icons.medication;
      case ReminderCategory.symptomLog: return Icons.monitor_heart;
      case ReminderCategory.appointment: return Icons.calendar_month;
      case ReminderCategory.hydration: return Icons.water_drop;
      case ReminderCategory.other: return Icons.notifications;
    }
  }

  String _getCategoryLabel(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.medication: return 'Medication';
      case ReminderCategory.symptomLog: return 'Symptom';
      case ReminderCategory.appointment: return 'Appointment';
      case ReminderCategory.hydration: return 'Hydration';
      case ReminderCategory.other: return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifierState = ref.watch(remindersNotifierProvider);
    final isLoading = notifierState.isLoading;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingReminder == null ? 'Add Reminder' : 'Edit Reminder',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              AppTextField(
                label: 'Title *',
                controller: _titleController,
                maxLength: 100,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description (Optional)',
                controller: _descController,
                maxLength: 300,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReminderCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(_getCategoryLabel(cat)),
                    avatar: Icon(_getCategoryIcon(cat), size: 18, color: isSelected ? AppColors.primary : Colors.grey),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date *', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedDate == null ? 'Select' : DateFormat('E, d MMM y').format(_selectedDate!)),
                                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time *', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedTime == null ? 'Select' : _selectedTime!.format(context)),
                                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Repeat', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<ReminderRepeat>(
                segments: const [
                  ButtonSegment(value: ReminderRepeat.none, label: Text('None')),
                  ButtonSegment(value: ReminderRepeat.daily, label: Text('Daily')),
                  ButtonSegment(value: ReminderRepeat.weekly, label: Text('Weekly')),
                  ButtonSegment(value: ReminderRepeat.monthly, label: Text('Monthly')),
                ],
                selected: {_selectedRepeat},
                onSelectionChanged: (val) => setState(() => _selectedRepeat = val.first),
              ),
              const SizedBox(height: 32),

              AppButton(
                label: widget.existingReminder == null ? 'Save reminder' : 'Update reminder',
                isLoading: isLoading,
                onPressed: _isValid ? _save : null,
              ),

              if (widget.existingReminder != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: isLoading ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Remove reminder'),
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}
