import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../symptom_tracker/symptom_controller.dart';
import 'ai_insight_controller.dart';
import '../../data/models/ai_insight.dart';

class AiInsightsScreen extends ConsumerStatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  ConsumerState<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends ConsumerState<AiInsightsScreen> {
  final Set<String> _selectedLogIds = {};
  bool _isLoading = false;

  void _generateInsight() async {
    if (_selectedLogIds.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final insight = await ref.read(aiInsightControllerProvider.notifier)
          .generateInsightFromSymptoms(_selectedLogIds.toList());
      
      if (mounted) {
        context.push('/insight-result', extra: insight);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsState = ref.watch(symptomControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Insight'),
      ),
      body: logsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No symptom logs found. Log some symptoms first to generate an insight.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondaryLight),
                ),
              ),
            );
          }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select the symptom logs you want to include in this analysis. Our AI will analyze patterns and suggest potential insights or questions for your doctor.',
                  style: TextStyle(color: AppColors.textSecondaryLight),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final isSelected = _selectedLogIds.contains(log.id);
                    return CheckboxListTile(
                      title: Text(DateFormat('MMM dd, yyyy').format(log.date)),
                      subtitle: Text('Pain: ${log.painLevel}/10, Flow: ${log.flowLevel.name}'),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedLogIds.add(log.id);
                          } else {
                            _selectedLogIds.remove(log.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppButton(
                  label: 'Analyze Selected Logs',
                  isLoading: _isLoading,
                  onPressed: _selectedLogIds.isEmpty ? null : _generateInsight,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
