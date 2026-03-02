import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/notification_model.dart';
import 'package:intl/intl.dart';

class ClientNotificationsScreen extends StatelessWidget {
  const ClientNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification, firestoreService, user);
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
    switch (notification.type) {
      case 'DIET_ALLOCATED':
        return Card(
          child: ListTile(
            leading: const Icon(Icons.restaurant, color: Colors.green, size: 32),
            title: const Text('Diet Allocated'),
            subtitle: Text(
              '${notification.message ?? 'Diets added'}\n${DateFormat('MMM d, h:mm a').format(notification.createdAt)}',
            ),
          ),
        );

      case 'DELETE_REQUEST':
        return Card(
          child: ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            title: const Text('Account Removal Request'),
            subtitle: Text(
              'Admin has requested to remove your account.\n'
              'Status: ${notification.status}\n'
              '${DateFormat('MMM d, h:mm a').format(notification.createdAt)}',
            ),
            trailing: notification.status == 'PENDING'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        child: const Text('Reject', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          await firestoreService.updateData(
                            path: 'notifications/${notification.notificationId}',
                            data: {'status': 'REJECTED'},
                          );
                        },
                      ),
                      TextButton(
                        child: const Text('Accept', style: TextStyle(color: Colors.green)),
                        onPressed: () async {
                          // Soft-delete: clear mess association
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
                  )
                : Icon(
                    notification.status == 'ACCEPTED' ? Icons.check_circle : Icons.cancel,
                    color: notification.status == 'ACCEPTED' ? Colors.green : Colors.red,
                  ),
          ),
        );

      case 'ACCOUNT_DELETED':
        return Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.red, size: 32),
            title: const Text('Account Removed'),
            subtitle: Text(
              '${notification.message ?? 'Your account has been removed'}\n${DateFormat('MMM d, h:mm a').format(notification.createdAt)}',
            ),
          ),
        );

      case 'APPROVAL_REQUEST':
      default:
        return Card(
          child: ListTile(
            leading: Icon(
              notification.status == 'ACCEPTED' ? Icons.check_circle :
              notification.status == 'REJECTED' ? Icons.cancel : Icons.info,
              color: notification.status == 'ACCEPTED' ? Colors.green :
                     notification.status == 'REJECTED' ? Colors.red : Colors.blue,
              size: 32,
            ),
            title: Text(notification.type.replaceAll('_', ' ')),
            subtitle: Text(
              'Status: ${notification.status}\n${DateFormat('MMM d, h:mm a').format(notification.createdAt)}',
            ),
          ),
        );
    }
  }
}
