class UserModel {
  final String uid;
  final String name;
  final String contactNumber;
  final String role; // 'ADMIN' or 'CLIENT'
  final String? messId;
  final bool approved;
  final bool permanentOff;
  final bool morningOff;
  final bool eveningOff;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.contactNumber,
    required this.role,
    this.messId,
    this.approved = false,
    this.permanentOff = false,
    this.morningOff = false,
    this.eveningOff = false,
    required this.createdAt,
  });

  // Add fromJson and toJson methods later
}
