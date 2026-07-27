import '../../models/student_profile.dart';

/// Curated, soft-phrasing string templates used by the rule-based mock
/// logic. Centralizing every student/parent-facing sentence here means no
/// code path can accidentally emit a blaming phrase ("게으르다", "의지가
/// 부족하다", "실패했다" etc.) -- every string here has already been chosen
/// to match the AI Teacher spec's approved tone.
class MessageBank {
  MessageBank._();

  static String conditionAdjustmentReason(StudentCondition condition) => switch (condition) {
        StudentCondition.tired => '오늘 컨디션이 다소 피곤하다고 하셔서 학습량을 조금 줄였어요.',
        StudentCondition.veryTired => '많이 피곤한 날이라 꼭 필요한 계획 중심으로만 구성했어요.',
        StudentCondition.stressed => '마음이 편하지 않은 날이라 작은 단위로 나누어 부담을 줄였어요.',
        StudentCondition.sick => '컨디션이 좋지 않아 학습보다 휴식을 우선했어요. 보호자 확인이 필요해요.',
        _ => '',
      };

  static String loadTierReason(String tierLabel, double rate7d) {
    final pct = rate7d.round();
    switch (tierLabel) {
      case 'increase':
        return '최근 7일 달성률이 $pct%로 높아 학습량을 조금 늘려도 괜찮을 것 같아요.';
      case 'keep':
        return '최근 7일 달성률이 $pct%로 안정적이어서 기존 학습량을 그대로 유지했어요.';
      case 'decrease10':
        return '최근 7일 달성률이 $pct%이어서 학습량을 10% 정도 줄여 부담을 낮췄어요.';
      case 'decrease20':
        return '최근 7일 달성률이 $pct%이어서 학습량을 20% 정도 줄이고 꼭 필요한 것 위주로 구성했어요.';
      case 'requiredOnly':
      default:
        return '최근 7일 달성률이 $pct%이어서 오늘은 꼭 필요한 계획 중심으로만 구성했어요.';
    }
  }

  static String examProximityReason(String subject, int daysLeft) {
    if (daysLeft <= 2) {
      return '$subject 시험이 코앞이라 새로운 학습보다 핵심 복습 위주로 배치했어요.';
    } else if (daysLeft <= 6) {
      return '$subject 시험이 얼마 남지 않아 오답과 취약 영역을 우선 배치했어요.';
    } else if (daysLeft <= 14) {
      return '$subject 시험이 다가오고 있어 핵심 개념과 문제풀이 비중을 높였어요.';
    } else {
      return '$subject 시험까지 시간이 있어 진도와 복습을 균형 있게 배치했어요.';
    }
  }

  static String assignmentDueReason(String title, bool dueToday) {
    return dueToday
        ? '오늘 마감인 "$title" 과제를 우선 배치했어요.'
        : '마감이 가까운 "$title" 과제를 먼저 배치했어요.';
  }

  static String carryOverReducedReason() =>
      '전날 컨디션을 반영해 이월된 학습은 분량을 줄여서 다시 배치했어요.';

  static String hardCapReason() =>
      '어려운 과목이 너무 몰리지 않도록 일부 난이도를 조정했어요.';

  static String studentMessageTitle(String condition) {
    switch (condition) {
      case 'tired':
      case 'very_tired':
        return '오늘은 가볍게, 할 수 있는 만큼만 해봐요.';
      case 'stressed':
        return '오늘은 작은 단위로 하나씩 완료해봐요.';
      case 'sick':
        return '오늘은 몸을 먼저 돌보는 게 우선이에요.';
      default:
        return '오늘은 중요한 계획부터 차근차근 해봐요.';
    }
  }

  static String studentMessageBody({
    required String leastCompletedSubject,
    required bool reducedLoad,
  }) {
    final loadPart = reducedLoad
        ? '지난 학습 결과를 반영해 분량을 줄였어요. '
        : '';
    return '$loadPart$leastCompletedSubject부터 먼저 시작해서 중요한 계획을 하나씩 완료해봅시다.'
        .trim();
  }

  static const String parentDeletionBlockedReason =
      '필수 계획 삭제는 보호자 승인이 필요한 항목이라 자동으로 반영하지 않았어요.';

  static String modifyReducedMessage() =>
      '오늘 컨디션을 반영해 분량을 줄여서 이어서 진행할 수 있게 조정했어요.';

  static String modifyShortenedMessage() =>
      '짧게 시작한 뒤 집중 상태를 다시 확인해볼 수 있도록 시간을 줄였어요.';

  static String modifyRescheduleMessage() =>
      '지금 시간이 맞지 않는 것 같아 다른 시간대로 옮겨봤어요.';

  static String modifyRemovedMessage(String tier) => switch (tier) {
        'bonus' => '보너스 계획이라 부담 없이 오늘 계획에서 제외했어요.',
        'optional' => '선택 계획이라 오늘 계획에서 제외했어요.',
        _ => '오늘 수행 가능한 범위로 조정했어요.',
      };

  static String reviewCompletedRequired() => '오늘 필수 계획을 완료했어요.';

  static String reviewCompletedItem(String title) => '"$title"을(를) 완료했어요.';

  static String reviewSlowerThanPlanned(String subject, int extraMinutes) =>
      '$subject은(는) 예상보다 $extraMinutes분 더 걸렸어요. 다음에는 시간을 조금 더 넉넉히 잡아볼게요.';

  static String reviewFasterThanPlanned(String subject) =>
      '$subject은(는) 예상보다 빠르게 완료했어요.';

  static String reviewIncompleteGentle(String title) =>
      '"$title"은(는) 다음 계획에서 조정해볼게요.';

  static String reviewEncouragement(int overallRate) {
    if (overallRate >= 90) {
      return '오늘 정말 잘 해냈어요. 이 흐름 그대로 내일도 이어가봐요!';
    } else if (overallRate >= 70) {
      return '완료한 부분을 기준으로 다음 계획을 개선하겠습니다. 오늘도 수고했어요!';
    } else {
      return '오늘 수행 가능한 범위로 조정했습니다. 다시 시작해봐도 충분해요!';
    }
  }
}
