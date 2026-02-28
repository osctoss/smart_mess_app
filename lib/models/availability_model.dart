class AvailabilityModel {
  final String uid;
  final String messId;
  final String date; // YYYY-MM-DD
  final String meal; // 'MORNING' or 'EVENING'
  final String status; // 'ON' or 'OFF'
  final bool locked;

  AvailabilityModel({
    required this.uid,
    required this.messId,
    required this.date,
    required this.meal,
    required this.status,
    this.locked = false,
  });
}
