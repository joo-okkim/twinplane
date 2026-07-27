/// Client-tracked completion state for one plan item, submitted as part of
/// the daily review request. Kept separate from PlanItem so the plan-creation
/// response model stays a pure mirror of the wire contract.
class PlanItemCompletion {
  final String planItemId;
  final bool completed;
  final int? actualMinutes;

  const PlanItemCompletion({
    required this.planItemId,
    required this.completed,
    this.actualMinutes,
  });

  Map<String, dynamic> toJson() => {
        'planItemId': planItemId,
        'completed': completed,
        'actualMinutes': actualMinutes,
      };
}
