import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/daily_plan_response.dart';
import '../models/plan_item.dart';
import '../models/student_profile.dart';
import '../providers/daily_plan_provider.dart';
import '../providers/daily_review_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../utils/time_format.dart';

/// The 홈 (Home) tab -- a premium AI-coaching dashboard modelled on
/// 다운로드/메인디자인시안.png: hero greeting, an AI Teacher hero card with
/// today's expected achievement rate, a progress dashboard, the "NOW" item
/// to start next, a condensed plan timeline, and three quick insight cards.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onViewPlan});

  final VoidCallback onViewPlan;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();

    return SafeArea(
      child: Consumer2<DailyPlanProvider, DailyReviewProvider>(
        builder: (context, planProvider, reviewProvider, _) {
          final plan = planProvider.plan;
          final scoreableItems =
              plan?.dailyPlans.where((p) => p.rewardEligible).toList() ??
              const <PlanItem>[];
          final completedItems = scoreableItems
              .where((p) => reviewProvider.isCompleted(p.id))
              .toList();
          final completionRate = scoreableItems.isEmpty
              ? 0.0
              : completedItems.length / scoreableItems.length;
          final remainingMinutes = scoreableItems
              .where((p) => !reviewProvider.isCompleted(p.id))
              .fold(0, (sum, p) => sum + p.durationMinutes);
          final earnedStickers = completedItems.fold(
            0,
            (sum, p) => sum + p.estimatedStickerReward,
          );
          PlanItem? activeItem;
          for (final item in scoreableItems) {
            if (!reviewProvider.isCompleted(item.id)) {
              activeItem = item;
              break;
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _HomeHeader(
                date: date,
                studentName: planProvider.studentName,
                streakDays: planProvider.streakDays,
              ),
              const SizedBox(height: 16),
              if (plan != null)
                _AiHeroCard(plan: plan, onStart: onViewPlan)
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 14),
              if (plan != null)
                _ProgressDashboardCard(
                  completionRate: completionRate,
                  completedCount: completedItems.length,
                  totalCount: scoreableItems.length,
                  remainingMinutes: remainingMinutes,
                  earnedStickers: earnedStickers,
                  maxStickers:
                      plan.rewardForecast.maximumEstimatedStickerReward,
                  onViewPlan: onViewPlan,
                ),
              const SizedBox(height: 14),
              if (plan != null) _NowCard(item: activeItem, onStart: onViewPlan),
              const SizedBox(height: 14),
              if (plan != null)
                _MiniTimelineCard(
                  items: plan.dailyPlans,
                  reviewProvider: reviewProvider,
                  onViewPlan: onViewPlan,
                ),
              const SizedBox(height: 14),
              if (plan != null)
                _InsightRow(
                  weakestSubject: planProvider.subjectLevels.isEmpty
                      ? null
                      : planProvider.subjectLevels.reduce(
                          (a, b) =>
                              a.recentAchievementRate < b.recentAchievementRate
                              ? a
                              : b,
                        ),
                  streakDays: planProvider.streakDays,
                  weeklyAchievementRate: planProvider.weeklyAchievementRate,
                  cheerMessage: plan.studentMessage.title,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.date,
    required this.studentName,
    required this.streakDays,
  });

  final DateTime date;
  final String studentName;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    // Decorative level badge derived from weekly performance -- not part of
    // the AI Teacher spec's data model, purely a cosmetic gamification touch.
    final level = 10 + (streakDays ~/ 2);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            studentName.isNotEmpty ? studentName.substring(0, 1) : '?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '안녕, $studentName!',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.waving_hand_rounded,
                    size: 18,
                    color: Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                formatKoreanDate(date),
                style: const TextStyle(fontSize: 12.5, color: AppColors.gray),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('준비 중이에요.'))),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.gray,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orangeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 13,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$streakDays일',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Lv.$level',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard({required this.plan, required this.onStart});

  final DailyPlanResponse plan;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF5B4FE9)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'AI Teacher',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      plan.studentMessage.message,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: Colors.white,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '오늘 예상 달성률',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      '${plan.planSummary.expectedAchievementRate}%',
                      style: const TextStyle(
                        fontSize: 34,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: plan.planSummary.expectedAchievementRate / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: onStart,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '오늘 계획 시작하기',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.play_arrow_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDashboardCard extends StatelessWidget {
  const _ProgressDashboardCard({
    required this.completionRate,
    required this.completedCount,
    required this.totalCount,
    required this.remainingMinutes,
    required this.earnedStickers,
    required this.maxStickers,
    required this.onViewPlan,
  });

  final double completionRate;
  final int completedCount;
  final int totalCount;
  final int remainingMinutes;
  final int earnedStickers;
  final int maxStickers;
  final VoidCallback onViewPlan;

  String get _remainingLabel {
    if (remainingMinutes <= 0) return '0분';
    final h = remainingMinutes ~/ 60;
    final m = remainingMinutes % 60;
    return h > 0 ? '$h시간 $m분' : '$m분';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '오늘의 진행률',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewPlan,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(10, 10),
                ),
                child: const Text(
                  '자세히 보기 >',
                  style: TextStyle(fontSize: 12, color: AppColors.gray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: completionRate.clamp(0, 1),
                        strokeWidth: 8,
                        backgroundColor: AppColors.grayBg,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.greenText,
                        ),
                      ),
                    ),
                    Text(
                      '${(completionRate.clamp(0, 1) * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _miniRow(
                      Icons.check_circle,
                      AppColors.greenText,
                      '완료',
                      '$completedCount / $totalCount',
                    ),
                    const SizedBox(height: 10),
                    _miniRow(
                      Icons.hourglass_bottom_rounded,
                      AppColors.blue,
                      '남은 시간',
                      _remainingLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: _footStat(
                  '예상 스티커',
                  '$earnedStickers / $maxStickers개',
                  Icons.star_rounded,
                  Colors.amber,
                ),
              ),
              Expanded(
                child: _footStat(
                  '오늘 목표',
                  '$maxStickers개',
                  Icons.flag_rounded,
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniRow(IconData icon, Color color, String label, String value) =>
      Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.gray),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ],
      );

  Widget _footStat(String label, String value, IconData icon, Color color) =>
      Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.gray),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      );
}

