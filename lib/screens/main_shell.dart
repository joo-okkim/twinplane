import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/modification_request.dart';
import '../models/modification_result.dart';
import '../providers/daily_plan_provider.dart';
import '../providers/daily_review_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/generation_reasons_panel.dart';
import 'home_screen.dart';
import 'reward_screen.dart';
import 'today_plan_screen.dart';

/// Hosts the single bottom nav bar shared by every tab. 홈/학습/보상 are
/// implemented today; 마이 surfaces a "coming soon" snackbar instead of
/// switching tabs. The floating "AI 코치" button opens a quick-action sheet
/// wired to real plan-modification/regeneration calls rather than a chat UI.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _navIndex = 0;

  void _goToPlanTab() => setState(() => _navIndex = 1);

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('준비 중이에요.')));
      return;
    }
    setState(() => _navIndex = index);
  }

  String? _activeItemId() {
    final plan = context.read<DailyPlanProvider>().plan;
    if (plan == null) return null;
    final reviewProvider = context.read<DailyReviewProvider>();
    final scoreable = plan.dailyPlans.where((p) => p.rewardEligible).toList();
    for (final item in scoreable) {
      if (!reviewProvider.isCompleted(item.id)) return item.id;
    }
    return null;
  }

  Future<void> _requestOnActiveItem(ModificationReason reason) async {
    Navigator.of(context).pop();
    final itemId = _activeItemId();
    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('지금 진행할 학습이 없어요.')));
      return;
    }
    final result = await context.read<DailyPlanProvider>().requestModification(planItemId: itemId, reason: reason);
    if (!mounted) return;
    if (result.status == ModificationStatus.parentApprovalRequired) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('부모님 확인이 필요해요'),
          content: Text(result.message),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _regeneratePlan() async {
    Navigator.of(context).pop();
    context.read<DailyReviewProvider>().resetForNewDay();
    await context.read<DailyPlanProvider>().loadPlanFor(context.read<DailyPlanProvider>().selectedDate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('새로운 계획을 준비했어요!')));
  }

  void _showReasons() {
    Navigator.of(context).pop();
    final reasons = context.read<DailyPlanProvider>().plan?.generationReasons ?? const [];
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: GenerationReasonsPanel(reasons: reasons),
      ),
    );
  }

  void _showAiQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.smart_toy_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('AI 코치에게 물어보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              _quickActionTile(Icons.sentiment_dissatisfied_outlined, '오늘 하기 싫어요', () => _requestOnActiveItem(ModificationReason.dontWant)),
              _quickActionTile(Icons.access_time_rounded, '시간이 부족해요', () => _requestOnActiveItem(ModificationReason.tooMuch)),
              _quickActionTile(Icons.autorenew_rounded, '계획 바꿔줘', _regeneratePlan),
              _quickActionTile(Icons.help_outline_rounded, '왜 이 순서로 계획했어요?', _showReasons),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14.5)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.gray),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _navIndex,
        children: [
          HomeScreen(onViewPlan: _goToPlanTab),
          const TodayPlanScreen(),
          const RewardScreen(),
          const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: _navIndex, onTap: _onNavTap, onAiTap: _showAiQuickActions),
    );
  }
}
