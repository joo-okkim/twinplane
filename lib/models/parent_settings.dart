class ParentSettings {
  final String planApprovalMode;
  final int maxDailyStudyMinutes;
  final bool allowPlanAutoAdjustment;
  final bool allowStudentTimeChange;
  final bool allowStudentQuantityChange;
  final bool requireParentApprovalForRequiredPlanDeletion;

  const ParentSettings({
    required this.planApprovalMode,
    required this.maxDailyStudyMinutes,
    required this.allowPlanAutoAdjustment,
    required this.allowStudentTimeChange,
    required this.allowStudentQuantityChange,
    required this.requireParentApprovalForRequiredPlanDeletion,
  });

  factory ParentSettings.fromJson(Map<String, dynamic> json) => ParentSettings(
        planApprovalMode: json['planApprovalMode'] as String,
        maxDailyStudyMinutes: json['maxDailyStudyMinutes'] as int,
        allowPlanAutoAdjustment: json['allowPlanAutoAdjustment'] as bool,
        allowStudentTimeChange: json['allowStudentTimeChange'] as bool,
        allowStudentQuantityChange: json['allowStudentQuantityChange'] as bool,
        requireParentApprovalForRequiredPlanDeletion:
            json['requireParentApprovalForRequiredPlanDeletion'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'planApprovalMode': planApprovalMode,
        'maxDailyStudyMinutes': maxDailyStudyMinutes,
        'allowPlanAutoAdjustment': allowPlanAutoAdjustment,
        'allowStudentTimeChange': allowStudentTimeChange,
        'allowStudentQuantityChange': allowStudentQuantityChange,
        'requireParentApprovalForRequiredPlanDeletion':
            requireParentApprovalForRequiredPlanDeletion,
      };
}
