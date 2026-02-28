class AttendanceModel {
  final String messId;
  final String date;
  final String meal;
  final DateTime createdAt;

  AttendanceModel({
    required this.messId,
    required this.date,
    required this.meal,
    required this.createdAt,
  });
}

class AttendanceRecord {
  final String uid;
  final bool present;

  AttendanceRecord({
    required this.uid,
    required this.present,
  });
}
