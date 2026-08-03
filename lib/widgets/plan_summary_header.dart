import 'package:flutter/material.dart';

import '../models/plan_summary.dart';
import '../models/reward_forecast.dart';
import '../theme/app_colors.dart';

class PlanSummaryHeader extends StatelessWidget {
  const PlanSummaryHeader({
    super.key,
    required this.summary,
    required this.rewardForecast,
    required this.completionRate,
  });

  final PlanSummary summary;
  final RewardForecast rewardForecast;

  /// 0.0-1.0 fraction of trackable items marked complete so far today.
  final double completionRate;

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
              Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(summary.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _stat('총 학습시간', '${summary.totalStudyMinutes}분', AppColors.primary)),
                    Expanded(child: _stat('필수', '${summary.requiredStudyMinutes}분', AppColors.blue)),
                    Expanded(child: _stat('권장', '${summary.recommendedStudyMinutes}분', AppColors.greenText)),
                    Expanded(child: _stat('휴식', '${summary.breakMinutes}분', AppColors.orange)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _completionRing(),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '예상 스티커 최대 ${rewardForecast.maximumEstimatedStickerReward}개',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.coralBg, borderRadius: BorderRadius.circular(20)),
                child: Text('부모님 승인 필요',
                    style: TextStyle(fontSize: 11.5, color: AppColors.coral, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _completionRing() {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: completionRate.clamp(0, 1),
              strokeWidth: 6,
              backgroundColor: AppColors.grayBg,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(completionRate.clamp(0, 1) * 100).round()}%',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text('완료율', style: TextStyle(fontSize: 9, color: AppColors.gray)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.gray)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
