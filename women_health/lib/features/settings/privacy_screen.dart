import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_layout.dart';
import 'privacy_controller.dart';
import '../../data/models/privacy_settings.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(privacyControllerProvider);
    final isWeb = ResponsiveLayout.isWeb(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Sharing Settings'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (settings) {
          if (isWeb) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy Preferences',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  const Text('Manage how your health metrics are displayed and who has permission to view them.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  
                  // Side-by-side cards on Web
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card 1: Data & Display Options
                      Expanded(
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.visibility_off, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text(
                                      'Data & Display Options',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildToggle(
                                  context,
                                  ref,
                                  settings,
                                  title: 'Hide sensitive dashboard details',
                                  subtitle: 'Replaces symptom and mood specifics with generic placeholder text on the home screen.',
                                  value: settings.hideSensitiveDashboardDetails,
                                  onChanged: (val) {
                                    ref.read(privacyControllerProvider.notifier).updateSettings(
                                      settings.copyWith(hideSensitiveDashboardDetails: val, updatedAt: DateTime.now())
                                    );
                                  },
                                ),
                                const Divider(height: 24),
                                _buildToggle(
                                  context,
                                  ref,
                                  settings,
                                  title: 'Use generic notification text',
                                  subtitle: 'Prevents clinical details from appearing in external system push notifications.',
                                  value: settings.useGenericNotificationText,
                                  onChanged: (val) {
                                    ref.read(privacyControllerProvider.notifier).updateSettings(
                                      settings.copyWith(useGenericNotificationText: val, updatedAt: DateTime.now())
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 24),

                      // Card 2: Sharing & Family Access
                      Expanded(
                        child: Column(
                          children: [
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.people, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text(
                                          'Sharing & Family Access',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    _buildToggle(
                                      context,
                                      ref,
                                      settings,
                                      title: 'Require confirmation before sharing',
                                      subtitle: 'Prompt a confirmation prompt before exporting report summaries or medical documents.',
                                      value: settings.requireConfirmationBeforeSharing,
                                      onChanged: (val) {
                                        ref.read(privacyControllerProvider.notifier).updateSettings(
                                          settings.copyWith(requireConfirmationBeforeSharing: val, updatedAt: DateTime.now())
                                        );
                                      },
                                    ),
                                    const Divider(height: 24),
                                    _buildToggle(
                                      context,
                                      ref,
                                      settings,
                                      title: 'Enable Family Profile Access',
                                      subtitle: 'Allow verified linked family profiles to synchronize and view non-sensitive history.',
                                      value: settings.familyProfileAccessEnabled,
                                      onChanged: (val) {
                                        ref.read(privacyControllerProvider.notifier).updateSettings(
                                          settings.copyWith(familyProfileAccessEnabled: val, updatedAt: DateTime.now())
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Danger Zone Card on Web
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.04),
                                border: Border.all(color: Colors.red.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        'Danger Zone Options',
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Deleting your account will permanently wipe all logs, reports, and setups from the backend databases. This is irreversible.', style: TextStyle(fontSize: 13)),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmation(context, ref);
                                    },
                                    child: const Text('Delete My Account Permanently'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // Default Mobile View
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data & Display',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                _buildToggle(
                  context,
                  ref,
                  settings,
                  title: 'Hide sensitive dashboard details',
                  subtitle: 'Replaces symptom and mood specifics with generic text on the home screen.',
                  value: settings.hideSensitiveDashboardDetails,
                  onChanged: (val) {
                    ref.read(privacyControllerProvider.notifier).updateSettings(
                      settings.copyWith(hideSensitiveDashboardDetails: val, updatedAt: DateTime.now())
                    );
                  },
                ),
                const Divider(),
                _buildToggle(
                  context,
                  ref,
                  settings,
                  title: 'Use generic notification text',
                  subtitle: 'Prevents health details from appearing in push notifications.',
                  value: settings.useGenericNotificationText,
                  onChanged: (val) {
                    ref.read(privacyControllerProvider.notifier).updateSettings(
                      settings.copyWith(useGenericNotificationText: val, updatedAt: DateTime.now())
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                const Text(
                  'Sharing & Family',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                _buildToggle(
                  context,
                  ref,
                  settings,
                  title: 'Require confirmation before sharing',
                  subtitle: 'Always ask before exporting PDFs or sharing records externally.',
                  value: settings.requireConfirmationBeforeSharing,
                  onChanged: (val) {
                    ref.read(privacyControllerProvider.notifier).updateSettings(
                      settings.copyWith(requireConfirmationBeforeSharing: val, updatedAt: DateTime.now())
                    );
                  },
                ),
                const Divider(),
                _buildToggle(
                  context,
                  ref,
                  settings,
                  title: 'Enable Family Profile Access',
                  subtitle: 'Allow linked family members to view non-sensitive timeline events.',
                  value: settings.familyProfileAccessEnabled,
                  onChanged: (val) {
                    ref.read(privacyControllerProvider.notifier).updateSettings(
                      settings.copyWith(familyProfileAccessEnabled: val, updatedAt: DateTime.now())
                    );
                  },
                ),

                const SizedBox(height: 48),
                
                // Danger Zone Block
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Danger Zone',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Deleting your account will permanently remove all your health records, symptom logs, and profile data from our servers. This action cannot be undone.'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () {
                            _showDeleteConfirmation(context, ref);
                          },
                          child: const Text('Delete Account'),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToggle(
    BuildContext context,
    WidgetRef ref,
    PrivacySettings settings, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: const Text('Are you absolutely sure? This will permanently erase all your data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Delete Permanently', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
