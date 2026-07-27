import 'package:flutter/material.dart';

import '../models/plan_item.dart';
import '../theme/app_colors.dart';
import '../utils/time_format.dart';

class PlanItemTile extends StatelessWidget {
  const PlanItemTile({
    super.key,
    required this.item,
    required this.completed,
    required this.isFirst,
    required this.isLast,
    this.isActive = false,
    this.onToggle,
    this.onRequestModify,
  });

  final PlanItem item;
  final bool completed;
  final bool isFirst;
  final bool isLast;
  final bool isActive;
  final VoidCallback? onToggle;
  final VoidCallback? onRequestModify;

  bool get _isTrackable => item.rewardEligible;

  @override
  Widget build(BuildContext context) {
    final isFixedOrBreak = item.planType == PlanType.fixed || item.planType == PlanType.breakTime;
    final (icon, iconBg, iconColor) = planItemVisual(item);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: isActive || completed ? AppColors.primary : const Color(0xFFD9D9E3),
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFE4E1F0))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(item.endTime, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isFixedOrBreak ? const Color(0xFFF7F7FA) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isActive ? Border.all(color: AppColors.primary, width: 1.5) : null,
                  boxShadow: isFixedOrBreak
                      ? null
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, size: 19, color: iconColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.subject != null ? '${item.subject} ${item.title}' : item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    decoration: completed ? TextDecoration.lineThrough : null,
                                    color: completed ? AppColors.gray : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.adjustable)
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: onRequestModify,
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.more_vert, size: 18, color: AppColors.gray),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(item.description, style: const TextStyle(fontSize: 12.5, color: AppColors.gray)),
                          if (item.adjustmentReason != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_awesome, size: 13, color: AppColors.teal),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.adjustmentReason!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.teal, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _pill(planTypeLabel(item.planType), planTypeBadgeStyle(item.planType)),
                              if (!isFixedOrBreak) _pill(difficultyLabel(item.difficulty), difficultyBadgeStyle(item.difficulty)),
                              _durationPill(item.durationMinutes),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isTrackable) ...[
                      const SizedBox(width: 6),
                      _TimelineCheckbox(completed: completed, active: isActive, onTap: onToggle),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, BadgeStyle style) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: style.background, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(fontSize: 11, color: style.foreground, fontWeight: FontWeight.w600)),
      );

  Widget _durationPill(int minutes) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.grayBg, borderRadius: BorderRadius.circular(20)),
        child: Text(formatDuration(minutes), style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w600)),
      );
}

class _TimelineCheckbox extends StatelessWidget {
  const _TimelineCheckbox({required this.completed, required this.active, this.onTap});

  final bool completed;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: completed ? AppColors.primary : Colors.transparent,
          border: Border.all(color: completed || active ? AppColors.primary : const Color(0xFFD9D9E3), width: 2),
        ),
        child: completed ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      ),
    );
  }
}
