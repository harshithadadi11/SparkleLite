import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import 'symptom_controller.dart';

class SymptomHistoryScreen extends ConsumerWidget {
  const SymptomHistoryScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomLogsState = ref.watch(symptomControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom History'),
        automaticallyImplyLeading: false,
      ),
      body: symptomLogsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No symptoms logged yet.',
                      style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Log First Symptom',
                      onPressed: () => context.push('/symptoms/add'),
                    )
                  ],
                ),
              ),
            );
          }

          final sortedLogs = List.of(logs)..sort((a, b) => b.date.compareTo(a.date));

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger a refresh (assuming controller has a refresh method or invalidation)
              ref.invalidate(symptomControllerProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sortedLogs.length,
              itemBuilder: (context, index) {
                final log = sortedLogs[index];
                return Dismissible(
                  key: Key(log.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Delete Log'),
                          content: const Text('Are you sure you want to delete this symptom log?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    ref.read(symptomControllerProvider.notifier).deleteLog(log.id);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: InkWell(
                    onTap: () {
                      context.push('/symptoms/add/${log.id}', extra: log);
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(log.date),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                                      tooltip: 'Edit Log',
                                      onPressed: () {
                                        context.push('/symptoms/add/${log.id}', extra: log);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Pain: ${log.painLevel}/10',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (log.symptoms.isNotEmpty) ...[
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: log.symptoms.map((s) {
                                  return Chip(
                                    label: Text(s.name),
                                    backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                                    labelStyle: const TextStyle(fontSize: 12),
                                    padding: EdgeInsets.zero,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Icon(Icons.water_drop, size: 16, color: Colors.red[300]),
                                const SizedBox(width: 4),
                                Text('Flow: ${log.flowLevel.name}'),
                                const SizedBox(width: 16),
                                Icon(Icons.mood, size: 16, color: Colors.orange[300]),
                                const SizedBox(width: 4),
                                Text('Mood: ${log.mood.name}'),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(log.periodStatus.name, style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            if (log.notes != null && log.notes!.isNotEmpty) ...[
                              const Divider(height: 24),
                              Text(
                                log.notes!,
                                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
