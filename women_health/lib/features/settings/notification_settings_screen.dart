import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'privacy_controller.dart';
import '../../core/constants/app_colors.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _enableNotifications = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privacyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Enable notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                value: _enableNotifications,
                onChanged: (val) => setState(() => _enableNotifications = val),
                activeColor: AppColors.primary,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Use generic notification text', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Keeps your health details private in notifications'),
                value: settings.useGenericNotificationText,
                onChanged: _enableNotifications
                    ? (val) {
                        ref.read(privacyControllerProvider.notifier).updateSettings(
                          settings.copyWith(useGenericNotificationText: val, updatedAt: DateTime.now())
                        );
                      }
                    : null,
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What this means', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.shield, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Expanded(child: Text("Generic: 'You have a health reminder.'")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.grey[700], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(child: Text("Detailed: 'Your symptom log reminder is due at 8:00 PM.'")),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
