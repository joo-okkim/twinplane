import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'providers/daily_plan_provider.dart';
import 'providers/daily_review_provider.dart';
import 'services/ai_teacher_repository.dart';
import 'services/http/http_ai_teacher_repository.dart';
import 'services/mock/mock_ai_teacher_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  final AiTeacherRepository repository = AppConfig.useMockBackend
      ? MockAiTeacherRepository()
      : HttpAiTeacherRepository(baseUrl: AppConfig.apiBaseUrl);

  try {
    await repository.initialize();
  } catch (e) {
    runApp(_StartupErrorApp(error: e.toString()));
    return;
  }

  runApp(TwinplaneRoot(repository: repository));
}

class TwinplaneRoot extends StatelessWidget {
  const TwinplaneRoot({super.key, required this.repository});

  final AiTeacherRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AiTeacherRepository>.value(value: repository),
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

/// Shown when USE_MOCK=false but the real API couldn't be reached during
/// startup -- gives backend-integration testers a clear signal instead of a
/// generic crash.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('AI Teacher 서버에 연결하지 못했어요', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'API_BASE_URL=${AppConfig.apiBaseUrl}\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
