import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'availability_list_controller.dart';
import '../../../core/constants/enums.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../shared_widgets/animated_list_item.dart';
import '../../shared_widgets/status_badge.dart';
import '../../shared_widgets/shimmer_loading.dart';

class AvailabilityListScreen extends StatelessWidget {
  const AvailabilityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AvailabilityListController(),
      child: GradientScaffold(
        appBar: AppBar(title: const Text('Availability List')),
        body: Consumer<AvailabilityListController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                // Date picker
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _navButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => controller.onDateSelected(
                            controller.selectedDate.subtract(const Duration(days: 1)),
                          ),
                        ),
                        Text(
                          DateFormat('EEE, MMM d').format(controller.selectedDate),
                          style: AppTextStyles.heading4,
                        ),
                        _navButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: () => controller.onDateSelected(
                            controller.selectedDate.add(const Duration(days: 1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Meal chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _mealChip(
                        label: 'Morning',
                        icon: Icons.wb_sunny_rounded,
                        isSelected: controller.selectedMeal == MealType.morning,
                        onTap: () => controller.setMealType(MealType.morning),
                      ),
                      const SizedBox(width: 12),
                      _mealChip(
                        label: 'Evening',
                        icon: Icons.nightlight_round,
                        isSelected: controller.selectedMeal == MealType.evening,
                        onTap: () => controller.setMealType(MealType.evening),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                if (controller.isLoading)
                  Expanded(child: ShimmerLoading.listPlaceholder())
                else
                  Expanded(
                    child: controller.allMembers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text('No members found', style: AppTextStyles.subtitle),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: controller.allMembers.length,
                            itemBuilder: (context, index) {
                              final user = controller.allMembers[index];
                              final isAvailable = controller.isUserAvailable(user.uid);
                              return AnimatedListItem(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GlassCard(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            gradient: isAvailable ? AppColors.tealGradient : AppColors.primaryGradient,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(user.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                        StatusBadge(
                                          text: isAvailable ? 'Available' : 'Off',
                                          variant: isAvailable ? BadgeVariant.success : BadgeVariant.danger,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                // Summary footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    border: Border(top: BorderSide(color: AppColors.glassBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_rounded, color: AppColors.accentTeal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Available: ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        '${controller.availableCount}',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.accentTeal, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' / ${controller.allMembers.length}',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.accentOrange, size: 22),
      ),
    );
  }

  Widget _mealChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentOrange.withValues(alpha: 0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accentOrange : AppColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.accentOrange : AppColors.textSecondary),
            const SizedBox(width: 8),
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
