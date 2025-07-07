class HomeStateEntity {
  String param;
  String? atomsScenario;
  DateTime date;
  bool isGridEnabled;
  bool dateRangeEnabled;

  HomeStateEntity({
    required this.param,
    this.atomsScenario,
    required this.date,
    this.isGridEnabled = false,
    this.dateRangeEnabled = false,
  });
}
