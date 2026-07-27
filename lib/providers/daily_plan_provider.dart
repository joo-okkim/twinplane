import 'package:flutter/foundation.dart';

import '../models/allowance_policy.dart';
import '../models/daily_plan_response.dart';
import '../models/exam_info.dart';
import '../models/modification_request.dart';
import '../models/modification_result.dart';
import '../models/sticker_policy.dart';
import '../models/student_profile.dart';
import '../services/ai_teacher_repository.dart';

class DailyPlanProvider extends ChangeNotifier {
  DailyPlanProvider(this._repository);

  final AiTeacherRepository _repository;

  DailyPlanResponse? _plan;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  ModificationResult? _lastModificationResult;
  StudentCondition? _selectedCondition;

  DailyPlanResponse? get plan => _plan;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ModificationResult? get lastModificationResult => _lastModificationResult;
  String get studentName => _repository.studentName;
  int get streakDays => _repository.streakDays;
  double get weeklyAchievementRate => _repository.weeklyAchievementRate;
  List<ExamInfo> get exams => _repository.exams;
  List<SubjectLevel> get subjectLevels => _repository.subjectLevels;
  StickerPolicy get stickerPolicy => _repository.stickerPolicy;
  AllowancePolicy get allowancePolicy => _repository.allowancePolicy;
  StudentCondition? get selectedCondition => _selectedCondition;

  Future<void> loadPlanFor(DateTime date, {StudentCondition? condition}) async {
    _selectedDate = date;
    if (condition != null) _selectedCondition = condition;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _plan = await _repository.createDailyPlan(date: date, condition: _selectedCondition);
    } catch (e) {
      _error = '오늘의 학습 플랜을 불러오지 못했어요.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ModificationResult> requestModification({
    required String planItemId,
    required ModificationReason reason,
    String? freeText,
  }) async {
    final result = await _repository.requestModification(
      ModificationRequest(planItemId: planItemId, reason: reason, freeText: freeText),
    );
    _lastModificationResult = result;

    if (_plan != null) {
      if (result.status == ModificationStatus.applied && result.updatedItem != null) {
        final updatedItems = _plan!.dailyPlans
            .map((item) => item.id == planItemId ? result.updatedItem! : item)
            .toList();
        _plan = _plan!.copyWithPlans(updatedItems);
      } else if (result.status == ModificationStatus.removed) {
        final updatedItems = _plan!.dailyPlans.where((item) => item.id != planItemId).toList();
        _plan = _plan!.copyWithPlans(updatedItems);
      }
    }
    notifyListeners();
    return result;
  }
}
