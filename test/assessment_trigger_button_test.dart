import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:twinplane/providers/daily_plan_provider.dart';
import 'package:twinplane/providers/daily_review_provider.dart';
import 'package:twinplane/screens/twinplane_root.dart';
import 'package:twinplane/services/mock/mock_ai_teacher_repository.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  testWidgets('이해도 확인 button only appears once its evidence-required item is completed', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(TwinplaneRoot(repository: MockAiTeacherRepository()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('학습'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The seeded 수학 assignment ("유형 문제집 42~45쪽") is the only item with
    // evidenceRequired: true (see mock_student_data.dart) -- the button must
    // not appear before it's marked complete.
    expect(find.text('이해도 확인'), findsNothing);

    final context = tester.element(find.text('오늘의 AI 학습 플랜'));
    final planProvider = Provider.of<DailyPlanProvider>(context, listen: false);
    final reviewProvider = Provider.of<DailyReviewProvider>(context, listen: false);
    final evidenceItem = planProvider.plan!.dailyPlans.firstWhere((p) => p.evidenceRequired);

    reviewProvider.toggleCompleted(evidenceItem.id);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('이해도 확인'), findsOneWidget);

    // Completing a different, non-evidence-required item must not also
    // surface the button.
    final otherItem = planProvider.plan!.dailyPlans.firstWhere((p) => p.rewardEligible && !p.evidenceRequired);
    reviewProvider.toggleCompleted(otherItem.id);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('이해도 확인'), findsOneWidget);
  });
}
