class StateEntity {
  String? param;
  String? atomsScenario;
  DateTime? date;
  bool isGridEnabled;
  bool dateRangeEnabled;

  StateEntity({
    this.param = 't',
    this.atomsScenario,
    this.date,
    this.isGridEnabled = false,
    this.dateRangeEnabled = false,
  });
}