class _NowCard extends StatelessWidget {
  const _NowCard({required this.item, required this.onStart});

  final PlanItem? item;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.celebration_outlined, color: AppColors.greenText),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '오늘 학습을 모두 마쳤어요! 정말 잘했어요',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final current = item!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'NOW ${current.startTime}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gray.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '우선순위',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.gray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            current.subject != null
                ? '${current.subject} ${current.title}'
                : current.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            current.description,
            style: const TextStyle(fontSize: 12.5, color: AppColors.gray),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              _badge(
                planTypeLabel(current.planType),
                planTypeBadgeStyle(current.planType),
              ),
              _badge(
                difficultyLabel(current.difficulty),
                difficultyBadgeStyle(current.difficulty),
              ),
              _badge(
                formatDuration(current.durationMinutes),
                const BadgeStyle(AppColors.grayBg, AppColors.gray),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: onStart,
              child: const Text(
                '시작하기',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, BadgeStyle style) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: style.background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: style.foreground,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _MiniTimelineCard extends StatelessWidget {
  const _MiniTimelineCard({
    required this.items,
    required this.reviewProvider,
    required this.onViewPlan,
  });

  final List<PlanItem> items;
  final DailyReviewProvider reviewProvider;
  final VoidCallback onViewPlan;

  static const _maxRows = 6;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(_maxRows).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '오늘의 AI 플랜',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewPlan,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(10, 10),
                ),
                child: const Text(
                  '전체 보기 >',
                  style: TextStyle(fontSize: 12, color: AppColors.gray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in shown) _row(item),
        ],
      ),
    );
  }

  Widget _row(PlanItem item) {
    final trackable = item.rewardEligible;
    final done = trackable && reviewProvider.isCompleted(item.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              item.startTime,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppColors.greenText
                  : (trackable ? AppColors.primary : const Color(0xFFD9D9E3)),
            ),
          ),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 13,
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? AppColors.gray : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trackable)
            Text(
              done ? '완료 ✓' : '예정',
              style: TextStyle(
                fontSize: 11.5,
                color: done ? AppColors.greenText : AppColors.gray,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.weakestSubject,
    required this.streakDays,
    required this.weeklyAchievementRate,
    required this.cheerMessage,
  });

  final SubjectLevel? weakestSubject;
  final int streakDays;
  final double weeklyAchievementRate;
  final String cheerMessage;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _insightCard(
              icon: Icons.insights_rounded,
              iconColor: AppColors.blue,
              label: 'AI 분석',
              value: weakestSubject != null
                  ? '${weakestSubject!.recentAchievementRate.round()}%'
                  : '-',
              caption: weakestSubject != null
                  ? '${weakestSubject!.subject} 완료율'
                  : '데이터 없음',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _insightCard(
              icon: Icons.local_fire_department,
              iconColor: AppColors.orange,
              label: '이번 주 성장',
              value: '$streakDays일 연속',
              caption: '주간 달성률 ${weeklyAchievementRate.round()}%',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _insightCard(
              icon: Icons.favorite_rounded,
              iconColor: AppColors.coral,
              label: '오늘의 응원',
              value: null,
              caption: cheerMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? value,
    required String caption,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.gray),
          ),
          if (value != null) ...[
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.gray,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
