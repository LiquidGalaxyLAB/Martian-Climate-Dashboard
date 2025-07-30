// class StateEntity {
//   String? param;
//   String? atomsScenario;
//   DateTime? date;
//   bool isGridEnabled;
//   bool dateRangeEnabled;

//   StateEntity({
//     this.param = 't',
//     this.atomsScenario,
//     this.date,
//     this.isGridEnabled = false,
//     this.dateRangeEnabled = false,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'param': param,
//       'atomsScenario': atomsScenario,
//       'date': date?.toIso8601String(),
//       'isGridEnabled': isGridEnabled,
//       'dateRangeEnabled': dateRangeEnabled,
//     };
//   }

//   factory StateEntity.fromJson(Map<String, dynamic> json) {
//     return StateEntity(
//       param: json['param'],
//       atomsScenario: json['atomsScenario'],
//       date: DateTime.tryParse(json['date']),
//       isGridEnabled: json['isGridEnabled'] ?? false,
//       dateRangeEnabled: json['dateRangeEnabled'] ?? false,
//     );
//   }
// }
