import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/notification_model.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../shared_widgets/animated_list_item.dart';
import '../../shared_widgets/shimmer_loading.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return GradientScaffold(
        body: Center(child: Text('Not logged in', style: AppTextStyles.bodyMedium)),
      );
    }

    final FirestoreService firestoreService = FirestoreService();

    return GradientScaffold(
      appBar: AppBar(title: const Text('Admin Notifications')),
      body: StreamBuilder<List<NotificationModel>>(
        stream: firestoreService.collectionStream(
          path: 'notifications',
          queryBuilder: (query) => query
              .where('toUid', isEqualTo: user.uid)
              .where('status', isEqualTo: 'PENDING')
              .orderBy('createdAt', descending: true),
          builder: (data, id) => NotificationModel(
            notificationId: id,
            messId: data['messId'] ?? '',
            type: data['type'] ?? '',
            fromUid: data['fromUid'] ?? '',
            toUid: data['toUid'] ?? '',
            status: data['status'] ?? '',
            createdAt: data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            message: data['message'],
          ),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ShimmerLoading.listPlaceholder();
          }
          final allNotifications = snapshot.data ?? [];
          // Filter out join requests — those are handled in Members → Pending
          final notifications = allNotifications
              .where((n) => n.type != 'APPROVAL_REQUEST')
              .toList();

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.accentTeal.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('All caught up!', style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('No pending notifications', style: AppTextStyles.subtitle),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return AnimatedListItem(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: Key(notification.notificationId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                    ),
                    onDismissed: (direction) async {
                      await firestoreService.deleteData(path: 'notifications/${notification.notificationId}');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification deleted')),
                      );
                    },
                    child: _buildNotificationCard(context, notification, firestoreService),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification, FirestoreService firestoreService) {
    Color accentColor;
    IconData icon;
    String title;
    bool isRequest = notification.type == 'APPROVAL_REQUEST' || notification.type == 'DELETE_REQUEST';

    switch (notification.type) {
      case 'DIET_ALLOCATED':
        accentColor = AppColors.accentTeal;
        icon = Icons.restaurant_rounded;
        title = 'Diet Allocated';
        break;
      case 'DIET_DEDUCTED':
        accentColor = AppColors.accentOrange;
        icon = Icons.remove_circle_outline_rounded;
        title = 'Diet Deducted';
        break;
      case 'APPROVAL_REQUEST':
        accentColor = AppColors.accentAmber;
        icon = Icons.person_add_alt_1_rounded;
        title = 'Approval Request';
        break;
      case 'DELETE_REQUEST':
        accentColor = AppColors.accentRose;
        icon = Icons.warning_amber_rounded;
        title = 'Delete Request';
        break;
      default:
        accentColor = AppColors.accentBlue;
        icon = Icons.info_outline_rounded;
        title = notification.type.replaceAll('_', ' ');
    }

    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Row(
        children: [
          // Accent stripe
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message ?? (isRequest ? 'Request pending' : 'Informational notification'),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  if (notification.type == 'APPROVAL_REQUEST') {
                    await firestoreService.approveMemberAndAssignRollNumber(
                      notification.messId, 
                      notification.fromUid,
                    );
                  }
                  await firestoreService.updateData(
                    path: 'notifications/${notification.notificationId}',
                    data: {'status': 'ACCEPTED'},
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.check_rounded, color: AppColors.accentTeal, size: 18),
                ),
              ),
              if (isRequest) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await firestoreService.updateData(
                      path: 'notifications/${notification.notificationId}',
                      data: {'status': 'REJECTED'},
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accentRose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.close_rounded, color: AppColors.accentRose, size: 18),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}
