enum StudentCondition {
  veryGood('very_good'),
  good('good'),
  normal('normal'),
  tired('tired'),
  veryTired('very_tired'),
  stressed('stressed'),
  sick('sick');

  final String wireValue;
  const StudentCondition(this.wireValue);

  static StudentCondition fromWire(String value) => StudentCondition.values
      .firstWhere((c) => c.wireValue == value, orElse: () => StudentCondition.normal);
}

class StudentProfile {
  final int studentId;
  final String name;
  final String gradeLevel;
  final String wakeUpTime;
  final String bedTime;
  final String preferredStudyStartTime;
  final int maxSelfStudyMinutes;
  final int maxConcentrationMinutes;
  final StudentCondition condition;
  final String? conditionMemo;

  const StudentProfile({
    required this.studentId,
    required this.name,
    required this.gradeLevel,
    required this.wakeUpTime,
    required this.bedTime,
    required this.preferredStudyStartTime,
    required this.maxSelfStudyMinutes,
    required this.maxConcentrationMinutes,
    required this.condition,
    this.conditionMemo,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        studentId: json['studentId'] as int,
        name: json['name'] as String,
        gradeLevel: json['gradeLevel'] as String,
        wakeUpTime: json['wakeUpTime'] as String,
        bedTime: json['bedTime'] as String,
        preferredStudyStartTime: json['preferredStudyStartTime'] as String,
        maxSelfStudyMinutes: json['maxSelfStudyMinutes'] as int,
        maxConcentrationMinutes: json['maxConcentrationMinutes'] as int,
        condition: StudentCondition.fromWire(json['condition'] as String),
        conditionMemo: json['conditionMemo'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'name': name,
        'gradeLevel': gradeLevel,
        'wakeUpTime': wakeUpTime,
        'bedTime': bedTime,
        'preferredStudyStartTime': preferredStudyStartTime,
        'maxSelfStudyMinutes': maxSelfStudyMinutes,
        'maxConcentrationMinutes': maxConcentrationMinutes,
        'condition': condition.wireValue,
        'conditionMemo': conditionMemo,
      };
}

class SubjectLevel {
  final String subject;
  final String level;
  final double recentAchievementRate;
  final int averageDelayMinutes;
  final int averageActualMinutes;
  final int recentIncompleteCount;

  const SubjectLevel({
    required this.subject,
    required this.level,
    required this.recentAchievementRate,
    required this.averageDelayMinutes,
    required this.averageActualMinutes,
    required this.recentIncompleteCount,
  });

  factory SubjectLevel.fromJson(Map<String, dynamic> json) => SubjectLevel(
        subject: json['subject'] as String,
        level: json['level'] as String,
        recentAchievementRate: (json['recentAchievementRate'] as num).toDouble(),
        averageDelayMinutes: json['averageDelayMinutes'] as int,
        averageActualMinutes: json['averageActualMinutes'] as int,
        recentIncompleteCount: json['recentIncompleteCount'] as int,
      );

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'level': level,
        'recentAchievementRate': recentAchievementRate,
        'averageDelayMinutes': averageDelayMinutes,
        'averageActualMinutes': averageActualMinutes,
        'recentIncompleteCount': recentIncompleteCount,
      };
}
