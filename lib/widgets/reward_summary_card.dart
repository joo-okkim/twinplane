import 'package:flutter/material.dart';

import '../models/daily_review_response.dart';

class RewardSummaryCard extends StatelessWidget {
  const RewardSummaryCard({super.key, required this.reward});

  final RewardResult reward;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text('오늘 획득 스티커 ${reward.earnedStickerCount}개', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            if (reward.allowanceCandidate && reward.expectedAllowance != null) ...[
              const SizedBox(height: 8),
              Text('이번 주 용돈 지급 후보: ${reward.expectedAllowance}${reward.currency == 'KRW' ? '원' : reward.currency}'),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('부모님 승인 대기', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
