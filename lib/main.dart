import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/daily_plan_provider.dart';
import 'providers/daily_review_provider.dart';
import 'services/ai_teacher_repository.dart';
import 'services/mock/mock_ai_teacher_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const TwinplaneRoot());
}

class TwinplaneRoot extends StatelessWidget {
  const TwinplaneRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AiTeacherRepository>(create: (_) => MockAiTeacherRepository()),
        ChangeNotifierProvider<DailyPlanProvider>(
          create: (context) => DailyPlanProvider(context.read<AiTeacherRepository>()),
        ),
        ChangeNotifierProvider<DailyReviewProvider>(
          create: (context) => DailyReviewProvider(context.read<AiTeacherRepository>()),
        ),
      ],
      child: const TwinplaneApp(),
    );
  }
}
