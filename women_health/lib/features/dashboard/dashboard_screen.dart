import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_layout.dart';
import '../ai_insights/ai_insight_controller.dart';
import '../ai_insights/insight_input_screen.dart';
import '../doctor_summary/doctor_summary_screen.dart';
import '../health_records/health_records_screen.dart';
import '../health_records/upload_record_screen.dart';
import '../symptom_tracker/symptom_history_screen.dart';
import '../timeline/timeline_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/family_profile_screen.dart';
import '../profile/profile_controller.dart';
import '../../data/repositories/mock_backend.dart';
import '../reminders/providers/reminder_providers.dart';
import '../settings/privacy_controller.dart';
import 'providers/dashboard_providers.dart';
import '../auth/auth_controller.dart';
import '../health_records/health_record_controller.dart';
import '../symptom_tracker/symptom_controller.dart';
import '../timeline/timeline_controller.dart';
import '../../data/models/timeline_entry_model.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _mobileSelectedIndex = 0;
  int _webSelectedIndex = 0;

  final List<Widget> _mobilePages = [
    const _HomeDashboard(),
    const SymptomHistoryScreen(),
    const TimelineScreen(),
    const SettingsScreen(),
  ];

  List<Widget> _webPages() => [
    const _WebDashboardOverview(),
    const SymptomHistoryScreen(),
    const HealthRecordsScreen(),
    const TimelineScreen(),
    const AiInsightsScreen(),
    const DoctorSummaryScreen(),
    const SettingsScreen(),
    const FamilyProfileScreen(),
  ];

  void _onMobileItemTapped(int index) {
    setState(() {
      _mobileSelectedIndex = index;
    });
  }

  void _onWebItemTapped(int index) {
    setState(() {
      _webSelectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: Scaffold(
        body: _mobilePages[_mobileSelectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _mobileSelectedIndex,
          onTap: _onMobileItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Symptoms'),
            BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Timeline'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
      webBody: Scaffold(
        body: Row(
          children: [
            // Premium Sidebar Navigation
            Container(
              width: 260,
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    height: 80,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.spa, color: AppColors.primary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Sparkle Lite',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildSidebarItem(0, 'Dashboard', Icons.dashboard),
                        _buildSidebarItem(1, 'Symptom Logs', Icons.favorite),
                        _buildSidebarItem(2, 'Health Records', Icons.folder),
                        _buildSidebarItem(3, 'Timeline / History', Icons.timeline),
                        _buildSidebarItem(4, 'AI Health Insights', Icons.auto_awesome),
                        _buildSidebarItem(5, 'Doctor Visit Summary', Icons.medical_services),
                        _buildSidebarItem(6, 'Settings', Icons.settings),
                        _buildSidebarItem(7, 'Family Sharing', Icons.people),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSidebarProfile(),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Main dynamic content pane
            Expanded(
              child: _webPages()[_webSelectedIndex],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon) {
    final isSelected = _webSelectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey[600]),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => _onWebItemTapped(index),
      ),
    );
  }

  Widget _buildSidebarProfile() {
    final profileState = ref.watch(profileControllerProvider);
    final name = profileState.value?.nameOrNickname ?? 'Guest';
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'G',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profileState.value != null ? 'Logged In' : 'Guest Mode',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              context.go('/auth/login');
            },
          )
        ],
      ),
    );
  }
}

