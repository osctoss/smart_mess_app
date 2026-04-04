import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            builder: (context, controller, child) {
              final messName = controller.mess?.messName ?? 'Admin Dashboard';
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      messName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (controller.mess != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: controller.isUpdatingMessName
                          ? null
                          : () => _handleEditMessName(context, controller),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: controller.isUpdatingMessName
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                      ),
                    ),
                  ],
                ],
              );
            },
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
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
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
    return SizedBox(
      height: 132,
      child: GlassCard(
        onTap: () => Navigator.pushNamed(context, item.route),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: item.gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: item.gradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(item.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEditMessName(
    BuildContext context,
    AdminDashboardController controller,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final nextName = await _showEditMessNameDialog(
      context,
      controller.mess?.messName ?? '',
    );

    if (nextName == null) return;

    try {
      await controller.updateMessName(nextName);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Mess name updated successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<String?> _showEditMessNameDialog(
    BuildContext context,
    String initialName,
  ) async {
    final textController = TextEditingController(
      text: initialName,
    );
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            void submit() {
              final nextName = textController.text.trim();

              if (nextName.isEmpty) {
                setDialogState(() => errorText = 'Mess name is required.');
                return;
              }

              Navigator.of(dialogContext).pop(nextName);
            }

            return AlertDialog(
              backgroundColor: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.glassBorder),
              ),
              title: const Text('Edit Mess Name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: 'Mess Name',
                      errorText: errorText,
                      prefixIcon: const Icon(Icons.home_work_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This will update the mess name everywhere it is shown.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submit,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    textController.dispose();
    return result;
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
