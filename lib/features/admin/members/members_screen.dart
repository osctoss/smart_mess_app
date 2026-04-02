import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'members_controller.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../shared_widgets/animated_list_item.dart';
import '../../shared_widgets/shimmer_loading.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MembersController(),
      child: DefaultTabController(
        length: 2,
        child: GradientScaffold(
          appBar: AppBar(
            title: const Text('Members'),
            bottom: const TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Approved'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Pending'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Consumer<MembersController>(
            builder: (context, controller, _) {
              if (controller.isLoading) {
                return ShimmerLoading.listPlaceholder();
              }

              return TabBarView(
                children: [
                  // Approved Tab
                  controller.members.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text('No approved members', style: AppTextStyles.subtitle),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.members.length,
                          itemBuilder: (context, index) {
                            final member = controller.members[index];
                            return AnimatedListItem(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassCard(
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.clientDetail, arguments: member),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: AppColors.blueGradient,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(member.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                                            Text(member.contactNumber, style: AppTextStyles.bodySmall),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => controller.removeMember(member.uid),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.accentRose.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.delete_rounded, color: AppColors.accentRose, size: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                  // Pending Tab
                  controller.errorMessage != null
                      ? Center(
                          child: Text(controller.errorMessage!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentRose)),
                        )
                      : controller.pendingMembers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 56, color: AppColors.accentTeal.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  Text('No pending requests', style: AppTextStyles.subtitle),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: controller.pendingMembers.length,
                              itemBuilder: (context, index) {
                                final member = controller.pendingMembers[index];
                                return AnimatedListItem(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: GlassCard(
                                      borderColor: AppColors.accentAmber.withValues(alpha: 0.3),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient: AppColors.amberGradient,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(member.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                                                Text('Waiting for approval', style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentAmber)),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => controller.approveMember(member.uid),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                gradient: AppColors.tealGradient,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text('Approve', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
