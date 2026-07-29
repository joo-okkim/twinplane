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
    await tester.pumpWidget(TwinplaneRoot(repository: MockAiTeacherRepository()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('오늘 계획 시작하기'), findsOneWidget);
    expect(find.text('오늘의 진행률'), findsOneWidget);
  });

  testWidgets('Plan tab loads the mock daily plan', (WidgetTester tester) async {
    await tester.pumpWidget(TwinplaneRoot(repository: MockAiTeacherRepository()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('학습'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('오늘의 AI 학습 플랜'), findsOneWidget);
    expect(find.text('AI 다시 추천'), findsOneWidget);
  });

  testWidgets('opening the modify-request sheet finds DailyPlanProvider without throwing', (
    WidgetTester tester,
  ) async {
    // Regression test: the modal bottom sheet is inserted into the
    // Navigator's Overlay, which only inherits providers declared *above*
    // MaterialApp -- a provider tree nested *inside* MaterialApp's home
    // route (as an earlier version of AuthGate/TwinplaneRoot had it) throws
    // "Could not find the correct Provider<DailyPlanProvider>" here.
    //
    // A tall virtual screen keeps every plan item on-screen without
    // scrolling, since the item that first exposes the bug (an adjustable
    // required item) isn't always the first one rendered.
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(TwinplaneRoot(repository: MockAiTeacherRepository()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('학습'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byIcon(Icons.more_vert), findsWidgets);
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('어떤 점이 힘든가요?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My tab hides the logout row when there is no session to log out of (mock mode)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(TwinplaneRoot(repository: MockAiTeacherRepository()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('로그아웃'), findsNothing);
  });

  testWidgets('My tab shows a working logout row when a real session exists', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var loggedOut = false;
    await tester.pumpWidget(
      TwinplaneRoot(repository: MockAiTeacherRepository(), onLogout: () => loggedOut = true),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('로그아웃'), findsOneWidget);
    await tester.tap(find.text('로그아웃'));

    expect(loggedOut, isTrue);
  });
}
