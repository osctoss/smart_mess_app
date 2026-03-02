enum UserRole {
  admin,
  client,
}

enum MealType {
  morning,
  evening,
}

enum AvailabilityStatus {
  on,
  off,
}

enum NotificationType {
  approvalRequest,
  deleteRequest,
  dietAllocated,
  accountDeleted,
}

extension NotificationTypeExtension on NotificationType {
  String get toShortString => toString().split('.').last;
}

enum NotificationStatus {
  pending,
  accepted,
  rejected,
}