class _HomeDashboard extends ConsumerWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildMobileDashboard(context, ref);
  }

  Widget _buildMobileDashboard(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final insightsState = ref.watch(aiInsightControllerProvider);
    final nextReminderState = ref.watch(nextReminderProvider);
    final privacyState = ref.watch(privacyControllerProvider);
    
    final bool hideSensitive = privacyState.value?.hideSensitiveDashboardDetails ?? true;

    final name = profileState.value?.nameOrNickname ?? 'Guest';
    final lifeStageLabel = profileState.value != null 
        ? profileState.value!.lifeStage.name 
        : 'General wellness';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sparkle Lite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hi, $name!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  tooltip: 'Edit Profile',
                  onPressed: () => context.push('/profile/setup'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Focus: $lifeStageLabel',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            
            // Next Reminder
            nextReminderState.when(
              data: (reminder) {
                if (reminder == null) {
                  return _buildInfoCard(
                    context,
                    title: 'No reminders set',
                    content: 'Tap to add your first reminder',
                    icon: Icons.notifications_off,
                    color: Colors.grey,
                    onTap: () => context.push('/dashboard/reminders'),
                  );
                }
                
                final isToday = reminder.scheduledTime.year == DateTime.now().year &&
                                reminder.scheduledTime.month == DateTime.now().month &&
                                reminder.scheduledTime.day == DateTime.now().day;
                final isTomorrow = reminder.scheduledTime.year == DateTime.now().year &&
                                   reminder.scheduledTime.month == DateTime.now().month &&
                                   reminder.scheduledTime.day == DateTime.now().day + 1;
                
                String timeStr = DateFormat.jm().format(reminder.scheduledTime);
                String dateStr;
                if (isToday) {
                  dateStr = 'Today at $timeStr';
                } else if (isTomorrow) {
                  dateStr = 'Tomorrow at $timeStr';
                } else {
                  dateStr = '${DateFormat('E, d MMM').format(reminder.scheduledTime)} at $timeStr';
                }

                return _buildInfoCard(
                  context,
                  title: reminder.title,
                  content: hideSensitive ? 'You have an upcoming reminder' : dateStr,
                  icon: Icons.notifications_active,
                  color: Colors.orange,
                  onTap: () => context.push('/dashboard/reminders'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // Recent Symptom Log
            ref.watch(recentSymptomLogProvider).when(
              data: (log) {
                if (log == null) {
                  return _buildInfoCard(
                    context,
                    title: 'No symptom logs yet',
                    content: 'Tap to log your first entry',
                    icon: Icons.history,
                    color: Colors.purple,
                    onTap: () => context.push('/symptoms/add'),
                  );
                }
                
                final dateStr = DateFormat('MMM d').format(log.date);
                return _buildInfoCard(
                  context,
                  title: 'Recent Log',
                  content: hideSensitive ? 'Health data recorded - $dateStr' : '$dateStr, Pain: ${log.painLevel}/10, Mood: ${log.mood}',
                  icon: Icons.history,
                  color: Colors.purple,
                  onTap: () => context.push('/dashboard/symptoms/history'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // Recent Uploaded Report
            ref.watch(recentHealthRecordProvider).when(
              data: (record) {
                if (record == null) {
                  return _buildInfoCard(
                    context,
                    title: 'No records uploaded yet',
                    content: 'Tap to upload your first record',
                    icon: Icons.folder,
                    color: Colors.blue,
                    onTap: () => context.push('/dashboard/records/upload'),
                  );
                }
                
                final dateStr = DateFormat('MMM d').format(record.recordDate);
                return _buildInfoCard(
                  context,
                  title: 'Recent Record',
                  content: hideSensitive ? 'Health record uploaded - $dateStr' : '${record.title} - $dateStr',
                  icon: Icons.folder,
                  color: Colors.blue,
                  onTap: () => context.push('/dashboard/records'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 24),

            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildQuickActionGridItem(context, 'Log Symptom', Icons.add_circle, Colors.pink, () => context.push('/symptoms/add')),
                _buildQuickActionGridItem(context, 'Upload Report', Icons.upload_file, Colors.blue, () => context.push('/upload-record')),
                _buildQuickActionGridItem(context, 'Doctor Visit', Icons.medical_services, Colors.teal, () => context.push('/visit-prep')),
                _buildQuickActionGridItem(context, 'Ask AI', Icons.auto_awesome, Colors.purple, () => context.push('/insights')),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Latest Insight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            insightsState.when(
              data: (insights) {
                if (insights.isEmpty) return const Text('No insights available yet.');
                final insight = insights.first;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Text(
                    hideSensitive ? 'Insight available' : insight.summary, 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading insights'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String content, required IconData icon, required Color color, VoidCallback? onTap}) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildQuickActionGridItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _WebDashboardOverview extends ConsumerWidget {
  const _WebDashboardOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final insightsState = ref.watch(aiInsightControllerProvider);
    final recordsState = ref.watch(healthRecordControllerProvider);
    final symptomsState = ref.watch(symptomControllerProvider);
    final nextReminderState = ref.watch(nextReminderProvider);
    final privacyState = ref.watch(privacyControllerProvider);
    final timelineState = ref.watch(timelineControllerProvider);

    final name = profileState.value?.nameOrNickname ?? 'Guest';
    final lifeStageLabel = profileState.value != null 
        ? profileState.value!.lifeStage.name 
        : 'General wellness';
    
    final bool hideSensitive = privacyState.value?.hideSensitiveDashboardDetails ?? true;

    final logCount = symptomsState.value?.length ?? 0;
    final recordCount = recordsState.value?.length ?? 0;
    final insightCount = insightsState.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Overview'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            tooltip: 'Setup Health Profile',
            onPressed: () => context.push('/profile/setup'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Card(
              elevation: 0,
              color: AppColors.primary.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, $name!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your current focus: $lifeStageLabel. Keep track of your symptoms, reports, and AI insights.',
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.spa, size: 64, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Stat Cards Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Symptom Logs',
                    value: '$logCount Logs',
                    subtitle: 'Track your physical state',
                    icon: Icons.favorite,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildStatCard(
                    title: 'Health Records',
                    value: '$recordCount Reports',
                    subtitle: 'All documents in one place',
                    icon: Icons.folder,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildStatCard(
                    title: 'AI Health Insights',
                    value: '$insightCount Insights',
                    subtitle: 'Personalized AI summaries',
                    icon: Icons.auto_awesome,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Two-column Content Area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Quick Actions + Recent Activity Feed (2/3 space)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 3.0,
                        children: [
                          _buildQuickActionCard(
                            context,
                            'Log New Symptom',
                            'Record how you feel today',
                            Icons.add_circle,
                            Colors.pink,
                            () => context.push('/symptoms/add'),
                          ),
                          _buildQuickActionCard(
                            context,
                            'Upload Lab Report',
                            'Keep your records secure',
                            Icons.upload_file,
                            Colors.blue,
                            () {
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
                          ),
                          _buildQuickActionCard(
                            context,
                            'Doctor Visit Summary',
                            'Generate a prep sheet',
                            Icons.medical_services,
                            Colors.teal,
                            () => context.push('/visit-prep'),
                          ),
                          _buildQuickActionCard(
                            context,
                            'Get AI Insights',
                            'Analyze symptom patterns',
                            Icons.auto_awesome,
                            Colors.purple,
                            () => context.push('/insights'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        'Recent Activity Feed',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final symptomLogs = symptomsState.valueOrNull ?? [];
                            final healthRecords = recordsState.valueOrNull ?? [];
                            
                            final List<Map<String, dynamic>> activities = [];
                            
                            for (var log in symptomLogs.take(3)) {
                              activities.add({
                                'title': hideSensitive ? 'Health symptoms recorded' : 'Logged symptoms (Pain: ${log.painLevel}/10, Flow: ${log.flowLevel.name})',
                                'subtitle': DateFormat('MMM dd, yyyy').format(log.date),
                                'icon': Icons.favorite,
                                'color': Colors.pink,
                              });
                            }
                            
                            for (var record in healthRecords.take(3)) {
                              activities.add({
                                'title': hideSensitive ? 'New health record uploaded' : 'Uploaded document: ${record.title}',
                                'subtitle': DateFormat('MMM dd, yyyy').format(record.recordDate),
                                'icon': Icons.folder,
                                'color': Colors.blue,
                              });
                            }
                            
                            if (activities.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    'No recent activity. Try adding a log or uploading a record!',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }

                            // Sort by date equivalent if possible (simple fallback)
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activities.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final activity = activities[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: activity['color'].withOpacity(0.1),
                                    child: Icon(activity['icon'], color: activity['color'], size: 20),
                                  ),
                                  title: Text(
                                    activity['title'],
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(activity['subtitle']),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                
                // Right Column: Upcoming Reminder + Timeline Preview (1/3 space)
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upcoming reminder card
                      const Text(
                        'Next Reminder',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      nextReminderState.when(
                        data: (reminder) {
                          if (reminder == null) {
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.notifications_off, color: Colors.grey),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No upcoming reminders.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          final isToday = reminder.scheduledTime.year == DateTime.now().year &&
                                          reminder.scheduledTime.month == DateTime.now().month &&
                                          reminder.scheduledTime.day == DateTime.now().day;
                          final isTomorrow = reminder.scheduledTime.year == DateTime.now().year &&
                                             reminder.scheduledTime.month == DateTime.now().month &&
                                             reminder.scheduledTime.day == DateTime.now().day + 1;
                          
                          String timeStr = DateFormat.jm().format(reminder.scheduledTime);
                          String dateStr;
                          if (isToday) {
                            dateStr = 'Today at $timeStr';
                          } else if (isTomorrow) {
                            dateStr = 'Tomorrow at $timeStr';
                          } else {
                            dateStr = '${DateFormat('E, d MMM').format(reminder.scheduledTime)} at $timeStr';
                          }

                          return Card(
                            elevation: 1,
                            color: Colors.orange.withOpacity(0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.orange.withOpacity(0.2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.notifications_active, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          reminder.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    hideSensitive ? 'Scheduled Reminder' : dateStr,
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox(),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        'Timeline Preview',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: timelineState.when(
                          data: (entries) {
                            if (entries.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No timeline logs recorded yet.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }
                            final recentEntries = entries.take(4).toList();
                            return Column(
                              children: recentEntries.map((e) => _buildTimelineItem(
                                DateFormat('MMM dd').format(e.date), 
                                e.title, 
                                e.entryType == TimelineEntryType.symptomLog ? Colors.purple : Colors.blue,
                              )).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Text('Error loading timeline'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String date, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 12),
            child: Icon(Icons.circle, size: 10, color: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
