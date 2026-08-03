import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/allowance_policy.dart';
import '../models/sticker_policy.dart';
import '../providers/daily_plan_provider.dart';
import '../providers/daily_review_provider.dart';
import '../theme/app_colors.dart';

/// The 보상 (Reward) tab: today's sticker tally, the weekly allowance-
/// candidate ladder, and a transparency panel explaining exactly how
/// stickers are earned. Per spec sections 8/9, the AI never confirms a
/// payout itself -- every allowance figure here is labelled as a candidate
/// awaiting parent approval.
class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<DailyPlanProvider, DailyReviewProvider>(
        builder: (context, planProvider, reviewProvider, _) {
          final plan = planProvider.plan;
          if (plan == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final review = reviewProvider.review;
          final earnedToday = review?.rewardResult.earnedStickerCount;
          final maxToday = plan.rewardForecast.maximumEstimatedStickerReward;
          final weeklyRate = review?.rewardResult.weeklyAchievementRate ?? planProvider.weeklyAchievementRate;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Text('나의 보상', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('성취를 확인해보세요', style: TextStyle(fontSize: 12.5, color: AppColors.gray)),
              const SizedBox(height: 16),
              _StickerSummaryCard(earnedToday: earnedToday, maxToday: maxToday, streakDays: planProvider.streakDays),
              const SizedBox(height: 14),
              _AllowanceLadderCard(policy: planProvider.allowancePolicy, weeklyRate: weeklyRate),
              const SizedBox(height: 14),
              _StickerRulesPanel(policy: planProvider.stickerPolicy),
              const SizedBox(height: 14),
              const _CheerFooter(),
            ],
          );
        },
      ),
    );
  }
}

class _StickerSummaryCard extends StatelessWidget {
  const _StickerSummaryCard({required this.earnedToday, required this.maxToday, required this.streakDays});

  final int? earnedToday;
  final int maxToday;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = earnedToday != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, const Color(0xFF5B4FE9)],
        ),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: const Icon(Icons.star_rounded, color: Colors.amber, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isConfirmed ? '오늘 획득한 스티커' : '오늘 예상 스티커', style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  '${isConfirmed ? earnedToday : 0} / $maxToday개',
                  style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 15, color: Colors.orangeAccent),
                    const SizedBox(width: 4),
                    Text('$streakDays일 연속 학습 중', style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllowanceLadderCard extends StatelessWidget {
  const _AllowanceLadderCard({required this.policy, required this.weeklyRate});

  final AllowancePolicy policy;
  final double weeklyRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('이번 주 용돈 후보', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${weeklyRate.round()}% 달성', style: TextStyle(fontSize: 12.5, color: AppColors.gray, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          if (!policy.enabled || policy.conditions.isEmpty)
            Text('적용 가능한 용돈 정책이 없습니다.', style: TextStyle(fontSize: 12.5, color: AppColors.gray))
          else
            for (final condition in policy.conditions) _tierRow(condition),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.coralBg, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.coral),
                const SizedBox(width: 6),
                Text('최종 지급은 부모님 승인이 필요해요', style: TextStyle(fontSize: 11.5, color: AppColors.coral, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierRow(AllowanceCondition condition) {
    final reached = weeklyRate >= condition.achievementRate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            reached ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: reached ? AppColors.greenText : AppColors.outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '달성률 ${condition.achievementRate.round()}% 이상',
              style: TextStyle(fontSize: 13.5, color: reached ? AppColors.textPrimary : AppColors.gray, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${condition.amount}원',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: reached ? AppColors.primary : AppColors.gray),
          ),
        ],
      ),
    );
  }
}

class _StickerRulesPanel extends StatelessWidget {
  const _StickerRulesPanel({required this.policy});

  final StickerPolicy policy;

  @override
  Widget build(BuildContext context) {
    final rules = <(IconData, String)>[
      (Icons.check_circle_outline, '필수 계획 완료 시 스티커 ${policy.requiredPlanCompletion}개'),
      (Icons.check_circle_outline, '권장 계획 완료 시 스티커 ${policy.recommendedPlanCompletion}개'),
      (Icons.access_time, '정시에 완료하면 추가 ${policy.onTimeBonus}개'),
      (Icons.trending_up, '오늘 달성률 80% 이상이면 추가 ${policy.dailyAchievement80Bonus}개'),
      (Icons.flag_circle_outlined, '필수 계획을 모두 완료하면 추가 ${policy.allRequiredCompletionBonus}개'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('스티커는 어떻게 받나요?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          leading: const Icon(Icons.star_outline_rounded, color: Colors.amber),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          children: [
            for (final rule in rules)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Icon(rule.$1, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(rule.$2, style: const TextStyle(fontSize: 12.5))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheerFooter extends StatelessWidget {
  const _CheerFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.greenBg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.favorite_rounded, color: AppColors.greenText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '스티커보다 더 중요한 건 꾸준히 이어가는 마음이에요.',
              style: TextStyle(fontSize: 12.5, color: AppColors.greenText, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
