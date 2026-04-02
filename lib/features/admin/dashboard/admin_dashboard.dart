import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'admin_dashboard_controller.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../shared_widgets/animated_list_item.dart';
import '../../shared_widgets/shimmer_loading.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminDashboardController(),
      child: GradientScaffold(
        appBar: AppBar(
          title: Consumer<AdminDashboardController>(
            builder: (_, controller, child) => Text(controller.mess?.messName ?? 'Admin Dashboard'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.adminNotifications),
            ),
            IconButton(
              icon: const Icon(Icons.person_rounded),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.clientProfile),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Consumer<AdminDashboardController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return ShimmerLoading.listPlaceholder(itemCount: 4, itemHeight: 150);
            }

            if (controller.mess == null) {
              return Center(
                child: Text('Error loading mess details', style: AppTextStyles.bodyMedium),
              );
            }

            final items = [
              _DashboardItem(
                title: 'Set Menu',
                icon: Icons.restaurant_menu_rounded,
                gradient: AppColors.primaryGradient,
                route: AppRoutes.menuManagement,
                subtitle: 'Manage meals',
              ),
              _DashboardItem(
                title: 'Members',
                icon: Icons.people_rounded,
                gradient: AppColors.blueGradient,
                route: AppRoutes.membersList,
                subtitle: '${controller.totalMembers} members',
              ),
              _DashboardItem(
                title: 'Availability',
                icon: Icons.list_alt_rounded,
                gradient: AppColors.tealGradient,
                route: AppRoutes.availabilityList,
                subtitle: 'View status',
              ),
              _DashboardItem(
                title: 'Attendance',
                icon: Icons.check_circle_outline_rounded,
                gradient: AppColors.amberGradient,
                route: AppRoutes.attendance,
                subtitle: 'Track records',
              ),
            ];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return AnimatedListItem(
                    index: index,
                    child: _buildDashboardCard(context, item),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, _DashboardItem item) {
    return GlassCard(
      onTap: () => Navigator.pushNamed(context, item.route),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: item.gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: item.gradient.colors.first.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final String route;
  final String subtitle;

  const _DashboardItem({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.route,
    required this.subtitle,
  });
}
