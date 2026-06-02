import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_layout.dart';
import '../auth/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWeb = ResponsiveLayout.isWeb(context);

    if (isWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('System Settings'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton.icon(
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
                context.go('/auth/login');
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 32),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure Sparkle Lite Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.6,
                children: [
                  // Card 1: Account & Security
                  _buildWebSettingsCard(
                    title: 'Account & Security',
                    description: 'Manage details regarding your local screen security, privacy constraints, and general data visibility.',
                    icon: Icons.security,
                    color: Colors.blue,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.privacy_tip, color: AppColors.primary),
                        title: const Text('Privacy & Display Settings'),
                        subtitle: const Text('Toggle dashboard data sensitivity'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/dashboard/settings/privacy'),
                      ),
                    ],
                  ),
                  
                  // Card 2: Family & Sharing
                  _buildWebSettingsCard(
                    title: 'Family & Sharing',
                    description: 'Set up dependent patient profiles, manage sharing access, and oversee data syncing among relatives.',
                    icon: Icons.family_restroom,
                    color: Colors.teal,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.people, color: AppColors.primary),
                        title: const Text('Family Profiles'),
                        subtitle: const Text('Manage caregivers or dependents'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/dashboard/settings/family'),
                      ),
                    ],
                  ),

                  // Card 3: Support & Information
                  _buildWebSettingsCard(
                    title: 'Support & Help Center',
                    description: 'Get help with symptom logs, read our user guides, or learn about data encryption standards.',
                    icon: Icons.help_outline,
                    color: Colors.purple,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.help_center, color: AppColors.primary),
                        title: const Text('Help Center Documentation'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),

                  // Card 4: Product Specifications
                  _buildWebSettingsCard(
                    title: 'About Sparkle Lite',
                    description: 'Read the privacy policy, terms of service, and verify client application build references.',
                    icon: Icons.info_outline,
                    color: Colors.grey,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info, color: AppColors.primary),
                        title: const Text('Version 1.0.0 Build Specifications'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Default Mobile Layout
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Account & Security',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Display'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/dashboard/settings/privacy'),
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          const Text(
            'Family & Sharing',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('Family Profiles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/dashboard/settings/family'),
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          const Text(
            'Support & About',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help Center'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          const SizedBox(height: 32),
          
          Center(
            child: TextButton.icon(
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
                context.go('/auth/login');
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWebSettingsCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const Spacer(),
            ...children,
          ],
        ),
      ),
    );
  }
}
