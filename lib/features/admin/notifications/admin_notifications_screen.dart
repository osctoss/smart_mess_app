import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/notification_model.dart';


class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final FirestoreService firestoreService = FirestoreService();

    // Need to fetch Admin's Mess ID first to filter notifications for their mess
    // Or queried by 'toUid' if notifications are sent to Admin UID.
    // In SelectMessController, we sent to `mess.createdBy` (Admin UID). 
    // So querying by `toUid` is correct.

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Notifications')),
      body: StreamBuilder<List<NotificationModel>>(
        stream: firestoreService.collectionStream(
          path: 'notifications',
          queryBuilder: (query) => query
              .where('toUid', isEqualTo: user.uid)
              .where('status', isEqualTo: 'PENDING') // Show only pending
              .orderBy('createdAt', descending: true),
          builder: (data, id) => NotificationModel(
            notificationId: id,
            messId: data['messId'] ?? '',
            type: data['type'] ?? '',
            fromUid: data['fromUid'] ?? '',
            toUid: data['toUid'] ?? '',
            status: data['status'] ?? '',
            createdAt: (data['createdAt'] as Timestamp).toDate(),
          ),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
             return const Center(child: Text('No pending notifications'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                child: ListTile(
                  title: Text(notification.type.replaceAll('_', ' ')),
                  subtitle: Text('From: ${notification.fromUid}'), // Fetch name ideally
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                           // Approve Logic
                           if (notification.type == 'APPROVAL_REQUEST') {
                             await firestoreService.updateData(
                               path: 'users/${notification.fromUid}',
                               data: {'approved': true, 'role': 'CLIENT', 'messId': notification.messId}, 
                             );
                           }
                           // Update Notification Status
                           await firestoreService.updateData(
                             path: 'notifications/${notification.notificationId}',
                             data: {'status': 'ACCEPTED'},
                           );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                           // Reject Logic
                           await firestoreService.updateData(
                             path: 'notifications/${notification.notificationId}',
                             data: {'status': 'REJECTED'},
                           );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
