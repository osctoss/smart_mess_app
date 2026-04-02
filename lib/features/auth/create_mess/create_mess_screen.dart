import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'create_mess_controller.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class CreateMessScreen extends StatelessWidget {
  const CreateMessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateMessController(),
      child: GradientScaffold(
        appBar: AppBar(title: const Text('Create Mess')),
        body: Consumer<CreateMessController>(
          builder: (context, controller, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                  // Icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.amberGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentAmber.withValues(alpha: 0.3),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.store_rounded, size: 44, color: Colors.white),
                  )
                      .animate()
                      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 28),

                  Text(
                    'Setup Your Mess',
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                  const SizedBox(height: 8),
                  Text(
                    'Give your mess a name to get started',
                    style: AppTextStyles.subtitle,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                  const SizedBox(height: 36),

                  GlassCard(
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: controller.messNameController,
                          label: 'Mess Name',
                          prefixIcon: Icons.restaurant_rounded,
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
                          text: 'Create Mess',
                          icon: Icons.add_business_rounded,
                          onPressed: () => controller.createMess(context),
                          isLoading: controller.isLoading,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 600.ms),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
