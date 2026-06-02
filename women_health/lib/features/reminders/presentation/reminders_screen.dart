import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/reminder_model.dart';
import '../providers/reminder_providers.dart';
import 'add_reminder_bottom_sheet.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  bool _isPastExpanded = false;

  void _showAddReminderSheet([ReminderModel? existingReminder]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReminderBottomSheet(existingReminder: existingReminder),
    );
  }

  IconData _getCategoryIcon(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.medication:
        return Icons.medication;
      case ReminderCategory.symptomLog:
        return Icons.monitor_heart;
      case ReminderCategory.appointment:
        return Icons.calendar_month;
      case ReminderCategory.hydration:
        return Icons.water_drop;
      case ReminderCategory.other:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
    final isTomorrow = time.year == now.year && time.month == now.month && time.day == now.day + 1;
    final diff = time.difference(now).inDays;

    final timeStr = DateFormat.jm().format(time);
    
    if (isToday) return 'Today at $timeStr';
    if (isTomorrow) return 'Tomorrow at $timeStr';
    if (diff > 0 && diff < 7) return '${DateFormat('E').format(time)} at $timeStr';
    return '${DateFormat('d MMM').format(time)} at $timeStr';
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // Returns to dashboard
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderSheet(),
        child: const Icon(Icons.add),
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (reminders) {
          final now = DateTime.now();
          
          final upcoming = reminders.where((r) => r.scheduledTime.isAfter(now) || r.repeat != ReminderRepeat.none).toList();
          final past = reminders.where((r) => r.scheduledTime.isBefore(now) && r.repeat == ReminderRepeat.none).toList();

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No reminders set', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Add a reminder to stay on top of your health routine.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Add reminder',
                    onPressed: () => _showAddReminderSheet(),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                const Text('Upcoming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...upcoming.map((r) => _buildReminderCard(r)),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 24),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: const Text('Past Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    initiallyExpanded: _isPastExpanded,
                    onExpansionChanged: (val) => setState(() => _isPastExpanded = val),
                    children: past.map((r) => _buildReminderCard(r)).toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) {
        ref.read(remindersNotifierProvider.notifier).deleteReminder(reminder.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _showAddReminderSheet(reminder),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(_getCategoryIcon(reminder.category), color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(_formatTime(reminder.scheduledTime), style: const TextStyle(color: Colors.grey)),
                          if (reminder.repeat != ReminderRepeat.none) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                reminder.repeat.name.toUpperCase(),
                                style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reminder.isActive,
                  onChanged: (val) {
                    ref.read(remindersNotifierProvider.notifier).toggleReminder(reminder.id, val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
