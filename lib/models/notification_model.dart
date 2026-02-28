class NotificationModel {
  final String notificationId;
  final String messId;
  final String type; // 'APPROVAL_REQUEST' or 'DELETE_REQUEST'
  final String fromUid;
  final String toUid;
  final String status; // 'PENDING', 'ACCEPTED', 'REJECTED'
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.messId,
    required this.type,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });
}
