class ExamInfo {
  final String examName;
  final String subject;
  final String examDate;
  final String scope;
  final String importance;

  const ExamInfo({
    required this.examName,
    required this.subject,
    required this.examDate,
    required this.scope,
    required this.importance,
  });

  factory ExamInfo.fromJson(Map<String, dynamic> json) => ExamInfo(
        examName: json['examName'] as String,
        subject: json['subject'] as String,
        examDate: json['examDate'] as String,
        scope: json['scope'] as String,
        importance: json['importance'] as String,
      );

  Map<String, dynamic> toJson() => {
        'examName': examName,
        'subject': subject,
        'examDate': examDate,
        'scope': scope,
        'importance': importance,
      };

  int daysUntil(DateTime from) {
    final exam = DateTime.parse(examDate);
    return exam.difference(DateTime(from.year, from.month, from.day)).inDays;
  }
}
