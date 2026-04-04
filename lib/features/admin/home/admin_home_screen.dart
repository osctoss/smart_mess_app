import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'admin_home_controller.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../shared_widgets/animated_list_item.dart';
import '../../shared_widgets/shimmer_loading.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/mess_model.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminHomeController(),
      child: Consumer<AdminHomeController>(
        builder: (context, controller, _) {
          return GradientScaffold(
            appBar: AppBar(
              title: const Text('Admin Home'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.adminNotifications);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person_rounded),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.clientProfile);
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: controller.isLoading
                ? ShimmerLoading.listPlaceholder(itemCount: 3)
                : RefreshIndicator(
                    color: AppColors.accentOrange,
                    backgroundColor: AppColors.surfaceDark,
                    onRefresh: () async => controller.refresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Greeting
                          Text(
                            'Welcome back,',
                            style: AppTextStyles.subtitle,
                          ).animate().fadeIn(duration: 400.ms),
                          const SizedBox(height: 4),
                          Text(
                            controller.user?.name ?? 'Admin',
                            style: AppTextStyles.heading1.copyWith(fontSize: 28),
                          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),

                          const SizedBox(height: 32),

                          // Header
                          Row(
                            children: [
                              Icon(Icons.dashboard_customize_rounded, color: AppColors.accentBlue, size: 22),
                              const SizedBox(width: 8),
                              Text('Your Messes', style: AppTextStyles.heading3),
                            ],
                          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                          const SizedBox(height: 16),

                          _buildMessList(context, controller),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildMessList(BuildContext context, AdminHomeController controller) {
    return StreamBuilder<List<MessModel>>(
      stream: controller.messesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerLoading.listPlaceholder(itemCount: 2, itemHeight: 80);
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: AppTextStyles.bodyMedium));
        }

        final messes = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (messes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.maps_home_work_rounded, size: 28, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'You haven\'t created any mess yet',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create one to get started',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: messes.length,
                itemBuilder: (context, index) {
                  final mess = messes[index];
                  return AnimatedListItem(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        onTap: () => controller.selectMess(context, mess),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Accent Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            // Mess Name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mess.messName, 
                                    style: AppTextStyles.heading4,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Administered by you',
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentTeal),
                                  ),
                                ],
                              ),
                            ),
                            // Arrow
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Create Another Mess Button (if < 3)
            if (messes.length < 3)
              AnimatedListItem(
                index: messes.length,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GlassCard(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.createMess),
                    borderColor: AppColors.accentTeal.withValues(alpha: 0.3),
                    backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.3),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, color: AppColors.accentTeal, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          messes.isEmpty ? 'Create New Mess' : 'Create Another Mess',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.accentTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
