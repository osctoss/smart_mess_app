class NotificationModel {
  final String notificationId;
  final String messId;
  final String type; // 'APPROVAL_REQUEST', 'DELETE_REQUEST', 'DIET_ALLOCATED', 'ACCOUNT_DELETED'
  final String fromUid;
  final String toUid;
  final String status; // 'PENDING', 'ACCEPTED', 'REJECTED'
  final DateTime createdAt;
  final String? message;

  NotificationModel({
    required this.notificationId,
    required this.messId,
    required this.type,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    this.message,
  });
}
