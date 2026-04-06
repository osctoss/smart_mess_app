import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'menu_controller.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MenuManagementController(),
      child: GradientScaffold(
        appBar: AppBar(title: const Text('Menu Management')),
        body: Consumer<MenuManagementController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Weekday Selector
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (index) {
                          final weekday = index + 1; // 1-7
                          final isSelected = controller.selectedWeekday == weekday;
                          
                          const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final dayName = dayNames[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => controller.onWeekdaySelected(weekday),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? AppColors.primaryGradient : null,
                                  color: isSelected ? null : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.accentOrange.withValues(alpha: 0.5) : AppColors.glassBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  dayName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // Menu Form
                  GlassCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: AppColors.amberGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text('Morning Menu', style: AppTextStyles.label.copyWith(color: AppColors.accentAmber)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: controller.morningController,
                          label: 'Morning Menu',
                          prefixIcon: Icons.restaurant_rounded,
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.nightlight_round, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text('Evening Menu', style: AppTextStyles.label.copyWith(color: AppColors.accentOrange)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: controller.eveningController,
                          label: 'Evening Menu',
                          prefixIcon: Icons.restaurant_rounded,
                        ),

                        const SizedBox(height: 28),

                        CustomButton(
                          text: 'Save Menu',
                          icon: Icons.save_rounded,
                          onPressed: () => controller.saveMenu(context),
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
