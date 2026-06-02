import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../data/models/health_record.dart';
import 'health_record_controller.dart';
import 'upload_record_screen.dart';

class HealthRecordsScreen extends ConsumerStatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  ConsumerState<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends ConsumerState<HealthRecordsScreen> {
  RecordType? _selectedFilter; // null means 'All'

  String _getRecordTypeLabel(RecordType type) {
    switch (type) {
      case RecordType.labReport: return 'Lab Report';
      case RecordType.prescription: return 'Prescription';
      case RecordType.scanReport: return 'Scan';
      case RecordType.doctorVisitNote: return 'Doctor Note';
      case RecordType.vaccinationRecord: return 'Vaccination';
      case RecordType.other: return 'Other';
    }
  }

  Color _getRecordTypeColor(RecordType type) {
    switch (type) {
      case RecordType.labReport: return Colors.blue;
      case RecordType.prescription: return Colors.teal;
      case RecordType.scanReport: return Colors.purple;
      case RecordType.doctorVisitNote: return Colors.grey;
      case RecordType.vaccinationRecord: return Colors.green;
      case RecordType.other: return Colors.amber;
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(healthRecordControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthRecordControllerProvider);
    final isWeb = ResponsiveLayout.isWeb(context);

    if (isWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Health Records Manager'),
          automaticallyImplyLeading: false,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
                      child: UploadRecordScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload New Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 32),
          ],
        ),
        body: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                AppButton(label: 'Retry', onPressed: _refresh),
              ],
            ),
          ),
          data: (allRecords) {
            final records = _selectedFilter == null 
                ? allRecords 
                : allRecords.where((r) => r.recordType == _selectedFilter).toList();

            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Web-appropriate top filter bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Uploaded Reports & Clinical Records',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Text('Filter by Type: ', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<RecordType?>(
                                value: _selectedFilter,
                                hint: const Text('All Types'),
                                items: [
                                  const DropdownMenuItem<RecordType?>(
                                    value: null,
                                    child: Text('All Types'),
                                  ),
                                  ...RecordType.values.map((type) => DropdownMenuItem<RecordType?>(
                                    value: type,
                                    child: Text(_getRecordTypeLabel(type)),
                                  )),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedFilter = value);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh Records',
                            onPressed: _refresh,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Table Content Card
                  Expanded(
                    child: records.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No records match the active filter',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text('Try selecting a different filter or upload a new record.', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 16),
                                AppButton(
                                  label: 'Clear Filters',
                                  onPressed: () => setState(() => _selectedFilter = null),
                                ),
                              ],
                            ),
                          )
                        : Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                                  horizontalMargin: 24,
                                  columnSpacing: 24,
                                  columns: const [
                                    DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Record Type', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Doctor Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Sharing', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: records.map((record) {
                                    final color = _getRecordTypeColor(record.recordType);
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(DateFormat('d MMM yyyy').format(record.recordDate))),
                                        DataCell(
                                          Row(
                                            children: [
                                              Text(record.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              if (record.isPrivate)
                                                const Padding(
                                                  padding: EdgeInsets.only(left: 8),
                                                  child: Icon(Icons.lock, size: 14, color: Colors.grey),
                                                ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _getRecordTypeLabel(record.recordType),
                                              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(record.doctorName?.isNotEmpty == true ? record.doctorName! : 'N/A')),
                                        DataCell(
                                          Row(
                                            children: [
                                              Icon(
                                                record.isPrivate ? Icons.visibility_off : Icons.visibility,
                                                size: 16,
                                                color: record.isPrivate ? Colors.redAccent : Colors.green,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(record.isPrivate ? 'Only Me' : 'Shared with Family'),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                                            tooltip: 'Open details',
                                            onPressed: () => context.push('/dashboard/records/${record.id}'),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Default Mobile View Layout
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedFilter == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = null);
                    },
                  ),
                ),
                ...RecordType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getRecordTypeLabel(type)),
                      selected: _selectedFilter == type,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = selected ? type : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      AppButton(label: 'Retry', onPressed: _refresh),
                    ],
                  ),
                ),
                data: (allRecords) {
                  final records = _selectedFilter == null 
                      ? allRecords 
                      : allRecords.where((r) => r.recordType == _selectedFilter).toList();

                  if (records.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 100),
                        const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No records yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload your first health record to keep everything in one place.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: AppButton(
                            label: 'Upload record',
                            onPressed: () => context.push('/dashboard/records/upload'),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final color = _getRecordTypeColor(record.recordType);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => context.push('/dashboard/records/${record.id}'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        record.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    if (record.isPrivate)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(Icons.lock, size: 16, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getRecordTypeLabel(record.recordType),
                                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat('d MMM yyyy').format(record.recordDate),
                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                                if (record.doctorName != null && record.doctorName!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    record.doctorName!,
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/dashboard/records/upload'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.upload_file, color: Colors.white),
      ),
    );
  }
}
