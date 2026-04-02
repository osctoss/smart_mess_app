import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'signup_controller.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/enums.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupController(),
      child: GradientScaffold(
        appBar: AppBar(title: Text(AppStrings.signup)),
        body: Consumer<SignupController>(
          builder: (context, controller, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 8),
                  Text(
                    'Join Smart Mess to get started',
                    style: AppTextStyles.subtitle,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                  const SizedBox(height: 32),

                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: controller.nameController,
                          label: 'Full Name',
                          prefixIcon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 16),

                        // Phone with country code
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text('+91', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomTextField(
                                controller: controller.contactController,
                                label: 'Phone Number',
                                prefixIcon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: controller.passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock_rounded,
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),

                        // Role selector
                        Text('Choose your role', style: AppTextStyles.label),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _RoleChip(
                                label: 'Client',
                                icon: Icons.person_rounded,
                                isSelected: controller.selectedRole == UserRole.client,
                                onTap: () => controller.setRole(UserRole.client),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RoleChip(
                                label: 'Admin',
                                icon: Icons.admin_panel_settings_rounded,
                                isSelected: controller.selectedRole == UserRole.admin,
                                onTap: () => controller.setRole(UserRole.admin),
                              ),
                            ),
                          ],
                        ),

                        if (controller.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              controller.errorMessage!,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentRose),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 28),

                        CustomButton(
                          text: 'Send OTP & Sign Up',
                          icon: Icons.send_rounded,
                          onPressed: () => controller.sendOTP(context),
                          isLoading: controller.isLoading,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 600.ms),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentOrange.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentOrange : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppColors.accentOrange : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.accentOrange : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
