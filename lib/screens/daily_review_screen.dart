import 'package:flutter/material.dart';

import '../models/daily_review_response.dart';
import '../utils/date_utils.dart';
import '../widgets/achievement_stat_card.dart';
import '../widgets/message_banner.dart';
import '../widgets/reward_summary_card.dart';
import '../widgets/subject_result_card.dart';

class DailyReviewScreen extends StatelessWidget {
  const DailyReviewScreen({super.key, required this.review, required this.date});

  final DailyReviewResponse review;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final achievement = review.achievement;
    return Scaffold(
      appBar: AppBar(title: Text('${formatKoreanDate(date)} 평가')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: AchievementStatCard(label: '전체 달성률', value: '${achievement.overallAchievementRate}%')),
              const SizedBox(width: 8),
              Expanded(child: AchievementStatCard(label: '필수 달성률', value: '${achievement.requiredAchievementRate}%')),
              const SizedBox(width: 8),
              Expanded(child: AchievementStatCard(label: '정시 완료율', value: '${achievement.onTimeCompletionRate}%')),
            ],
          ),
          const SizedBox(height: 16),
          if (review.subjectResults.isNotEmpty) ...[
            Text('과목별 결과', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...review.subjectResults.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SubjectResultCard(result: r),
                )),
            const SizedBox(height: 8),
          ],
          if (review.completedWell.isNotEmpty) ...[
            Text('오늘 잘한 점', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...review.completedWell.map((c) => _bullet(c, Colors.green)),
            const SizedBox(height: 16),
          ],
          if (review.improvementPoints.isNotEmpty) ...[
            Text('내일 반영할 점', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...review.improvementPoints.map((c) => _bullet(c, Colors.blueGrey)),
            const SizedBox(height: 16),
          ],
          MessageBanner(title: '오늘의 한마디', message: review.studentMessage, tone: 'encouraging'),
          const SizedBox(height: 16),
          RewardSummaryCard(reward: review.rewardResult),
        ],
      ),
    );
  }

  Widget _bullet(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
