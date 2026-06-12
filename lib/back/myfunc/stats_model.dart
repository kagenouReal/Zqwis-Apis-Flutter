class StatsModel {
final int total;
final int success;
final int failed;
final String? lastCrash;
final String? broadcast;
//===============
const StatsModel({
required this.total,
required this.success,
required this.failed,
this.lastCrash,
this.broadcast,
});
//===============
factory StatsModel.fromJson(Map<String, dynamic> json) {
return StatsModel(
total: json['total'] ?? 0,
success: json['success'] ?? 0,
failed: json['failed'] ?? 0,
lastCrash: json['lastCrash'],
broadcast: json['broadcast'],
);
}
//===============
double get successRate => total == 0 ? 0 : (success / total) * 100;
}
