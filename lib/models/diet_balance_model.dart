class DietBalanceModel {
  final String uid;
  final int totalDiets;
  final int remainingDiets;
  final DateTime lastUpdated;

  DietBalanceModel({
    required this.uid,
    required this.totalDiets,
    required this.remainingDiets,
    required this.lastUpdated,
  });
}
