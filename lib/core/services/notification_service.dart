import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendNotification({
    required String messId,
    required NotificationType type,
    required String fromUid,
    required String toUid,
    String? message,
  }) async {
    final typeStr = switch (type) {
      NotificationType.approvalRequest => 'APPROVAL_REQUEST',
      NotificationType.deleteRequest => 'DELETE_REQUEST',
      NotificationType.dietAllocated => 'DIET_ALLOCATED',
      NotificationType.accountDeleted => 'ACCOUNT_DELETED',
    };

    final data = <String, dynamic>{
      'messId': messId,
      'type': typeStr,
      'fromUid': fromUid,
      'toUid': toUid,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (message != null) {
      data['message'] = message;
    }

    await _db.collection('notifications').add(data);
  }
}
