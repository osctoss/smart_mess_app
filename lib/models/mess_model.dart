class MessModel {
  final String messId;
  final String messName;
  final String createdBy; // uid of admin
  final DateTime createdAt;

  MessModel({
    required this.messId,
    required this.messName,
    required this.createdBy,
    required this.createdAt,
  });
}
