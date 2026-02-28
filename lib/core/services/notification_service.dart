import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendNotification({
    required String messId,
    required NotificationType type,
    required String fromUid,
    required String toUid,
  }) async {
    await _db.collection('notifications').add({
      'messId': messId,
      'type': type.name, // Convert enum to string
      'fromUid': fromUid,
      'toUid': toUid,
      'status': NotificationStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Add methods to fetch notifications, accept/reject, etc.
}
