import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'client_home_controller.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../shared_widgets/animated_list_item.dart';
import '../../shared_widgets/status_badge.dart';
import '../../shared_widgets/shimmer_loading.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/mess_model.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientHomeController(),
      child: Consumer<ClientHomeController>(
        builder: (context, controller, _) {
          return GradientScaffold(
            appBar: AppBar(
              title: const Text('Home'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.clientNotifications);
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
                ? ShimmerLoading.listPlaceholder(itemCount: 4)
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
                            controller.user?.name ?? 'User',
                            style: AppTextStyles.heading1.copyWith(fontSize: 28),
                          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),

                          const SizedBox(height: 24),

                          // Joined Mess Section
                          _buildJoinedMessSection(context, controller),

                          const SizedBox(height: 28),

                          // Available Messes header
                          Row(
                            children: [
                              Icon(Icons.explore_rounded, color: AppColors.accentAmber, size: 22),
                              const SizedBox(width: 8),
                              Text('Available Messes', style: AppTextStyles.heading3),
                            ],
                          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                          const SizedBox(height: 12),
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

  Widget _buildJoinedMessSection(BuildContext context, ClientHomeController controller) {
    if (controller.user?.messId == null || controller.joinedMess == null) {
      return GlassCard(
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.restaurant_rounded, size: 28, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              'You haven\'t joined any mess yet',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Select one from the list below',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
    }

    final isApproved = controller.user!.approved;

    return GlassCard(
      onTap: isApproved ? () => Navigator.pushNamed(context, AppRoutes.clientDashboard) : null,
      child: Row(
        children: [
          // Accent stripe
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: isApproved ? AppColors.accentTeal : AppColors.accentAmber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isApproved ? AppColors.tealGradient : AppColors.amberGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.joinedMess!.messName, style: AppTextStyles.heading4),
                const SizedBox(height: 6),
                StatusBadge(
                  text: isApproved ? 'Approved' : 'Pending',
                  variant: isApproved ? BadgeVariant.success : BadgeVariant.warning,
                  icon: isApproved ? Icons.check_circle_rounded : Icons.access_time_rounded,
                ),
              ],
            ),
          ),
          Icon(
            isApproved ? Icons.arrow_forward_ios_rounded : Icons.access_time_rounded,
            size: 18,
            color: isApproved ? AppColors.textSecondary : AppColors.accentAmber,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 500.ms);
  }

  Widget _buildMessList(BuildContext context, ClientHomeController controller) {
    return StreamBuilder<List<MessModel>>(
      stream: controller.messesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerLoading.listPlaceholder(itemCount: 3, itemHeight: 80);
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: AppTextStyles.bodyMedium));
        }

        final allMesses = snapshot.data ?? [];
        final messes = allMesses.where((m) => m.messId != controller.user?.messId).toList();

        if (messes.isEmpty) {
          return GlassCard(
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 32, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text('No other messes available', style: AppTextStyles.subtitle),
                ],
              ),
            ),
          );
        }

        final hasJoinedMess = controller.user?.messId != null;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: messes.length,
          itemBuilder: (context, index) {
            final mess = messes[index];
            return AnimatedListItem(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(mess.messName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (hasJoinedMess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You can only join one mess at a time.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            controller.joinMess(context, mess);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: hasJoinedMess ? null : AppColors.tealGradient,
                            color: hasJoinedMess ? AppColors.surfaceLight.withValues(alpha: 0.5) : null,
                            borderRadius: BorderRadius.circular(12),
                            border: hasJoinedMess ? Border.all(color: AppColors.surfaceLight) : null,
                          ),
                          child: Text(
                            hasJoinedMess ? 'Locked' : 'Join',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: hasJoinedMess ? AppColors.textMuted : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
