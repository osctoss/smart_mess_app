import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/notification_model.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';
import '../../shared_widgets/animated_list_item.dart';
import '../../shared_widgets/status_badge.dart';
import '../../shared_widgets/shimmer_loading.dart';

class ClientNotificationsScreen extends StatelessWidget {
  const ClientNotificationsScreen({super.key});

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
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<NotificationModel>>(
        stream: firestoreService.collectionStream(
          path: 'notifications',
          queryBuilder: (query) => query
              .where('toUid', isEqualTo: user.uid)
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
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: AppTextStyles.bodyMedium));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('All caught up!', style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('No notifications yet', style: AppTextStyles.subtitle),
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
                  child: _buildNotificationCard(context, notification, firestoreService, user),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    FirestoreService firestoreService,
    User user,
  ) {
    Color accentColor;
    IconData icon;
    String title;

    switch (notification.type) {
      case 'DIET_ALLOCATED':
        accentColor = AppColors.accentTeal;
        icon = Icons.restaurant_rounded;
        title = 'Diet Allocated';
        break;
      case 'DELETE_REQUEST':
        accentColor = AppColors.accentAmber;
        icon = Icons.warning_amber_rounded;
        title = 'Account Removal Request';
        break;
      case 'ACCOUNT_DELETED':
        accentColor = AppColors.accentRose;
        icon = Icons.info_outline_rounded;
        title = 'Account Removed';
        break;
      default:
        accentColor = AppColors.accentBlue;
        icon = Icons.info_rounded;
        title = notification.type.replaceAll('_', ' ');
    }

    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Row(
        children: [
          // Accent stripe
          Container(
            width: 4,
            height: 80,
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    notification.message ?? 'Status: ${notification.status}',
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(notification.createdAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
          // Action buttons or status
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _buildTrailing(context, notification, firestoreService, user),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailing(
    BuildContext context,
    NotificationModel notification,
    FirestoreService firestoreService,
    User user,
  ) {
    if (notification.type == 'DELETE_REQUEST' && notification.status == 'PENDING') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(
            icon: Icons.close_rounded,
            color: AppColors.accentRose,
            onTap: () async {
              await firestoreService.updateData(
                path: 'notifications/${notification.notificationId}',
                data: {'status': 'REJECTED'},
              );
            },
          ),
          const SizedBox(width: 8),
          _actionButton(
            icon: Icons.check_rounded,
            color: AppColors.accentTeal,
            onTap: () async {
              await firestoreService.updateData(
                path: 'users/${user.uid}',
                data: {'messId': null, 'approved': false},
              );
              try {
                await firestoreService.deleteData(path: 'dietBalances/${user.uid}');
              } catch (_) {}
              await firestoreService.updateData(
                path: 'notifications/${notification.notificationId}',
                data: {'status': 'ACCEPTED'},
              );
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/clientHome', (route) => false);
            },
          ),
        ],
      );
    }

    if (notification.type == 'DELETE_REQUEST') {
      return StatusBadge(
        text: notification.status,
        variant: notification.status == 'ACCEPTED' ? BadgeVariant.success : BadgeVariant.danger,
        icon: notification.status == 'ACCEPTED' ? Icons.check_circle_rounded : Icons.cancel_rounded,
      );
    }

    if (notification.type == 'APPROVAL_REQUEST') {
      return StatusBadge(
        text: notification.status,
        variant: notification.status == 'ACCEPTED'
            ? BadgeVariant.success
            : notification.status == 'REJECTED'
                ? BadgeVariant.danger
                : BadgeVariant.info,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
