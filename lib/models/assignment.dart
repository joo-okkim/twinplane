class Assignment {
  final int assignmentId;
  final String subject;
  final String title;
  final String dueDate;
  final int estimatedMinutes;
  final String priority;
  final bool required;
  final bool evidenceRequired;

  const Assignment({
    required this.assignmentId,
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.estimatedMinutes,
    required this.priority,
    required this.required,
    required this.evidenceRequired,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        assignmentId: json['assignmentId'] as int,
        subject: json['subject'] as String,
        title: json['title'] as String,
        dueDate: json['dueDate'] as String,
        estimatedMinutes: json['estimatedMinutes'] as int,
        priority: json['priority'] as String,
        required: json['required'] as bool,
        evidenceRequired: json['evidenceRequired'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'assignmentId': assignmentId,
        'subject': subject,
        'title': title,
        'dueDate': dueDate,
        'estimatedMinutes': estimatedMinutes,
        'priority': priority,
        'required': required,
        'evidenceRequired': evidenceRequired,
      };
}
