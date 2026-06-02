import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/family_member.dart';
import 'family_profile_controller.dart';
import 'privacy_controller.dart';
import 'package:go_router/go_router.dart';

class FamilyProfileScreen extends ConsumerWidget {
  const FamilyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyProfileControllerProvider);
    final privacyState = ref.watch(privacyControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Sharing'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (members) {
          final isFamilyEnabled = privacyState.value?.familyProfileAccessEnabled ?? false;
          
          if (!isFamilyEnabled) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Family Profile Disabled',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Family profile is currently disabled in your privacy settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Go to Privacy Settings',
                      onPressed: () => context.push('/settings/privacy'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.family_restroom, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No Family Members Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Link your account with family members to securely share health updates and timelines.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(member.nameOrNickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${member.relationship.name} • ${member.ageRange}'),
                        trailing: const Icon(Icons.link, color: AppColors.accent),
                        isThreeLine: member.notes != null && member.notes!.isNotEmpty,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: privacyState.value?.familyProfileAccessEnabled == true 
        ? FloatingActionButton.extended(
            onPressed: () => _showAddMemberDialog(context, ref),
            label: const Text('Add Member'),
            icon: const Icon(Icons.person_add),
          )
        : null,
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const _AddMemberForm(),
        );
      },
    );
  }
}

class _AddMemberForm extends ConsumerStatefulWidget {
  const _AddMemberForm();

  @override
  ConsumerState<_AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends ConsumerState<_AddMemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageRangeController = TextEditingController();
  final _notesController = TextEditingController();
  Relationship _relationship = Relationship.parent;

  @override
  void dispose() {
    _nameController.dispose();
    _ageRangeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(familyProfileControllerProvider.notifier).addMember(
        _nameController.text,
        _relationship,
        _ageRangeController.text,
        _notesController.text,
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('Add Family Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Name or Nickname',
              controller: _nameController,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            const Text('Relationship', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Relationship>(
              value: _relationship,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: Relationship.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
              onChanged: (v) => setState(() => _relationship = v!),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Age Range (e.g. 30-40)',
              controller: _ageRangeController,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Notes (Max 500 chars)',
              controller: _notesController,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: _submit,
              label: 'Save Details',
            ),
          ],
        ),
      ),
    );
  }
}
