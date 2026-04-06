import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'client_dashboard_controller.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../shared_widgets/shimmer_loading.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientDashboardController(),
      child: GradientScaffold(
        appBar: AppBar(
          title: Consumer<ClientDashboardController>(
            builder: (_, controller, child) => Text(controller.mess?.messName ?? 'Dashboard'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.clientNotifications),
            ),
            IconButton(
              icon: const Icon(Icons.person_rounded),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.clientProfile),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Consumer<ClientDashboardController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return ShimmerLoading.listPlaceholder(itemCount: 3, itemHeight: 120);
            }

            if (controller.user?.messId == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_rounded, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('No mess joined', style: AppTextStyles.heading3),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.selectMess),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('Join a Mess', style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (controller.user != null && !controller.user!.approved) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.amberGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentAmber.withValues(alpha: 0.3),
                            blurRadius: 28,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.access_time_rounded, size: 40, color: Colors.white),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 1500.ms,
                      curve: Curves.easeInOut,
                    ),
                    const SizedBox(height: 24),
                    Text('Waiting for Approval', style: AppTextStyles.heading2),
                    const SizedBox(height: 8),
                    Text('Please contact your mess admin.', style: AppTextStyles.subtitle),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.accentOrange,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: () async => controller.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Diet Balance Card with circular ring
                    _buildDietCard(controller).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, duration: 500.ms),

                    const SizedBox(height: 16),

                    // Today's Menu
                    _buildMenuCard(context, controller).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.1, end: 0, delay: 150.ms, duration: 500.ms),

                    const SizedBox(height: 16),

                    // Availability Button
                    GlassCard(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.clientAvailability),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.blueGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Manage Availability', style: AppTextStyles.heading4),
                                const SizedBox(height: 4),
                                Text('Toggle your meal preferences', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 500.ms),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDietCard(ClientDashboardController controller) {
    final remaining = controller.dietBalance?.remainingDiets ?? 0;
    final total = controller.dietBalance?.totalDiets ?? 0;
    final progress = total > 0 ? remaining / total : 0.0;

    // Color based on level
    Color ringColor;
    if (progress > 0.5) {
      ringColor = AppColors.accentTeal;
    } else if (progress > 0.2) {
      ringColor = AppColors.accentAmber;
    } else {
      ringColor = AppColors.accentRose;
    }

    return GlassCard(
      child: Column(
        children: [
          Text('Diet Balance', style: AppTextStyles.heading4),
          const SizedBox(height: 20),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 10,
                    color: AppColors.surfaceLight,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Progress ring
                SizedBox(
                  width: 120,
                  height: 120,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                        color: ringColor,
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$remaining',
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 28,
                        color: ringColor,
                      ),
                    ),
                    Text(
                      'of $total',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Remaining / Total', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, ClientDashboardController controller) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Menu', style: AppTextStyles.heading4),
          const SizedBox(height: 16),

          // Morning
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.amberGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Morning', style: AppTextStyles.label.copyWith(color: AppColors.accentAmber)),
                    const SizedBox(height: 4),
                    Text(
                      (controller.todayMenu?.morningMenu ?? '').isNotEmpty
                          ? controller.todayMenu!.morningMenu
                          : 'Not set',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: (controller.todayMenu?.morningMenu ?? '').isNotEmpty
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.glassBorder, Colors.transparent],
                ),
              ),
            ),
          ),

          // Evening
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.nightlight_round, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Evening', style: AppTextStyles.label.copyWith(color: AppColors.accentOrange)),
                    const SizedBox(height: 4),
                    Text(
                      (controller.todayMenu?.eveningMenu ?? '').isNotEmpty
                          ? controller.todayMenu!.eveningMenu
                          : 'Not set',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: (controller.todayMenu?.eveningMenu ?? '').isNotEmpty
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // View Full Week Button
          GestureDetector(
            onTap: () => _showWeeklyMenuBottomSheet(context, controller),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Center(
                child: Text(
                  'View Full Week\'s Menu',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeeklyMenuBottomSheet(BuildContext context, ClientDashboardController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final Map<String, dynamic> weeklyMenu = controller.weeklyMenu ?? {};
        const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Weekly Menu', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final weekdayStr = (index + 1).toString();
                    final dayData = weeklyMenu[weekdayStr] as Map<String, dynamic>? ?? {};
                    final morning = dayData['morning']?.toString().trim() ?? '';
                    final evening = dayData['evening']?.toString().trim() ?? '';
                    final isToday = DateTime.now().weekday == (index + 1);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: isToday ? Border.all(color: AppColors.accentOrange, width: 1.5) : Border.all(color: AppColors.glassBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                dayNames[index],
                                style: AppTextStyles.heading4.copyWith(
                                  color: isToday ? AppColors.accentOrange : AppColors.textPrimary,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentOrange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Today', style: AppTextStyles.caption.copyWith(color: AppColors.accentOrange)),
                                )
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.wb_sunny_rounded, size: 16, color: AppColors.accentAmber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  morning.isNotEmpty ? morning : 'Not set',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: morning.isNotEmpty ? AppColors.textSecondary : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.nightlight_round, size: 16, color: AppColors.accentBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  evening.isNotEmpty ? evening : 'Not set',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: evening.isNotEmpty ? AppColors.textSecondary : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
