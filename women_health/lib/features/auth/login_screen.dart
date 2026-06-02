import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/app_router.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';
import '../../data/repositories/mock_backend.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
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
                    const SizedBox(height: 10),
                    if (authState.hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          authState.error.toString(),
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: AppStrings.loginButton,
                      isLoading: authState.isLoading,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await ref.read(authControllerProvider.notifier).login(
                            emailController.text,
                            passwordController.text,
                          );
                          if (mounted && !ref.read(authControllerProvider).hasError) {
                            final user = ref.read(authRepoProvider).currentUser;
                            if (user != null) {
                              final profile = await ref.read(profileRepoProvider).getProfile(user.uid);
                              if (profile != null) {
                                context.go('/dashboard');
                                return;
                              }
                            }
                            context.go('/profile/setup');
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        context.push('/auth/signup');
                      },
                      child: const Text("Create Account"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}