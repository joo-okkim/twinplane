enum PlanType {
  required('required'),
  recommended('recommended'),
  optional('optional'),
  bonus('bonus'),
  routine('routine'),
  breakTime('break'),
  fixed('fixed');

  final String wireValue;
  const PlanType(this.wireValue);

  static PlanType fromWire(String value) =>
      PlanType.values.firstWhere((t) => t.wireValue == value, orElse: () => PlanType.recommended);
}

enum Difficulty {
  easy('easy'),
  normal('normal'),
  hard('hard');

  final String wireValue;
  const Difficulty(this.wireValue);

  static Difficulty fromWire(String value) =>
      Difficulty.values.firstWhere((d) => d.wireValue == value, orElse: () => Difficulty.normal);
}

enum SourceType {
  assignment('ASSIGNMENT'),
  incompletePlan('INCOMPLETE_PLAN'),
  fixedSchedule('FIXED_SCHEDULE'),
  aiGenerated('AI_GENERATED');

  final String wireValue;
  const SourceType(this.wireValue);

  static SourceType fromWire(String value) => SourceType.values
      .firstWhere((t) => t.wireValue == value, orElse: () => SourceType.aiGenerated);
}

/// A single item in a day's plan. Mirrors the `dailyPlans[]` entries from the
/// AI Teacher spec's CREATE_DAILY_PLAN response contract.
///
/// Completion state (done / actual minutes) is intentionally NOT stored here
/// -- it is session/UI state tracked separately by DailyReviewProvider, so
/// this model stays a faithful, re-parseable mirror of the plan-creation
/// response even after the student marks items complete.
class PlanItem {
  final String id;
  final int sequence;
  final PlanType planType;
  final String? subject;
  final String title;
  final String description;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final String priority;
  final Difficulty difficulty;
  final bool required;
  final bool rewardEligible;
  final int estimatedStickerReward;
  final int confirmedStickerReward;
  final bool evidenceRequired;
  final SourceType sourceType;
  final String? sourceId;
  final bool adjustable;
  final String? adjustmentReason;

  const PlanItem({
    required this.id,
    required this.sequence,
    required this.planType,
    this.subject,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.priority,
    required this.difficulty,
    required this.required,
    required this.rewardEligible,
    required this.estimatedStickerReward,
    this.confirmedStickerReward = 0,
    required this.evidenceRequired,
    required this.sourceType,
    this.sourceId,
    required this.adjustable,
    this.adjustmentReason,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
        id: json['id'] as String,
        sequence: json['sequence'] as int,
        planType: PlanType.fromWire(json['planType'] as String),
        subject: json['subject'] as String?,
        title: json['title'] as String,
        description: json['description'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        durationMinutes: json['durationMinutes'] as int,
        priority: json['priority'] as String,
        difficulty: Difficulty.fromWire(json['difficulty'] as String),
        required: json['required'] as bool,
        rewardEligible: json['rewardEligible'] as bool,
        estimatedStickerReward: json['estimatedStickerReward'] as int,
        confirmedStickerReward: json['confirmedStickerReward'] as int? ?? 0,
        evidenceRequired: json['evidenceRequired'] as bool,
        sourceType: SourceType.fromWire(json['sourceType'] as String),
        sourceId: json['sourceId']?.toString(),
        adjustable: json['adjustable'] as bool,
        adjustmentReason: json['adjustmentReason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'sequence': sequence,
        'planType': planType.wireValue,
        'subject': subject,
        'title': title,
        'description': description,
        'startTime': startTime,
        'endTime': endTime,
        'durationMinutes': durationMinutes,
        'priority': priority,
        'difficulty': difficulty.wireValue,
        'required': required,
        'rewardEligible': rewardEligible,
        'estimatedStickerReward': estimatedStickerReward,
        'confirmedStickerReward': confirmedStickerReward,
        'evidenceRequired': evidenceRequired,
        'sourceType': sourceType.wireValue,
        'sourceId': sourceId,
        'adjustable': adjustable,
        'adjustmentReason': adjustmentReason,
      };

  PlanItem copyWith({
    String? title,
    String? description,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    Difficulty? difficulty,
    int? estimatedStickerReward,
    bool? adjustable,
    String? adjustmentReason,
  }) =>
      PlanItem(
        id: id,
        sequence: sequence,
        planType: planType,
        subject: subject,
        title: title ?? this.title,
        description: description ?? this.description,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        priority: priority,
        difficulty: difficulty ?? this.difficulty,
        required: required,
        rewardEligible: rewardEligible,
        estimatedStickerReward: estimatedStickerReward ?? this.estimatedStickerReward,
        confirmedStickerReward: confirmedStickerReward,
        evidenceRequired: evidenceRequired,
        sourceType: sourceType,
        sourceId: sourceId,
        adjustable: adjustable ?? this.adjustable,
        adjustmentReason: adjustmentReason ?? this.adjustmentReason,
      );
}
