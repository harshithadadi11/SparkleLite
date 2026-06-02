import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_layout.dart';
import '../symptom_tracker/symptom_controller.dart';
import '../health_records/health_record_controller.dart';
import 'timeline_controller.dart';
import '../../data/models/timeline_entry_model.dart';
import '../../data/models/symptom_log.dart';
import '../../data/models/health_record.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  String? _selectedEntryId;

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineControllerProvider);
    final isWeb = ResponsiveLayout.isWeb(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Timeline & Health History'),
        automaticallyImplyLeading: false,
      ),
      body: timelineState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'Your timeline is empty. Log some data to see it here!',
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Automatically select first entry if none selected
          if (_selectedEntryId == null && entries.isNotEmpty) {
            _selectedEntryId = entries.first.id;
          }

          final selectedEntry = entries.firstWhere(
            (e) => e.id == _selectedEntryId,
            orElse: () => entries.first,
          );

          if (isWeb) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1/3 Timeline List Master View
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24.0),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final isLast = index == entries.length - 1;
                        final isSelected = entry.id == _selectedEntryId;
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedEntryId = entry.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _buildTimelineTile(context, entry, isLast, isWeb: true),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // 2/3 Timeline Detail View
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.grey[50],
                    padding: const EdgeInsets.all(32.0),
                    child: _buildDetailPane(selectedEntry),
                  ),
                ),
              ],
            );
          }

          // Default Mobile View
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isLast = index == entries.length - 1;
              return InkWell(
                onTap: () => _showMobileDetailBottomSheet(context, entry),
                child: _buildTimelineTile(context, entry, isLast),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimelineTile(BuildContext context, TimelineEntry entry, bool isLast, {bool isWeb = false}) {
    final isSymptom = entry.entryType == TimelineEntryType.symptomLog;
    final dotColor = isSymptom ? AppColors.primary : Colors.blue;
    final icon = isSymptom ? Icons.favorite : Icons.folder;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                elevation: isWeb ? 0 : 1,
                color: isWeb ? Colors.transparent : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy - h:mm a').format(entry.date),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dotColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.summary,
                        style: const TextStyle(color: Colors.black87, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPane(TimelineEntry entry) {
    final isSymptom = entry.entryType == TimelineEntryType.symptomLog;
    final themeColor = isSymptom ? AppColors.primary : Colors.blue;
    
    // Attempt lookup in controllers
    final symptomLogs = ref.watch(symptomControllerProvider).valueOrNull ?? [];
    final healthRecords = ref.watch(healthRecordControllerProvider).valueOrNull ?? [];
    
    SymptomLog? underlyingSymptom;
    HealthRecord? underlyingRecord;
    
    if (isSymptom) {
      underlyingSymptom = symptomLogs.firstWhere(
        (s) => s.id == entry.sourceId, 
        orElse: () => SymptomLog(
          id: entry.sourceId,
          userId: entry.userId,
          date: entry.date,
          painLevel: 0,
          flowLevel: FlowLevel.none,
          periodStatus: PeriodStatus.noPeriod,
          mood: Mood.calm,
          symptoms: [],
          createdAt: entry.createdAt,
          updatedAt: entry.createdAt,
        ),
      );
    } else {
      underlyingRecord = healthRecords.firstWhere(
        (r) => r.id == entry.sourceId,
        orElse: () => HealthRecord(
          id: entry.sourceId,
          userId: entry.userId,
          title: entry.title,
          recordType: RecordType.other,
          recordDate: entry.date,
          fileUrl: '',
          isPrivate: false,
          createdAt: entry.createdAt,
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Header
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: themeColor.withOpacity(0.1),
                  child: Icon(isSymptom ? Icons.favorite : Icons.folder, color: themeColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSymptom ? 'SYMPTOM LOG RECORD' : 'CLINICAL DOCUMENT',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: themeColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            // Meta Fields
            _buildDetailField('Date Recorded', DateFormat('EEEE, MMMM d, yyyy - h:mm a').format(entry.date)),
            const SizedBox(height: 16),
            
            // Context Specific Fields
            if (isSymptom && underlyingSymptom != null) ...[
              _buildDetailField('Pain Severity Indicator', '${underlyingSymptom.painLevel} / 10'),
              const SizedBox(height: 16),
              _buildDetailField('Menstrual Flow Level', underlyingSymptom.flowLevel.name.toUpperCase()),
              const SizedBox(height: 16),
              _buildDetailField('Cycle Period Phase', underlyingSymptom.periodStatus.name.toUpperCase()),
              const SizedBox(height: 16),
              _buildDetailField('Logged Mood', underlyingSymptom.mood.name.toUpperCase()),
              const SizedBox(height: 16),
              
              const Text('Logged Physical Symptoms', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              underlyingSymptom.symptoms.isEmpty
                  ? const Text('No specific symptom tags registered.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: underlyingSymptom.symptoms.map((s) {
                        return Chip(
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                          label: Text(s.name, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
            ] else if (underlyingRecord != null) ...[
              _buildDetailField('Document Classification', underlyingRecord.recordType.name.toUpperCase()),
              const SizedBox(height: 16),
              _buildDetailField('Consulting Practitioner', underlyingRecord.doctorName?.isNotEmpty == true ? underlyingRecord.doctorName! : 'Not specified'),
              const SizedBox(height: 16),
              _buildDetailField('Data Privacy Level', underlyingRecord.isPrivate ? 'Confidential (Only Me)' : 'Shared with Family Profiles'),
              const SizedBox(height: 16),
              if (underlyingRecord.notes?.isNotEmpty == true) ...[
                _buildDetailField('Clinical / Patient Notes', underlyingRecord.notes!),
                const SizedBox(height: 16),
              ],
              if (underlyingRecord.fileUrl != null && underlyingRecord.fileUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Open link action
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download clinical report file'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ],
            ],
            const Spacer(),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Created System Ref: ${entry.id} | Timestamp: ${DateFormat('yyyy-MM-dd HH:mm').format(entry.createdAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }

  void _showMobileDetailBottomSheet(BuildContext context, TimelineEntry entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      entry.entryType == TimelineEntryType.symptomLog ? Icons.favorite : Icons.folder,
                      color: entry.entryType == TimelineEntryType.symptomLog ? AppColors.primary : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  DateFormat('MMMM dd, yyyy - h:mm a').format(entry.date),
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  entry.summary,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
