import 'plan_item.dart';
import 'plan_summary.dart';
import 'reward_forecast.dart';

class StudentMessage {
  final String title;
  final String message;
  final String tone;

  const StudentMessage({required this.title, required this.message, required this.tone});

  factory StudentMessage.fromJson(Map<String, dynamic> json) => StudentMessage(
        title: json['title'] as String,
        message: json['message'] as String,
        tone: json['tone'] as String,
      );

  Map<String, dynamic> toJson() => {'title': title, 'message': message, 'tone': tone};
}

class ParentMessage {
  final String summary;
  final List<String> attentionItems;
  final bool approvalRequired;

  const ParentMessage({
    required this.summary,
    required this.attentionItems,
    required this.approvalRequired,
  });

  factory ParentMessage.fromJson(Map<String, dynamic> json) => ParentMessage(
        summary: json['summary'] as String,
        attentionItems: (json['attentionItems'] as List).map((e) => e as String).toList(),
        approvalRequired: json['approvalRequired'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'attentionItems': attentionItems,
        'approvalRequired': approvalRequired,
      };
}

class CarryOverDecision {
  final String sourcePlanItemId;
  final String decision;
  final String originalQuantity;
  final String adjustedQuantity;
  final String reason;

  const CarryOverDecision({
    required this.sourcePlanItemId,
    required this.decision,
    required this.originalQuantity,
    required this.adjustedQuantity,
    required this.reason,
  });

  factory CarryOverDecision.fromJson(Map<String, dynamic> json) => CarryOverDecision(
        sourcePlanItemId: json['sourcePlanItemId'].toString(),
        decision: json['decision'] as String,
        originalQuantity: json['originalQuantity'] as String,
        adjustedQuantity: json['adjustedQuantity'] as String,
        reason: json['reason'] as String,
      );

  Map<String, dynamic> toJson() => {
        'sourcePlanItemId': sourcePlanItemId,
        'decision': decision,
        'originalQuantity': originalQuantity,
        'adjustedQuantity': adjustedQuantity,
        'reason': reason,
      };
}

class PlanValidation {
  final bool fixedScheduleConflict;
  final bool exceedsMaximumStudyTime;
  final bool bedTimeConflict;
  final bool insufficientBreakTime;
  final bool excessiveHardTasks;
  final bool excessiveCarryOver;
  final bool valid;

  const PlanValidation({
    required this.fixedScheduleConflict,
    required this.exceedsMaximumStudyTime,
    required this.bedTimeConflict,
    required this.insufficientBreakTime,
    required this.excessiveHardTasks,
    required this.excessiveCarryOver,
    required this.valid,
  });

  factory PlanValidation.fromJson(Map<String, dynamic> json) => PlanValidation(
        fixedScheduleConflict: json['fixedScheduleConflict'] as bool,
        exceedsMaximumStudyTime: json['exceedsMaximumStudyTime'] as bool,
        bedTimeConflict: json['bedTimeConflict'] as bool,
        insufficientBreakTime: json['insufficientBreakTime'] as bool,
        excessiveHardTasks: json['excessiveHardTasks'] as bool,
        excessiveCarryOver: json['excessiveCarryOver'] as bool,
        valid: json['valid'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'fixedScheduleConflict': fixedScheduleConflict,
        'exceedsMaximumStudyTime': exceedsMaximumStudyTime,
        'bedTimeConflict': bedTimeConflict,
        'insufficientBreakTime': insufficientBreakTime,
        'excessiveHardTasks': excessiveHardTasks,
        'excessiveCarryOver': excessiveCarryOver,
        'valid': valid,
      };
}

class DailyPlanResponse {
  final String result;
  final String targetDate;
  final int studentId;
  final PlanSummary planSummary;
  final List<PlanItem> dailyPlans;
  final List<String> generationReasons;
  final StudentMessage studentMessage;
  final ParentMessage parentMessage;
  final RewardForecast rewardForecast;
  final List<CarryOverDecision> carryOverDecisions;
  final List<String> warnings;
  final PlanValidation validation;

  const DailyPlanResponse({
    required this.result,
    required this.targetDate,
    required this.studentId,
    required this.planSummary,
    required this.dailyPlans,
    required this.generationReasons,
    required this.studentMessage,
    required this.parentMessage,
    required this.rewardForecast,
    required this.carryOverDecisions,
    required this.warnings,
    required this.validation,
  });

  factory DailyPlanResponse.fromJson(Map<String, dynamic> json) => DailyPlanResponse(
        result: json['result'] as String,
        targetDate: json['targetDate'] as String,
        studentId: json['studentId'] as int,
        planSummary: PlanSummary.fromJson(json['planSummary'] as Map<String, dynamic>),
        dailyPlans: (json['dailyPlans'] as List)
            .map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        generationReasons:
            (json['generationReasons'] as List).map((e) => e as String).toList(),
        studentMessage:
            StudentMessage.fromJson(json['studentMessage'] as Map<String, dynamic>),
        parentMessage: ParentMessage.fromJson(json['parentMessage'] as Map<String, dynamic>),
        rewardForecast:
            RewardForecast.fromJson(json['rewardForecast'] as Map<String, dynamic>),
        carryOverDecisions: (json['carryOverDecisions'] as List)
            .map((e) => CarryOverDecision.fromJson(e as Map<String, dynamic>))
            .toList(),
        warnings: (json['warnings'] as List).map((e) => e as String).toList(),
        validation: PlanValidation.fromJson(json['validation'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'result': result,
        'targetDate': targetDate,
        'studentId': studentId,
        'planSummary': planSummary.toJson(),
        'dailyPlans': dailyPlans.map((p) => p.toJson()).toList(),
        'generationReasons': generationReasons,
        'studentMessage': studentMessage.toJson(),
        'parentMessage': parentMessage.toJson(),
        'rewardForecast': rewardForecast.toJson(),
        'carryOverDecisions': carryOverDecisions.map((c) => c.toJson()).toList(),
        'warnings': warnings,
        'validation': validation.toJson(),
      };

  DailyPlanResponse copyWithPlans(List<PlanItem> newPlans) => DailyPlanResponse(
        result: result,
        targetDate: targetDate,
        studentId: studentId,
        planSummary: planSummary,
        dailyPlans: newPlans,
        generationReasons: generationReasons,
        studentMessage: studentMessage,
        parentMessage: parentMessage,
        rewardForecast: rewardForecast,
        carryOverDecisions: carryOverDecisions,
        warnings: warnings,
        validation: validation,
      );
}
