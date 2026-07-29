import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/daily_plan_response.dart';
import '../models/plan_item.dart';
import '../providers/daily_plan_provider.dart';
import '../providers/daily_review_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/generation_reasons_panel.dart';
import '../widgets/message_banner.dart';
import '../widgets/modify_request_sheet.dart';
import '../widgets/plan_item_tile.dart';
import '../widgets/plan_summary_header.dart';
import 'assessment_screen.dart';
import 'daily_review_screen.dart';

class TodayPlanScreen extends StatefulWidget {
  const TodayPlanScreen({super.key});

  @override
  State<TodayPlanScreen> createState() => _TodayPlanScreenState();
}

class _TodayPlanScreenState extends State<TodayPlanScreen> {
  final DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyPlanProvider>().loadPlanFor(_date);
    });
  }

  Future<void> _finishDay(List<PlanItem> scoreableItems) async {
    final reviewProvider = context.read<DailyReviewProvider>();
    await reviewProvider.submitReview(_date, scoreableItems);
    if (!mounted) return;
    final review = reviewProvider.review;
    if (review != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DailyReviewScreen(review: review, date: _date)),
      );
    }
  }

  Future<void> _regenerate() async {
    context.read<DailyReviewProvider>().resetForNewDay();
    await context.read<DailyPlanProvider>().loadPlanFor(_date);
  }

  void _showReasons(List<String> reasons) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: GenerationReasonsPanel(reasons: reasons),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<DailyPlanProvider>(
        builder: (context, planProvider, _) {
          if (planProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (planProvider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(planProvider.error!),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => planProvider.loadPlanFor(_date),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          final plan = planProvider.plan;
          if (plan == null) return const SizedBox.shrink();

          final scoreableItems = plan.dailyPlans.where((p) => p.rewardEligible).toList();

          return Consumer<DailyReviewProvider>(
            builder: (context, reviewProvider, _) {
              final allMarked = reviewProvider.allMarked(scoreableItems);
              final completedCount = scoreableItems.where((p) => reviewProvider.isCompleted(p.id)).length;
              final completionRate = scoreableItems.isEmpty ? 0.0 : completedCount / scoreableItems.length;
              final activeItemId = scoreableItems
                  .firstWhere((p) => !reviewProvider.isCompleted(p.id), orElse: () => scoreableItems.isEmpty ? plan.dailyPlans.first : scoreableItems.first)
                  .id;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: AppHeader(
                      date: _date,
                      studentName: planProvider.studentName,
                      streakDays: planProvider.streakDays,
                      subtitle: '${planProvider.studentName}의 오늘 학습 여정',
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        MessageBanner(
                          title: plan.studentMessage.title,
                          message: plan.studentMessage.message,
                          tone: plan.studentMessage.tone,
                        ),
                        if (plan.parentMessage.approvalRequired) ...[
                          const SizedBox(height: 12),
                          _ParentAttentionBanner(parentMessage: plan.parentMessage),
                        ],
                        const SizedBox(height: 12),
                        PlanSummaryHeader(
                          summary: plan.planSummary,
                          rewardForecast: plan.rewardForecast,
                          completionRate: completionRate,
                        ),
                        const SizedBox(height: 16),
                        for (var i = 0; i < plan.dailyPlans.length; i++)
                          PlanItemTile(
                            item: plan.dailyPlans[i],
                            completed: reviewProvider.isCompleted(plan.dailyPlans[i].id),
                            isFirst: i == 0,
                            isLast: i == plan.dailyPlans.length - 1,
                            isActive: plan.dailyPlans[i].id == activeItemId && plan.dailyPlans[i].rewardEligible,
                            onToggle: plan.dailyPlans[i].rewardEligible
                                ? () => reviewProvider.toggleCompleted(plan.dailyPlans[i].id)
                                : null,
                            onRequestModify: plan.dailyPlans[i].adjustable
                                ? () => showModifyRequestSheet(context, planItemId: plan.dailyPlans[i].id)
                                : null,
                            onRequestAssessment:
                                (reviewProvider.isCompleted(plan.dailyPlans[i].id) && plan.dailyPlans[i].evidenceRequired)
                                    ? () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => AssessmentScreen(planItemId: plan.dailyPlans[i].id)),
                                        )
                                    : null,
                          ),
                        const SizedBox(height: 4),
                        GenerationReasonsPanel(reasons: plan.generationReasons),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: allMarked
                        ? SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              ),
                              onPressed: reviewProvider.isLoading ? null : () => _finishDay(scoreableItems),
                              child: reviewProvider.isLoading
                                  ? const SizedBox(
                                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('오늘 마무리하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryLight,
                                      foregroundColor: AppColors.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                    ),
                                    onPressed: _regenerate,
                                    icon: const Icon(Icons.auto_awesome, size: 18),
                                    label: const Text('AI 다시 추천', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 52,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.gray,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Color(0xFFE4E1F0)),
                                    ),
                                  ),
                                  onPressed: () => _showReasons(plan.generationReasons),
                                  child: const Icon(Icons.tune, size: 20),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Surfaces `parentMessage` when the backend flags today's plan as needing
/// parent sign-off (spec §6: very_tired/sick condition forces a
/// required-only day) -- otherwise this data was generated but never shown.
class _ParentAttentionBanner extends StatelessWidget {
  const _ParentAttentionBanner({required this.parentMessage});

  final ParentMessage parentMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coralBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3C6C1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.coral),
              const SizedBox(width: 6),
              const Text('보호자 확인이 필요해요',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.coral)),
            ],
          ),
          const SizedBox(height: 8),
          Text(parentMessage.summary, style: const TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.4)),
          for (final item in parentMessage.attentionItems) ...[
            const SizedBox(height: 4),
            Text('· $item', style: const TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
