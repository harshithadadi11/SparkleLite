import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/ai_insight.dart';
import 'ai_insight_controller.dart';

class InsightResultScreen extends ConsumerStatefulWidget {
  final AIInsight insight;
  const InsightResultScreen({super.key, required this.insight});

  @override
  ConsumerState<InsightResultScreen> createState() => _InsightResultScreenState();
}

class _InsightResultScreenState extends ConsumerState<InsightResultScreen> {
  bool _isSaving = false;

  void _saveInsight() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(aiInsightControllerProvider.notifier).saveInsight(widget.insight);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insight saved to timeline.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Insight'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text('AI Analysis Complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const Divider(height: 32),
            const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(widget.insight.summary, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text('Possible Pattern', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(widget.insight.possiblePattern, style: const TextStyle(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 24),
            const Text('Self-Care Guidance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(widget.insight.careGuidance, style: const TextStyle(color: AppColors.textSecondaryLight)),
            if (widget.insight.doctorQuestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Questions to ask your doctor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...widget.insight.doctorQuestions.map((q) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Expanded(child: Text(q, style: const TextStyle(color: AppColors.textSecondaryLight))),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4), // Pale yellow
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.insight.disclaimer,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Save to Timeline',
              isLoading: _isSaving,
              onPressed: _saveInsight,
            ),
          ],
        ),
      ),
    );
  }
}
