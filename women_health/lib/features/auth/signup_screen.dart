import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.signupTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  AppTextField(
                    label: "Full Name",
                    controller: nameController,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: "Email",
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email is required';
                      if (!val.contains('@')) return 'Invalid email format';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: "Password",
                    controller: passwordController,
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (val.length < 8) return 'Minimum 8 characters required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: "Confirm Password",
                    controller: confirmPasswordController,
                    obscureText: true,
                    validator: (val) {
                      if (val != passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  if (authState.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        authState.error.toString(),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 30),
                  AppButton(
                    label: AppStrings.signupButton,
                    isLoading: authState.isLoading,
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await ref.read(authControllerProvider.notifier).signup(
                          emailController.text,
                          passwordController.text,
                        );
                        if (mounted && !ref.read(authControllerProvider).hasError) {
                          // The prompt requests explicit navigation to profile setup on success.
                          // Usually app_router redirects based on authState, but if the
                          // user explicitly specified it, we can force a push or assume redirect handles it.
                          // Actually, we must use `context.go`
                          context.go('/profile/setup');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/auth/login'),
                    child: const Text('Already have an account? Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}