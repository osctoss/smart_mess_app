import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'availability_controller.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AvailabilityController(),
      child: GradientScaffold(
        appBar: AppBar(title: const Text('Availability')),
        body: Consumer<AvailabilityController>(
          builder: (context, controller, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                children: [
                  // Calendar in glass card
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: TableCalendar(
                      firstDay: DateTime.now().subtract(const Duration(days: 30)),
                      lastDay: DateTime.now().add(const Duration(days: 30)),
                      focusedDay: controller.selectedDate,
                      selectedDayPredicate: (day) => isSameDay(controller.selectedDate, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        controller.onDateSelected(selectedDay);
                      },
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: AppTextStyles.bodyMedium,
                        weekendTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        outsideTextStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        todayDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentOrange, width: 1.5),
                        ),
                        todayTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentOrange),
                        selectedDecoration: BoxDecoration(
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

                  // Permanent OFF toggle
                  GlassCard(
                    borderColor: controller.isPermanentOff ? AppColors.accentRose.withValues(alpha: 0.4) : null,
                    backgroundColor: controller.isPermanentOff ? AppColors.accentRose.withValues(alpha: 0.08) : null,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accentRose.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.block_rounded, color: AppColors.accentRose, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Permanent OFF', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Turn off all meals indefinitely', style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                        Switch(
                          value: controller.isPermanentOff,
                          onChanged: (val) => controller.togglePermanentOff(val),
                          activeThumbColor: AppColors.accentRose,
                          activeTrackColor: AppColors.accentRose.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

                  const SizedBox(height: 12),

                  // Morning toggle
                  _buildMealToggle(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Morning Meal',
                    gradient: AppColors.amberGradient,
                    accentColor: AppColors.accentAmber,
                    isOn: controller.isMorningOn,
                    isLocked: controller.isLockedMorning,
                    onChanged: (val) => controller.toggleMorning(val),
                    index: 1,
                  ),

                  const SizedBox(height: 12),

                  // Evening toggle
                  _buildMealToggle(
                    icon: Icons.nightlight_round,
                    label: 'Evening Meal',
                    gradient: AppColors.primaryGradient,
                    accentColor: AppColors.accentOrange,
                    isOn: controller.isEveningOn,
                    isLocked: controller.isLockedEvening,
                    onChanged: (val) => controller.toggleEvening(val),
                    index: 2,
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Consumer<AvailabilityController>(
          builder: (context, controller, _) {
            return SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: controller.hasUnsavedChanges || controller.isSaving ? 1 : 0.75,
                child: IgnorePointer(
                  ignoring: !controller.hasUnsavedChanges && !controller.isSaving,
                  child: CustomButton(
                    text: controller.hasUnsavedChanges ? 'Save Changes' : 'No Changes Yet',
                    icon: Icons.save_rounded,
                    isLoading: controller.isSaving,
                    onPressed: () async {
                      final saved = await controller.saveChanges();
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            saved
                                ? 'Availability changes saved'
                                : 'Could not save changes. Please try again.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMealToggle({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required Color accentColor,
    required bool isOn,
    required bool isLocked,
    required ValueChanged<bool> onChanged,
    required int index,
  }) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                if (isLocked) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 14, color: AppColors.accentRose),
                      const SizedBox(width: 4),
                      Text('Locked', style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentRose)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: isOn,
            onChanged: isLocked ? null : onChanged,
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 150 + index * 100), duration: 500.ms);
  }
}
