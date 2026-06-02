import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/responsive_layout.dart';
import '../profile/profile_controller.dart';
import '../symptom_tracker/symptom_controller.dart';
import '../health_records/health_record_controller.dart';
import 'doctor_summary_controller.dart';

class DoctorSummaryScreen extends ConsumerStatefulWidget {
  const DoctorSummaryScreen({super.key});

  @override
  ConsumerState<DoctorSummaryScreen> createState() => _DoctorSummaryScreenState();
}

class _DoctorSummaryScreenState extends ConsumerState<DoctorSummaryScreen> {
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<String> _questions = [
    "What might be causing my recent symptoms?",
    "Are there any tests you would recommend?",
    "When should I schedule my next check-up?"
  ];
  
  bool _isGenerating = false;
  String? _generatedSummaryText;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileControllerProvider).valueOrNull;
      if (profile != null && profile.medications != null && profile.medications!.isNotEmpty) {
        _medicationsController.text = profile.medications!;
      }
    });
  }

  @override
  void dispose() {
    _medicationsController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Question'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Enter your question'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  setState(() => _questions.add(ctrl.text));
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editQuestion(int index) {
    final ctrl = TextEditingController(text: _questions[index]);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Question'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  setState(() => _questions[index] = ctrl.text);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isGenerating = true;
      _generatedSummaryText = null;
    });

    try {
      await ref.read(doctorSummaryControllerProvider.notifier).generateSummary(
        notes: _notesController.text,
        medications: _medicationsController.text,
        questions: _questions,
      );
      
      final summaries = ref.read(doctorSummaryControllerProvider).valueOrNull ?? [];
      if (summaries.isNotEmpty) {
        setState(() {
          _generatedSummaryText = summaries.first.summaryText;
        });
        
        // Scroll to preview on mobile
        if (!ResponsiveLayout.isWeb(context)) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_previewKey.currentContext != null) {
              Scrollable.ensureVisible(
                _previewKey.currentContext!,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating summary: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _copyToClipboard() {
    if (_generatedSummaryText != null) {
      Clipboard.setData(ClipboardData(text: _generatedSummaryText!));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary copied to clipboard')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final logsState = ref.watch(symptomControllerProvider);
    final recordsState = ref.watch(healthRecordControllerProvider);
    final summaryState = ref.watch(doctorSummaryControllerProvider);

    final logs = logsState.valueOrNull ?? [];
    final recentLogs = logs.where((l) => l.date.isAfter(DateTime.now().subtract(const Duration(days: 30)))).take(5).toList();
    
    final records = recordsState.valueOrNull ?? [];
    final recentRecords = records.where((r) => r.recordDate.isAfter(DateTime.now().subtract(const Duration(days: 30)))).toList();
    
    final lastSummary = summaryState.valueOrNull?.isNotEmpty == true ? summaryState.valueOrNull!.first : null;
    final isWeb = ResponsiveLayout.isWeb(context);

    // Dynamic fallback for the latest summary text if not set in state yet
    if (_generatedSummaryText == null && lastSummary != null) {
      _generatedSummaryText = lastSummary.summaryText;
    }

    if (isWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Doctor Visit Summary Prep'),
          automaticallyImplyLeading: false,
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: User Inputs (1/2 width)
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lastSummary != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Last generated: ${DateFormat('MMM dd, yyyy h:mm a').format(lastSummary.generatedAt)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),

                    // Profile Basics
                    const Text('Profile Basics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    if (profileState.valueOrNull != null)
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Name: ${profileState.value!.nameOrNickname}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Age: ${profileState.value!.ageRange}'),
                              Text('Stage: ${profileState.value!.lifeStage.name}'),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Current Medications
                    const Text('Current Medications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Medications List',
                      controller: _medicationsController,
                      hint: 'Enter your current medications & dosage (e.g. Vitamins, Thyroid)',
                    ),
                    
                    const SizedBox(height: 24),

                    // Questions to Ask
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Practitioner Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                        TextButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _questions.length,
                      itemBuilder: (context, idx) {
                        final q = _questions[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.help_outline, color: AppColors.primary),
                            title: Text(q, style: const TextStyle(fontSize: 14)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                  onPressed: () => _editQuestion(idx),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                  onPressed: () => setState(() => _questions.removeAt(idx)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Personal Notes
                    const Text('Personal Practitioner Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        hintText: 'Add any specific symptoms, mood changes, or context you want to cover with your doctor.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Generate Button
                    if (logs.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.assignment_late, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('No symptom logs found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text('Please add some symptom logs to prepare a meaningful clinical summary.', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Log a symptom',
                              onPressed: () => context.push('/symptoms/add'),
                            ),
                          ],
                        ),
                      )
                    else
                      AppButton(
                        label: 'Generate Visit Summary Sheet',
                        isLoading: _isGenerating,
                        onPressed: _isGenerating ? null : _generateSummary,
                      ),
                  ],
                ),
              ),
            ),
            
            const VerticalDivider(width: 1, thickness: 1),

            // Right Column: Summary Sheet Document Preview (1/2 width)
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prepared Clinical Preview',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (_generatedSummaryText != null)
                          OutlinedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy to Clipboard'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_generatedSummaryText == null)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_turned_in, size: 64, color: AppColors.primary.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              const Text(
                                'Prep Document is Ready to Generate',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Confirm your medications, notes, and questions on the left and click "Generate Visit Summary Sheet" to preview.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: SelectableText(
                          _generatedSummaryText!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5, color: Colors.black87),
                        ),
                      ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Helper context data visible to doctor
                    const Text('Underlying Data Included in Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    
                    Text('Recent Symptoms Logged (${recentLogs.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (recentLogs.isEmpty)
                      const Text('No symptoms recorded in the last 30 days.', style: TextStyle(color: Colors.grey, fontSize: 13))
                    else
                      ...recentLogs.map((log) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey[200]!)),
                        child: ListTile(
                          dense: true,
                          title: Text(DateFormat('EEEE, MMM dd').format(log.date), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Pain: ${log.painLevel}/10 | Phase: ${log.periodStatus.name} | Mood: ${log.mood.name}'),
                        ),
                      )),
                    
                    const SizedBox(height: 24),
                    Text('Clinical Records Uploaded (${recentRecords.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (recentRecords.isEmpty)
                      const Text('No clinical records uploaded in the last 30 days.', style: TextStyle(color: Colors.grey, fontSize: 13))
                    else
                      ...recentRecords.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey[200]!)),
                        child: ListTile(
                          dense: true,
                          title: Text(r.title),
                          subtitle: Text('Date: ${DateFormat('yyyy-MM-dd').format(r.recordDate)} | Practitioner: ${r.doctorName ?? 'N/A'}'),
                        ),
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default Mobile View Layout
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Visit Summary'),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastSummary != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Last generated: ${DateFormat('MMM dd, yyyy h:mm a').format(lastSummary.generatedAt)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),

            // Profile Basics
            const Text('Profile Basics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            const SizedBox(height: 8),
            if (profileState.valueOrNull != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${profileState.value!.nameOrNickname}'),
                      Text('Age Range: ${profileState.value!.ageRange}'),
                      Text('Life Stage: ${profileState.value!.lifeStage.name}'),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Current Medications
            const Text('Current Medications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            const SizedBox(height: 8),
            AppTextField(
              label: 'Current Medications',
              controller: _medicationsController,
              hint: 'Enter current medications',
            ),
            
            const SizedBox(height: 24),

            // Recent Symptom History
            const Text('Recent Symptom History (Last 5)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            const SizedBox(height: 8),
            if (recentLogs.isEmpty)
              const Text('No recent symptom logs found.', style: TextStyle(color: Colors.grey))
            else
              ...recentLogs.map((log) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(DateFormat('MMM dd').format(log.date), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Pain: ${log.painLevel}/10, Period: ${log.periodStatus.name}, Mood: ${log.mood.name}'),
                ),
              )),
              
            const SizedBox(height: 24),
            
            // Recent Health Records
            const Text('Recent Health Records (Last 30 Days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            const SizedBox(height: 8),
            if (recentRecords.isEmpty)
              const Text('No recent health records found.', style: TextStyle(color: Colors.grey))
            else
              ...recentRecords.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(r.title),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(r.recordDate)),
                  trailing: r.isPrivate ? const Icon(Icons.lock, size: 16, color: Colors.grey) : null,
                ),
              )),
              
            const SizedBox(height: 24),

            // Questions to Ask
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Questions to Ask', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                TextButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            ..._questions.asMap().entries.map((entry) {
              int idx = entry.key;
              String q = entry.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline, color: AppColors.primary),
                title: Text(q),
                onTap: () => _editQuestion(idx),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _questions.removeAt(idx)),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Personal Notes
            const Text('Personal Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Add any notes you want to share with your doctor',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Generate Button or Empty State
            if (logs.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.assignment_late, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('No symptom logs found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('Add some symptom logs first to generate a meaningful summary.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Log a symptom',
                      onPressed: () => context.push('/symptoms/add'),
                    ),
                  ],
                ),
              )
            else
              AppButton(
                label: 'Generate Summary',
                isLoading: _isGenerating,
                onPressed: _isGenerating ? null : _generateSummary,
              ),

            const SizedBox(height: 32),

            // Preview Section
            if (_generatedSummaryText != null) ...[
              Divider(key: _previewKey, height: 32, thickness: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy text'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _generatedSummaryText!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 48),
            ]
          ],
        ),
      ),
    );
  }
}
