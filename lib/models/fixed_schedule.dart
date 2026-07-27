class FixedSchedule {
  final String title;
  final String startTime;
  final String endTime;
  final String type;

  const FixedSchedule({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
  });

  factory FixedSchedule.fromJson(Map<String, dynamic> json) => FixedSchedule(
        title: json['title'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        type: json['type'] as String,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
        'type': type,
      };
}
