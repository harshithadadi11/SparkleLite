import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/symptom_log.dart';
import '../../data/repositories/mock_backend.dart';
import 'symptom_controller.dart';

class AddSymptomScreen extends ConsumerStatefulWidget {
  final SymptomLog? existingLog;

  const AddSymptomScreen({super.key, this.existingLog});

  @override
  ConsumerState<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends ConsumerState<AddSymptomScreen> {
  late DateTime _selectedDate;
  PeriodStatus? _periodStatus;
  FlowLevel? _flowLevel;
  double _painLevel = 0;
  Mood? _selectedMood;
  final Set<Symptom> _selectedSymptoms = {};
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _selectedDate = log.date;
      _periodStatus = log.periodStatus;
      _flowLevel = log.flowLevel;
      _painLevel = log.painLevel.toDouble();
      _selectedMood = log.mood;
      _selectedSymptoms.addAll(log.symptoms);
      _notesController.text = log.notes ?? '';
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveLog() async {
    if (_periodStatus == null) {
      setState(() => _errorMessage = 'Period status is required.');
      return;
    }
    if (_selectedMood == null) {
      setState(() => _errorMessage = 'Mood is required.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final log = SymptomLog(
      id: widget.existingLog?.id ?? '',
      userId: ref.read(authRepoProvider).currentUser!.uid,
      date: _selectedDate,
      periodStatus: _periodStatus!,
      flowLevel: _periodStatus == PeriodStatus.noPeriod ? FlowLevel.none : (_flowLevel ?? FlowLevel.none),
      painLevel: _painLevel.toInt(),
      mood: _selectedMood!,
      symptoms: _selectedSymptoms.toList(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.existingLog?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.existingLog != null) {
        await ref.read(symptomControllerProvider.notifier).addLog(log);
      } else {
        await ref.read(symptomControllerProvider.notifier).addLog(log);
      }
      
      final nextState = ref.read(symptomControllerProvider);
      if (nextState.hasError) {
        throw nextState.error!;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log saved successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _formatEnum(String enumStr) {
    final str = enumStr.split('.').last;
    if (str.isEmpty) return '';
    return str[0].toUpperCase() + str.substring(1).replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingLog != null ? 'Edit Symptom Log' : 'Add Symptom Log'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),

            // Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date *', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('MMMM d, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 24),

            // Period Status
            const Text('Period Status *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<PeriodStatus>(
              emptySelectionAllowed: true,
              segments: PeriodStatus.values.map((e) => ButtonSegment(
                value: e,
                label: Text(_formatEnum(e.toString()), style: const TextStyle(fontSize: 12)),
              )).toList(),
              selected: _periodStatus != null ? {_periodStatus!} : {},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) setState(() => _periodStatus = set.first);
              },
            ),
            const SizedBox(height: 24),

            // Flow Level
            if (_periodStatus != null && _periodStatus != PeriodStatus.noPeriod) ...[
              const Text('Flow Level', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<FlowLevel>(
                emptySelectionAllowed: true,
                segments: FlowLevel.values.map((e) => ButtonSegment(
                  value: e,
                  label: Text(_formatEnum(e.toString()), style: const TextStyle(fontSize: 12)),
                )).toList(),
                selected: _flowLevel != null ? {_flowLevel!} : {},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) setState(() => _flowLevel = set.first);
                },
              ),
              const SizedBox(height: 24),
            ],

            // Mood
            const Text('Mood *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: Mood.values.map((mood) {
                final isSelected = _selectedMood == mood;
                return ChoiceChip(
                  label: Text(_formatEnum(mood.toString())),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedMood = mood),
                  selectedColor: AppColors.accent.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Pain Level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pain Level', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_painLevel.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
              ],
            ),
            Slider(
              value: _painLevel,
              min: 0,
              max: 10,
              divisions: 10,
              label: _painLevel.toInt().toString(),
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _painLevel = val),
            ),
            const SizedBox(height: 24),

            // Symptoms
            const Text('Symptoms', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Symptom.values.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(_formatEnum(symptom.toString())),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) _selectedSymptoms.add(symptom);
                      else _selectedSymptoms.remove(symptom);
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Notes
            const Text('Optional notes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any additional details...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            AppButton(
              onPressed: _saveLog,
              label: 'Save Log',
              isLoading: _isLoading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
