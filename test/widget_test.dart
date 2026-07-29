import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:twinplane/screens/twinplane_root.dart';
import 'package:twinplane/services/mock/mock_ai_teacher_repository.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  testWidgets('Home tab shows the AI hero card and progress dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: TwinplaneRoot(repository: MockAiTeacherRepository())));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('오늘 계획 시작하기'), findsOneWidget);
    expect(find.text('오늘의 진행률'), findsOneWidget);
  });

  testWidgets('Plan tab loads the mock daily plan', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: TwinplaneRoot(repository: MockAiTeacherRepository())));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('학습'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('오늘의 AI 학습 플랜'), findsOneWidget);
    expect(find.text('AI 다시 추천'), findsOneWidget);
  });
}
