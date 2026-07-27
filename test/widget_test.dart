import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:twinplane/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  testWidgets('Today plan screen loads the mock daily plan', (WidgetTester tester) async {
    await tester.pumpWidget(const TwinplaneRoot());

    // Wait for the mock repository's simulated network latency to resolve.
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('오늘의 AI 학습 플랜'), findsOneWidget);
    expect(find.text('AI 다시 추천'), findsOneWidget);
  });
}
