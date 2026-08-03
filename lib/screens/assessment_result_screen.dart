import 'package:flutter/material.dart';

import '../models/assessment_question.dart';
import '../models/assessment_result.dart';
import '../models/assessment_submit_response.dart';
import '../theme/app_colors.dart';
import '../widgets/achievement_stat_card.dart';

/// Shows the graded 이해도 확인 (comprehension check) result: overall score
/// plus per-question feedback with the correct answer revealed. Structurally
/// mirrors DailyReviewScreen.
class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({super.key, required this.result});

  final AssessmentSubmitResponse result;

  @override
  Widget build(BuildContext context) {
    final correctCount = result.results.where((r) => r.isCorrect).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('이해도 확인 결과')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: AchievementStatCard(label: '점수', value: '${result.score}점')),
              const SizedBox(width: 8),
              Expanded(child: AchievementStatCard(label: '정답', value: '$correctCount/${result.totalQuestions}')),
            ],
          ),
          const SizedBox(height: 16),
          Text('문항별 결과', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final r in result.results) _QuestionResultCard(result: r),
        ],
      ),
    );
  }
}

class _QuestionResultCard extends StatelessWidget {
  const _QuestionResultCard({required this.result});

  final AssessmentQuestionResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.isCorrect ? AppColors.green : AppColors.coral;
    final bgColor = result.isCorrect ? AppColors.greenBg : AppColors.coralBg;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(result.isCorrect ? Icons.check_circle : Icons.cancel, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${result.sequence}. ${result.question}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Text('내 답: ${result.studentAnswer}', style: const TextStyle(fontSize: 13)),
          ),
          if (!result.isCorrect) ...[
            const SizedBox(height: 6),
            Text('정답: ${result.correctAnswer}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
          if (result.type == AssessmentQuestionType.multipleChoice && result.choices.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('보기: ${result.choices.join(', ')}', style: TextStyle(fontSize: 12, color: AppColors.gray)),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 13, color: AppColors.teal),
              const SizedBox(width: 4),
              Expanded(child: Text(result.feedback, style: TextStyle(fontSize: 12.5, color: AppColors.teal, height: 1.3))),
            ],
          ),
        ],
      ),
    );
  }
}
