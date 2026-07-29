import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:twinplane/app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  testWidgets('mock mode (USE_MOCK default) skips login and shows the app directly', (WidgetTester tester) async {
    await tester.pumpWidget(const TwinplaneApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('아이디'), findsNothing);
    expect(find.text('오늘의 진행률'), findsOneWidget);
  });
}
