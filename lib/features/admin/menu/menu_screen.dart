import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
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
            if (controller.isLoading && controller.selectedDate == DateTime.now()) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Calendar
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: TableCalendar(
                      firstDay: DateTime.now().subtract(const Duration(days: 7)),
                      lastDay: DateTime.now().add(const Duration(days: 30)),
                      focusedDay: controller.selectedDate,
                      currentDay: DateTime.now(),
                      selectedDayPredicate: (day) => isSameDay(controller.selectedDate, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        controller.onDateSelected(selectedDay);
                      },
                      calendarFormat: CalendarFormat.week,
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: AppTextStyles.bodyMedium,
                        weekendTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        outsideTextStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        todayDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentOrange, width: 1.5),
                        ),
                        todayTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentOrange),
                        selectedDecoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: AppTextStyles.heading4,
                        leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.accentOrange),
                        rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.accentOrange),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                        weekendStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textMuted),
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
