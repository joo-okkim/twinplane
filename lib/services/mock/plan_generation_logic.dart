import '../../models/daily_plan_response.dart';
import '../../models/exam_info.dart';
import '../../models/fixed_schedule.dart';
import '../../models/incomplete_plan.dart';
import '../../models/plan_item.dart';
import '../../models/plan_summary.dart';
import '../../models/reward_forecast.dart';
import '../../models/student_dataset.dart';
import '../../models/student_profile.dart';
import 'message_bank.dart';

enum _LoadTier { increase, keep, decrease10, decrease20, requiredOnly }

int _timeToMinutes(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String _minutesToTime(int minutes) {
  final h = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

class _WorkUnit {
  final String subject;
  final String title;
  final String description;
  final int minutes;
  final Difficulty difficulty;
  final PlanType planType;
  final SourceType sourceType;
  final String? sourceId;
  final bool required;
  final bool evidenceRequired;
  final String? adjustmentReason;

  _WorkUnit({
    required this.subject,
    required this.title,
    required this.description,
    required this.minutes,
    required this.difficulty,
    required this.planType,
    required this.sourceType,
    this.sourceId,
    required this.required,
    this.evidenceRequired = false,
    this.adjustmentReason,
  });
}

class _Window {
  int start;
  final int end;
  _Window(this.start, this.end);
  int get remaining => end - start;
}

/// Rule-based dummy "AI" plan generation implementing spec sections 2-8:
/// fixed schedules are never touched, required/deadline work is placed
/// first, recent achievement rate drives a load tier, hard-difficulty items
/// are capped at 40%, and incomplete carry-over is reduced rather than
/// re-added at full size.
class PlanGenerationLogic {
  static DailyPlanResponse generate({
    required StudentDataset dataset,
    required DateTime date,
    List<IncompletePlan>? carryOverOverride,
    StudentCondition? condition,
  }) {
    final effectiveCondition = condition ?? dataset.student.condition;
    // Spec section 6: very_tired/sick force a required-only day regardless of
    // recent achievement rate; tired/stressed apply an extra load reduction
    // on top of the achievement-based tier instead of overriding it.
    final conditionForcesRequiredOnly =
        effectiveCondition == StudentCondition.veryTired || effectiveCondition == StudentCondition.sick;

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final carryOver = carryOverOverride ?? dataset.incompletePlans;
    final achievementTier = _resolveLoadTier(dataset.recentPerformance.dailyAchievementRate7Days);
    final tier = conditionForcesRequiredOnly ? _LoadTier.requiredOnly : achievementTier;

    final fixedItems = _buildFixedItems(dataset.fixedSchedules);
    final windows = _computeWindows(dataset, fixedItems);

    final requiredUnits = _buildRequiredUnits(dataset, date);
    final carryOverUnits = _buildCarryOverUnits(carryOver);
    final recommendedUnits = _buildRecommendedUnits(dataset);

    final conditionMultiplier = _conditionLoadMultiplier(effectiveCondition);
    final targetStudyMinutes = (_targetStudyMinutes(dataset, tier) * conditionMultiplier).round();

    final placed = <PlanItem>[];
    var seq = 1;
    final carryOverDecisions = <CarryOverDecision>[];

    // Insert an after-school decompression break at the very start of the
    // first window, before any study begins (spec section 4: rest/study
    // balance).
    if (windows.isNotEmpty && windows.first.remaining > 0) {
      final w = windows.first;
      final breakLen = _clamp(30, 10, w.remaining);
      placed.add(_breakItem(seq++, w.start, breakLen, '하교 후 휴식', '간식을 먹고 몸과 머리를 쉬는 시간이에요.'));
      w.start += breakLen;
    }

    var remainingRequiredBudget = 1 << 30; // required work is never cut
    var remainingOptionalBudget = tier == _LoadTier.requiredOnly ? 0 : targetStudyMinutes;

    final queue = <_WorkUnit>[...requiredUnits, ...carryOverUnits, if (tier != _LoadTier.requiredOnly) ...recommendedUnits];

    Difficulty? lastDifficulty;
    for (final unit in List<_WorkUnit>.from(queue)) {
      if (!unit.required) {
        if (remainingOptionalBudget <= 0) continue;
      }

      // Avoid two hard items back to back: if the next unit is hard and the
      // previous placed item was hard, try to find a later non-hard unit to
      // swap with.
      var effectiveUnit = unit;
      if (unit.difficulty == Difficulty.hard && lastDifficulty == Difficulty.hard) {
        final swapIndex = queue.indexWhere((u) => u != unit && u.difficulty != Difficulty.hard && queue.indexOf(u) > queue.indexOf(unit));
        if (swapIndex != -1) {
          effectiveUnit = queue[swapIndex];
          queue[swapIndex] = unit;
        }
      }

      final window = _findWindowWithRoom(windows, 10);
      if (window == null) break;

      var duration = effectiveUnit.minutes;
      if (!effectiveUnit.required) {
        duration = duration.clamp(10, remainingOptionalBudget);
      }
      duration = duration > window.remaining ? window.remaining : duration;
      if (duration < 10) break;

      final start = window.start;
      final end = start + duration;
      final isCarryOver = effectiveUnit.sourceType == SourceType.incompletePlan;
      String? adjustmentReason = effectiveUnit.adjustmentReason;
      if (isCarryOver) {
        adjustmentReason ??= MessageBank.carryOverReducedReason();
      }

      placed.add(PlanItem(
        id: 'plan-$seq',
        sequence: seq,
        planType: effectiveUnit.planType,
        subject: effectiveUnit.subject,
        title: effectiveUnit.title,
        description: effectiveUnit.description,
        startTime: _minutesToTime(start),
        endTime: _minutesToTime(end),
        durationMinutes: duration,
        priority: effectiveUnit.required ? 'high' : 'normal',
        difficulty: effectiveUnit.difficulty,
        required: effectiveUnit.required,
        rewardEligible: true,
        estimatedStickerReward: effectiveUnit.required
            ? dataset.stickerPolicy.requiredPlanCompletion
            : dataset.stickerPolicy.recommendedPlanCompletion,
        confirmedStickerReward: 0,
        evidenceRequired: effectiveUnit.evidenceRequired,
        sourceType: effectiveUnit.sourceType,
        sourceId: effectiveUnit.sourceId,
        adjustable: true,
        adjustmentReason: adjustmentReason,
      ));
      seq++;
      window.start = end;
      lastDifficulty = effectiveUnit.difficulty;
      if (!effectiveUnit.required) remainingOptionalBudget -= duration;

      if (isCarryOver) {
        carryOverDecisions.add(CarryOverDecision(
          sourcePlanItemId: effectiveUnit.sourceId ?? '',
          decision: 'REDUCE_AND_CARRY_OVER',
          originalQuantity: '${carryOver.first.estimatedMinutes}분 분량',
          adjustedQuantity: '$duration분 분량',
          reason: MessageBank.carryOverReducedReason(),
        ));
      }

      // Insert a short rest after this study block if there's another item
      // still to place and room remains in the window.
      final breakMinutes = duration <= 25 ? 5 : (duration <= 45 ? 8 : 12);
      if (window.remaining > breakMinutes + 10) {
        placed.add(_breakItem(seq++, window.start, breakMinutes, '짧은 휴식', '물을 마시고 가볍게 스트레칭해요.'));
        window.start += breakMinutes;
      }

      remainingRequiredBudget = remainingRequiredBudget; // no-op, required never capped
    }

    // Merge in fixed schedule items at their real times, then sort by start.
    final merged = [...placed, ...fixedItems];
    merged.sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));
    var resequenced = <PlanItem>[];
    for (var i = 0; i < merged.length; i++) {
      resequenced.add(_withSequence(merged[i], i + 1));
    }

    final hardCapRatio =
        effectiveCondition == StudentCondition.tired || effectiveCondition == StudentCondition.stressed ? 0.25 : 0.4;
    resequenced = _enforceHardDifficultyCap(resequenced, hardCapRatio);

    final requiredMinutes = resequenced
        .where((p) => p.required && p.planType != PlanType.fixed && p.planType != PlanType.breakTime)
        .fold(0, (sum, p) => sum + p.durationMinutes);
    final recommendedMinutes = resequenced
        .where((p) => !p.required && p.planType != PlanType.fixed && p.planType != PlanType.breakTime)
        .fold(0, (sum, p) => sum + p.durationMinutes);
    final breakMinutesTotal =
        resequenced.where((p) => p.planType == PlanType.breakTime).fold(0, (sum, p) => sum + p.durationMinutes);

    final easyCount = resequenced.where((p) => p.difficulty == Difficulty.easy).length;
    final normalCount = resequenced.where((p) => p.difficulty == Difficulty.normal).length;
    final hardCount = resequenced.where((p) => p.difficulty == Difficulty.hard).length;

    final planSummary = PlanSummary(
      title: '오늘의 AI 학습 플랜',
      totalStudyMinutes: requiredMinutes + recommendedMinutes,
      requiredStudyMinutes: requiredMinutes,
      recommendedStudyMinutes: recommendedMinutes,
      breakMinutes: breakMinutesTotal,
      planItemCount: resequenced.length,
      requiredPlanCount: resequenced.where((p) => p.required && p.planType != PlanType.fixed).length,
      difficultyBalance: DifficultyBalance(easy: easyCount, normal: normalCount, hard: hardCount),
      expectedAchievementRate: _expectedAchievementRate(tier),
      planConfidenceScore: _planConfidenceScore(tier),
    );

    final generationReasons = _buildGenerationReasons(dataset, tier, date, carryOverDecisions, effectiveCondition);

    final rewardForecast = RewardForecast(
      estimatedPlanStickerReward: resequenced
          .where((p) => p.rewardEligible)
          .fold(0, (sum, p) => sum + p.estimatedStickerReward),
      dailyBonusStickerPossible:
          dataset.stickerPolicy.dailyAchievement80Bonus + dataset.stickerPolicy.allRequiredCompletionBonus,
      maximumEstimatedStickerReward: resequenced
              .where((p) => p.rewardEligible)
              .fold(0, (sum, p) => sum + p.estimatedStickerReward) +
          dataset.stickerPolicy.dailyAchievement80Bonus +
          dataset.stickerPolicy.allRequiredCompletionBonus,
      allowancePolicyExists: dataset.allowancePolicy.enabled,
      allowancePeriod: dataset.allowancePolicy.period,
      currentWeeklyAchievementRate: dataset.recentPerformance.weeklyAchievementRate,
      targetAchievementRate: dataset.allowancePolicy.conditions.isNotEmpty
          ? dataset.allowancePolicy.conditions.first.achievementRate
          : null,
      expectedAllowance:
          dataset.allowancePolicy.conditions.isNotEmpty ? dataset.allowancePolicy.conditions.first.amount : null,
      parentApprovalRequired: true,
      message: dataset.allowancePolicy.conditions.isNotEmpty
          ? '이번 주 달성률이 ${dataset.allowancePolicy.conditions.first.achievementRate.round()}% 이상이면 '
              '${dataset.allowancePolicy.conditions.first.amount}원 용돈 지급 후보가 됩니다.'
          : '적용 가능한 용돈 정책이 없습니다.',
    );

    return DailyPlanResponse(
      result: 'success',
      targetDate: dateStr,
      studentId: dataset.student.studentId,
      planSummary: planSummary,
      dailyPlans: resequenced,
      generationReasons: generationReasons,
      studentMessage: StudentMessage(
        title: MessageBank.studentMessageTitle(effectiveCondition.wireValue),
        message: MessageBank.studentMessageBody(
          leastCompletedSubject: dataset.recentPerformance.leastCompletedSubject,
          reducedLoad: tier == _LoadTier.decrease10 ||
              tier == _LoadTier.decrease20 ||
              tier == _LoadTier.requiredOnly ||
              conditionMultiplier < 1.0,
        ),
        tone: conditionForcesRequiredOnly || effectiveCondition == StudentCondition.stressed ? 'concerned' : 'encouraging',
      ),
      parentMessage: ParentMessage(
        summary:
            '최근 달성률과 ${dataset.recentPerformance.leastCompletedSubject} 미완료 이력을 반영해 '
            '총 자기주도 학습시간을 ${requiredMinutes + recommendedMinutes}분으로 조정했습니다.',
        attentionItems: [
          if (carryOverDecisions.isNotEmpty) '전날 미완료 학습이 있어 분량을 줄여 재배치했습니다.',
          if (dataset.recentPerformance.dailyAchievementRate7Days < 75)
            '${dataset.recentPerformance.leastCompletedSubject} 달성률이 최근 낮은 편입니다.',
          if (conditionForcesRequiredOnly) '학생 컨디션(${effectiveCondition.wireValue}) 확인이 필요해요.',
        ],
        approvalRequired: conditionForcesRequiredOnly,
      ),
      rewardForecast: rewardForecast,
      carryOverDecisions: carryOverDecisions,
      warnings: [
        if (effectiveCondition == StudentCondition.sick) '학생이 아픈 컨디션이에요. 학습보다 휴식을 우선해 주세요.',
      ],
      validation: PlanValidation(
        fixedScheduleConflict: false,
        exceedsMaximumStudyTime: (requiredMinutes + recommendedMinutes) > dataset.parentSettings.maxDailyStudyMinutes,
        bedTimeConflict: resequenced.isNotEmpty &&
            _timeToMinutes(resequenced.last.endTime) > _timeToMinutes(dataset.student.bedTime),
        insufficientBreakTime: breakMinutesTotal < 10,
        excessiveHardTasks: resequenced.isNotEmpty && hardCount / resequenced.length > 0.4,
        excessiveCarryOver: carryOverDecisions.length > 2,
        valid: true,
      ),
    );
  }

  static _LoadTier _resolveLoadTier(double rate7d) {
    if (rate7d >= 90) return _LoadTier.increase;
    if (rate7d >= 75) return _LoadTier.keep;
    if (rate7d >= 60) return _LoadTier.decrease10;
    if (rate7d >= 40) return _LoadTier.decrease20;
    return _LoadTier.requiredOnly;
  }

  static int _targetStudyMinutes(StudentDataset dataset, _LoadTier tier) {
    final base = dataset.student.maxSelfStudyMinutes < dataset.parentSettings.maxDailyStudyMinutes
        ? dataset.student.maxSelfStudyMinutes
        : dataset.parentSettings.maxDailyStudyMinutes;
    switch (tier) {
      case _LoadTier.increase:
        final increased = (base * 1.05).round();
        return increased > dataset.parentSettings.maxDailyStudyMinutes
            ? dataset.parentSettings.maxDailyStudyMinutes
            : increased;
      case _LoadTier.keep:
        return base;
      case _LoadTier.decrease10:
        return (base * 0.9).round();
      case _LoadTier.decrease20:
        return (base * 0.8).round();
      case _LoadTier.requiredOnly:
        return 0;
    }
  }

  /// Spec section 6: extra load adjustment layered on top of the
  /// achievement-based tier. very_tired/sick are already forced to
  /// requiredOnly (target 0) upstream, so their multiplier here is moot.
  static double _conditionLoadMultiplier(StudentCondition condition) {
    switch (condition) {
      case StudentCondition.veryGood:
      case StudentCondition.good:
      case StudentCondition.normal:
        return 1.0;
      case StudentCondition.tired:
        return 0.85;
      case StudentCondition.stressed:
        return 0.7;
      case StudentCondition.veryTired:
      case StudentCondition.sick:
        return 0.0;
    }
  }

  static int _expectedAchievementRate(_LoadTier tier) {
    switch (tier) {
      case _LoadTier.increase:
        return 88;
      case _LoadTier.keep:
        return 82;
      case _LoadTier.decrease10:
        return 78;
      case _LoadTier.decrease20:
        return 75;
      case _LoadTier.requiredOnly:
        return 70;
    }
  }

  static int _planConfidenceScore(_LoadTier tier) {
    switch (tier) {
      case _LoadTier.increase:
        return 90;
      case _LoadTier.keep:
        return 88;
      case _LoadTier.decrease10:
        return 85;
      case _LoadTier.decrease20:
        return 82;
      case _LoadTier.requiredOnly:
        return 78;
    }
  }

  static List<PlanItem> _buildFixedItems(List<FixedSchedule> schedules) {
    var seq = 0;
    return schedules
        .map((s) => PlanItem(
              id: 'fixed-${seq++}',
              sequence: 0,
              planType: PlanType.fixed,
              subject: null,
              title: s.title,
              description: '고정 일정이에요.',
              startTime: s.startTime,
              endTime: s.endTime,
              durationMinutes: _timeToMinutes(s.endTime) - _timeToMinutes(s.startTime),
              priority: 'required',
              difficulty: Difficulty.normal,
              required: true,
              rewardEligible: false,
              estimatedStickerReward: 0,
              confirmedStickerReward: 0,
              evidenceRequired: false,
              sourceType: SourceType.fixedSchedule,
              sourceId: null,
              adjustable: false,
              adjustmentReason: null,
            ))
        .toList();
  }

  static PlanItem _breakItem(int seq, int start, int duration, String title, String description) => PlanItem(
        id: 'break-$seq',
        sequence: seq,
        planType: PlanType.breakTime,
        subject: null,
        title: title,
        description: description,
        startTime: _minutesToTime(start),
        endTime: _minutesToTime(start + duration),
        durationMinutes: duration,
        priority: 'required',
        difficulty: Difficulty.easy,
        required: true,
        rewardEligible: false,
        estimatedStickerReward: 0,
        confirmedStickerReward: 0,
        evidenceRequired: false,
        sourceType: SourceType.aiGenerated,
        sourceId: null,
        adjustable: false,
        adjustmentReason: null,
      );

  static PlanItem _withSequence(PlanItem item, int sequence) => PlanItem(
        id: item.id,
        sequence: sequence,
        planType: item.planType,
        subject: item.subject,
        title: item.title,
        description: item.description,
        startTime: item.startTime,
        endTime: item.endTime,
        durationMinutes: item.durationMinutes,
        priority: item.priority,
        difficulty: item.difficulty,
        required: item.required,
        rewardEligible: item.rewardEligible,
        estimatedStickerReward: item.estimatedStickerReward,
        confirmedStickerReward: item.confirmedStickerReward,
        evidenceRequired: item.evidenceRequired,
        sourceType: item.sourceType,
        sourceId: item.sourceId,
        adjustable: item.adjustable,
        adjustmentReason: item.adjustmentReason,
      );

  /// Gaps between wake-up/fixed-schedules/bedtime, each with a small
  /// transition buffer, become the day's available study windows.
  static List<_Window> _computeWindows(StudentDataset dataset, List<PlanItem> fixedItems) {
    const wakeBuffer = 30; // getting ready
    const windDown = 20; // wind-down before bed, no heavy study right before sleep

    // The student's preferred self-study start time acts as a floor: a short
    // gap between wake-up and school start (or any other pre-noon gap) is
    // not a realistic self-study window, so we never schedule study before it.
    final wakeFloor = _timeToMinutes(dataset.student.wakeUpTime) + wakeBuffer;
    final preferredFloor = _timeToMinutes(dataset.student.preferredStudyStartTime);
    final dayStart = wakeFloor > preferredFloor ? wakeFloor : preferredFloor;
    final dayEnd = _timeToMinutes(dataset.student.bedTime) - windDown;

    final sortedFixed = [...fixedItems]..sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));

    final windows = <_Window>[];
    var cursor = dayStart;
    for (final f in sortedFixed) {
      final fStart = _timeToMinutes(f.startTime);
      final fEnd = _timeToMinutes(f.endTime);
      if (fStart > cursor) {
        final windowEnd = fStart - 5; // small buffer before the fixed block
        if (windowEnd - cursor >= 15) {
          windows.add(_Window(cursor, windowEnd));
        }
      }
      final afterFixed = fEnd + 10; // small buffer after the fixed block
      if (afterFixed > cursor) cursor = afterFixed; // cursor must never move backward
    }
    if (dayEnd - cursor >= 15) {
      windows.add(_Window(cursor, dayEnd));
    }
    return windows;
  }

  static _Window? _findWindowWithRoom(List<_Window> windows, int minRoom) {
    for (final w in windows) {
      if (w.remaining >= minRoom) return w;
    }
    return null;
  }

  static int _clamp(int value, int min, int max) {
    if (max < min) return max;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static List<_WorkUnit> _buildRequiredUnits(StudentDataset dataset, DateTime date) {
    final units = <_WorkUnit>[];
    for (final a in dataset.assignments) {
      if (!a.required) continue;
      final subjectLevel = dataset.subjectLevelFor(a.subject);
      final exam = dataset.exams.firstWhere(
        (e) => e.subject == a.subject,
        orElse: () => const ExamInfo(examName: '', subject: '', examDate: '', scope: '', importance: ''),
      );
      final isExamRelevant = exam.subject == a.subject && exam.examName.isNotEmpty;
      final difficulty = subjectLevel != null && subjectLevel.recentAchievementRate < 70
          ? Difficulty.hard
          : Difficulty.normal;
      final dueToday = a.dueDate == _dateStr(date);
      final description = isExamRelevant
          ? '${exam.examName} 대비를 위해 ${exam.scope} 관련 내용을 학습해요.'
          : (dueToday ? '오늘 마감인 과제를 먼저 끝내볼까요.' : '마감이 가까운 과제예요.');
      units.add(_WorkUnit(
        subject: a.subject,
        title: a.title,
        description: description,
        minutes: a.estimatedMinutes,
        difficulty: difficulty,
        planType: PlanType.required,
        sourceType: SourceType.assignment,
        sourceId: a.assignmentId.toString(),
        required: true,
        evidenceRequired: a.evidenceRequired,
        adjustmentReason: dueToday
            ? MessageBank.assignmentDueReason(a.title, true)
            : (isExamRelevant ? MessageBank.examProximityReason(a.subject, exam.daysUntil(date)) : null),
      ));
    }
    // Sort so due-today / exam-relevant / historically-hard subjects land in
    // the first (freshest-concentration) window.
    units.sort((a, b) {
      if (a.difficulty == Difficulty.hard && b.difficulty != Difficulty.hard) return -1;
      if (b.difficulty == Difficulty.hard && a.difficulty != Difficulty.hard) return 1;
      return 0;
    });
    return units;
  }

  static List<_WorkUnit> _buildCarryOverUnits(List<IncompletePlan> carryOver) {
    return carryOver.map((p) {
      final reducedMinutes = (p.estimatedMinutes * 0.5).round().clamp(10, p.estimatedMinutes);
      return _WorkUnit(
        subject: p.subject,
        title: '${p.title} (분량 축소)',
        description: '전날 컨디션을 고려해 분량을 줄여 다시 도전해봐요.',
        minutes: reducedMinutes,
        difficulty: Difficulty.normal,
        planType: PlanType.recommended,
        sourceType: SourceType.incompletePlan,
        sourceId: p.planItemId.toString(),
        required: false,
        adjustmentReason: MessageBank.carryOverReducedReason(),
      );
    }).toList();
  }

  static List<_WorkUnit> _buildRecommendedUnits(StudentDataset dataset) {
    final units = <_WorkUnit>[];
    for (final s in dataset.subjectLevels) {
      units.add(_WorkUnit(
        subject: s.subject,
        title: '${s.subject} 복습',
        description: '오늘 배운 내용을 가볍게 복습해요.',
        minutes: 20,
        difficulty: Difficulty.easy,
        planType: PlanType.recommended,
        sourceType: SourceType.aiGenerated,
        required: false,
      ));
    }
    return units;
  }

  static List<PlanItem> _enforceHardDifficultyCap(List<PlanItem> items, double hardCapRatio) {
    final studyItems = items.where((p) => p.planType != PlanType.fixed && p.planType != PlanType.breakTime).toList();
    if (studyItems.isEmpty) return items;
    var hardCount = studyItems.where((p) => p.difficulty == Difficulty.hard).length;
    final maxHard = (studyItems.length * hardCapRatio).floor();
    if (hardCount <= maxHard) return items;

    final result = [...items];
    final hardIndexesByPriority = <int>[];
    for (var i = 0; i < result.length; i++) {
      if (result[i].difficulty == Difficulty.hard && !result[i].required) {
        hardIndexesByPriority.add(i);
      }
    }
    for (var i = 0; i < result.length && hardCount > maxHard; i++) {
      if (result[i].difficulty == Difficulty.hard && !result[i].required) {
        result[i] = result[i].copyWith(
          difficulty: Difficulty.normal,
          adjustmentReason: MessageBank.hardCapReason(),
        );
        hardCount--;
      }
    }
    return result;
  }

  static List<String> _buildGenerationReasons(
    StudentDataset dataset,
    _LoadTier tier,
    DateTime date,
    List<CarryOverDecision> carryOverDecisions,
    StudentCondition condition,
  ) {
    final reasons = <String>[
      MessageBank.loadTierReason(_tierLabel(tier), dataset.recentPerformance.dailyAchievementRate7Days),
    ];
    if (condition != StudentCondition.normal && condition != StudentCondition.good && condition != StudentCondition.veryGood) {
      reasons.add(MessageBank.conditionAdjustmentReason(condition));
    }
    for (final exam in dataset.exams) {
      reasons.add(MessageBank.examProximityReason(exam.subject, exam.daysUntil(date)));
    }
    for (final a in dataset.assignments) {
      if (a.required && a.dueDate == _dateStr(date)) {
        reasons.add(MessageBank.assignmentDueReason(a.title, true));
      }
    }
    if (carryOverDecisions.isNotEmpty) {
      reasons.add(MessageBank.carryOverReducedReason());
    }
    reasons.add(MessageBank.hardCapReason());
    return reasons;
  }

  static String _tierLabel(_LoadTier tier) => switch (tier) {
        _LoadTier.increase => 'increase',
        _LoadTier.keep => 'keep',
        _LoadTier.decrease10 => 'decrease10',
        _LoadTier.decrease20 => 'decrease20',
        _LoadTier.requiredOnly => 'requiredOnly',
      };

  static String _dateStr(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
