import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/health_profile.dart';
import '../../data/repositories/mock_backend.dart';
import 'profile_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _currentStep = 0;
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Step 1: Basics
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  LifeStage? _selectedLifeStage;

  // Step 2: Medical
  String? _selectedCycleStatus;
  final Set<String> _selectedConditions = {};
  final _medicationsController = TextEditingController();

  // Step 3: Preferences
  PrivacyLevel _privacyPreference = PrivacyLevel.standard;
  bool _notificationsEnabled = true;

  final List<String> _cycleStatuses = ['Regular', 'Irregular', 'No period', 'Not applicable'];
  final List<String> _commonConditions = ['PCOS', 'Thyroid', 'Diabetes', 'Endometriosis', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  String _calculateAgeRange(int age) {
    if (age < 18) return 'Under 18';
    if (age <= 24) return '18-24';
    if (age <= 34) return '25-34';
    if (age <= 44) return '35-44';
    if (age <= 54) return '45-54';
    return '55+';
  }

  String _getLifeStageLabel(LifeStage stage) {
    switch (stage) {
      case LifeStage.generalWellness: return 'General wellness';
      case LifeStage.periodTracking: return 'Period tracking';
      case LifeStage.fertilityPlanning: return 'Fertility planning';
      case LifeStage.pregnancy: return 'Pregnancy';
      case LifeStage.postpartum: return 'Postpartum';
      case LifeStage.menopause: return 'Menopause/perimenopause';
    }
  }

  Future<void> _submitProfile() async {
    final ageStr = _ageController.text.trim();
    final age = int.tryParse(ageStr) ?? 0;

    final profile = HealthProfile(
      userId: ref.read(authRepoProvider).currentUser!.uid,
      nameOrNickname: _nameController.text.trim(),
      age: age,
      ageRange: _calculateAgeRange(age),
      lifeStage: _selectedLifeStage!,
      menstrualCycleStatus: _selectedCycleStatus,
      knownConditions: _selectedConditions.toList(),
      medications: _medicationsController.text.trim().isEmpty ? null : _medicationsController.text.trim(),
      privacyPreference: _privacyPreference,
      notificationsEnabled: _notificationsEnabled,
      useGenericNotifications: true, // defaults to true as per requirements
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(profileControllerProvider.notifier).saveProfile(profile);
    
    final nextState = ref.read(profileControllerProvider);
    if (nextState.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${nextState.error}')),
        );
      }
      return;
    }
    
    if (mounted) {
      context.go('/dashboard');
    }
  }

  void _onStepContinue() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep == 0 && _selectedLifeStage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a life stage.')),
        );
        return;
      }
      if (_currentStep < 2) {
        setState(() => _currentStep += 1);
      } else {
        _submitProfile();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name or Nickname *',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age *',
              border: OutlineInputBorder(),
              hintText: '13-100',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              final age = int.tryParse(value.trim());
              if (age == null || age < 13 || age > 100) return 'Enter a valid age between 13 and 100';
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text('Primary Life Stage Focus *', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: LifeStage.values.map((stage) {
              final isSelected = _selectedLifeStage == stage;
              return ChoiceChip(
                label: Text(_getLifeStageLabel(stage)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedLifeStage = stage);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCycleStatus,
            decoration: const InputDecoration(
              labelText: 'Menstrual Cycle Status (Optional)',
              border: OutlineInputBorder(),
            ),
            items: _cycleStatuses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedCycleStatus = v),
          ),
          const SizedBox(height: 24),
          const Text('Known Conditions (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _commonConditions.map((condition) {
              final isSelected = _selectedConditions.contains(condition);
              return FilterChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedConditions.add(condition);
                    } else {
                      _selectedConditions.remove(condition);
                    }
                  });
                },
                selectedColor: AppColors.accent.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _medicationsController,
            decoration: const InputDecoration(
              labelText: 'Current Medications (Optional)',
              hintText: 'e.g. Metformin, Levothyroxine',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Privacy Preference *', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<PrivacyLevel>(
            segments: const [
              ButtonSegment(value: PrivacyLevel.standard, label: Text('Standard')),
              ButtonSegment(value: PrivacyLevel.enhanced, label: Text('Enhanced')),
            ],
            selected: {_privacyPreference},
            onSelectionChanged: (newSelection) {
              setState(() => _privacyPreference = newSelection.first);
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Profile Setup'),
        automaticallyImplyLeading: false,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        onStepTapped: (step) {
          if (step < _currentStep) {
            setState(() => _currentStep = step);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    onPressed: details.onStepContinue,
                    label: _currentStep == 2 ? 'Save Profile' : 'Next',
                    isLoading: _currentStep == 2 ? profileState.isLoading : false,
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      onPressed: details.onStepCancel,
                      label: 'Back',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Basics'),
            content: _buildStep1(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Medical'),
            content: _buildStep2(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Privacy'),
            content: _buildStep3(),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }
}
