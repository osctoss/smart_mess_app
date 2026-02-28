class MenuModel {
  final String messId;
  final String date; // YYYY-MM-DD
  final String morningMenu;
  final String eveningMenu;
  final String updatedBy; // uid

  MenuModel({
    required this.messId,
    required this.date,
    required this.morningMenu,
    required this.eveningMenu,
    required this.updatedBy,
  });
}
