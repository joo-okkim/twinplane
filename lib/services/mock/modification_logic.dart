import '../../models/modification_request.dart';
import '../../models/modification_result.dart';
import '../../models/parent_settings.dart';
import '../../models/plan_item.dart';
import 'message_bank.dart';

int _timeToMinutes(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String _minutesToTime(int minutes) {
  final h = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Rule-based dummy modification handler implementing the priority ladder
/// from spec section 14: a student's request is never blindly honored --
/// required items locked by parent policy are routed to
/// PARENT_APPROVAL_REQUIRED, and otherwise the ladder is: remove bonus ->
/// remove optional -> shrink recommended -> shrink required -> split ->
/// move to another day (the "move" step is out of scope for this mock and
/// falls back to split).
class ModificationLogic {
  static ModificationResult decide({
    required PlanItem item,
    required ModificationRequest request,
    required ParentSettings parentSettings,
  }) {
    if (!item.adjustable) {
      return ModificationResult(
        status: ModificationStatus.parentApprovalRequired,
        updatedItem: null,
        message: '고정 일정이라 앱에서 바로 바꿀 수 없어요.',
        reason: '고정 일정/휴식은 조정 대상이 아니에요.',
      );
    }

    switch (request.reason) {
      case ModificationReason.wrongTime:
        return _handleWrongTime(item);
      case ModificationReason.tired:
      case ModificationReason.tooMuch:
        return _handleReduceOrRemove(item, parentSettings, wantsRemoval: false);
      case ModificationReason.dontWant:
        return _handleReduceOrRemove(item, parentSettings, wantsRemoval: true);
    }
  }

  static ModificationResult _handleWrongTime(PlanItem item) {
    if (item.required) {
      return ModificationResult(
        status: ModificationStatus.parentApprovalRequired,
        updatedItem: null,
        message: '필수 계획의 시간 변경은 보호자 확인 후 반영할게요.',
        reason: '필수 계획의 시간 이동은 보호자 승인 대상이에요.',
      );
    }
    final newStart = _timeToMinutes(item.startTime) + 30;
    final updated = item.copyWith(
      startTime: _minutesToTime(newStart),
      endTime: _minutesToTime(newStart + item.durationMinutes),
      adjustmentReason: MessageBank.modifyRescheduleMessage(),
    );
    return ModificationResult(
      status: ModificationStatus.applied,
      updatedItem: updated,
      message: MessageBank.modifyRescheduleMessage(),
      reason: MessageBank.modifyRescheduleMessage(),
    );
  }

  static ModificationResult _handleReduceOrRemove(
    PlanItem item,
    ParentSettings parentSettings, {
    required bool wantsRemoval,
  }) {
    // Step 1-2: bonus/optional items are removed with the least friction.
    if (item.planType == PlanType.bonus || item.planType == PlanType.optional) {
      final tier = item.planType == PlanType.bonus ? 'bonus' : 'optional';
      final message = MessageBank.modifyRemovedMessage(tier);
      return ModificationResult(
        status: ModificationStatus.removed,
        updatedItem: null,
        message: message,
        reason: message,
      );
    }

    // Step 3: recommended items are shrunk generously.
    if (item.planType == PlanType.recommended) {
      final newDuration = (item.durationMinutes * 0.5).round().clamp(10, item.durationMinutes);
      final start = _timeToMinutes(item.startTime);
      final message = MessageBank.modifyReducedMessage();
      final updated = item.copyWith(
        durationMinutes: newDuration,
        endTime: _minutesToTime(start + newDuration),
        adjustmentReason: message,
      );
      return ModificationResult(status: ModificationStatus.applied, updatedItem: updated, message: message, reason: message);
    }

    // Step 4: required items -- never deleted by this mock. An explicit
    // removal request ("하기 싫어요") on a required item is routed to
    // PARENT_APPROVAL_REQUIRED whenever parent policy locks required-item
    // deletion; a mere "make it lighter" request (tired/too much) is instead
    // eased directly without bothering the parent.
    if (item.required) {
      if (wantsRemoval && parentSettings.requireParentApprovalForRequiredPlanDeletion) {
        return ModificationResult(
          status: ModificationStatus.parentApprovalRequired,
          updatedItem: null,
          message: '이 계획은 꼭 필요한 항목이라 보호자 확인이 필요해요.',
          reason: MessageBank.parentDeletionBlockedReason,
        );
      }
      // Ease the load instead of deleting: downgrade hard->normal first,
      // otherwise trim duration by up to 30%.
      if (item.difficulty == Difficulty.hard) {
        const message = '필수 계획은 삭제 대신 난이도를 낮춰서 조정했어요.';
        final updated = item.copyWith(difficulty: Difficulty.normal, adjustmentReason: message);
        return ModificationResult(status: ModificationStatus.applied, updatedItem: updated, message: message, reason: message);
      }
      final newDuration = (item.durationMinutes * 0.7).round().clamp(10, item.durationMinutes);
      final start = _timeToMinutes(item.startTime);
      const message = '필수 계획이라 삭제 대신 분량을 줄여서 조정했어요.';
      final updated = item.copyWith(
        durationMinutes: newDuration,
        endTime: _minutesToTime(start + newDuration),
        adjustmentReason: message,
      );
      return ModificationResult(status: ModificationStatus.applied, updatedItem: updated, message: message, reason: message);
    }

    // Step 5: fallback -- split into a shorter block.
    final half = (item.durationMinutes / 2).round().clamp(10, item.durationMinutes);
    final start = _timeToMinutes(item.startTime);
    final message = MessageBank.modifyShortenedMessage();
    final updated = item.copyWith(
      durationMinutes: half,
      endTime: _minutesToTime(start + half),
      adjustmentReason: message,
    );
    return ModificationResult(status: ModificationStatus.applied, updatedItem: updated, message: message, reason: message);
  }
}
