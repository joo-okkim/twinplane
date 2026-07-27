import 'package:flutter/foundation.dart';

import '../models/daily_review_request.dart';
import '../models/daily_review_response.dart';
import '../models/plan_item.dart';
import '../services/ai_teacher_repository.dart';

class ItemCompletionState {
  final bool completed;
  final int? actualMinutes;

  const ItemCompletionState({required this.completed, this.actualMinutes});
}

class DailyReviewProvider extends ChangeNotifier {
  DailyReviewProvider(this._repository);

  final AiTeacherRepository _repository;

  final Map<String, ItemCompletionState> _completions = {};
  DailyReviewResponse? _review;
  bool _isLoading = false;
  String? _error;

  DailyReviewResponse? get review => _review;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isCompleted(String itemId) => _completions[itemId]?.completed ?? false;

  bool isMarked(String itemId) => _completions.containsKey(itemId);

  void toggleCompleted(String itemId, {int? actualMinutes}) {
    final current = _completions[itemId];
    _completions[itemId] = ItemCompletionState(
      completed: !(current?.completed ?? false),
      actualMinutes: actualMinutes ?? current?.actualMinutes,
    );
    notifyListeners();
  }

  bool allMarked(List<PlanItem> scoreableItems) {
    if (scoreableItems.isEmpty) return false;
    return scoreableItems.every((item) => _completions.containsKey(item.id));
  }

  void resetForNewDay() {
    _completions.clear();
    _review = null;
    _error = null;
    notifyListeners();
  }

  Future<void> submitReview(DateTime date, List<PlanItem> planItems) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final completions = planItems
          .where((p) => p.rewardEligible)
          .map((p) => PlanItemCompletion(
                planItemId: p.id,
                completed: _completions[p.id]?.completed ?? false,
                actualMinutes: _completions[p.id]?.actualMinutes,
              ))
          .toList();
      _review = await _repository.submitDailyReview(date: date, completions: completions);
    } catch (e) {
      _error = '오늘의 평가를 불러오지 못했어요.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
