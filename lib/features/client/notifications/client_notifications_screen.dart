import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../models/notification_model.dart';
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
            createdAt: (data['createdAt'] as Timestamp).toDate(),
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
              return Card(
                child: ListTile(
                  title: Text(notification.type.replaceAll('_', ' ')),
                  subtitle: Text('Status: ${notification.status} \n${DateFormat('MMM d, h:mm a').format(notification.createdAt)}'),
                  trailing: notification.type == 'DELETE_REQUEST' && notification.status == 'PENDING'
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
                                // Delete Account Logic
                                await firestoreService.deleteData(path: 'users/${user.uid}');
                                await firestoreService.deleteData(path: 'dietBalances/${user.uid}');
                                await firestoreService.deleteData(path: 'notifications/${notification.notificationId}');
                                await FirebaseAuth.instance.signOut();
                                if (!context.mounted) return;
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              },
                            ),
                          ],
                        )
                      : Icon(
                          notification.status == 'ACCEPTED' ? Icons.check_circle : 
                          notification.status == 'REJECTED' ? Icons.cancel : Icons.info,
                          color: notification.status == 'ACCEPTED' ? Colors.green : 
                                 notification.status == 'REJECTED' ? Colors.red : Colors.blue,
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
