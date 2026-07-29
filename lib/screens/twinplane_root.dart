import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/daily_plan_provider.dart';
import '../providers/daily_review_provider.dart';
import '../services/ai_teacher_repository.dart';
import 'main_shell.dart';

/// Wires a given [repository] into the provider tree and shows the app's
/// tab shell. Used by [AuthGate] once a repository is ready (mock mode, or
/// a successful login + initialize), and directly by widget tests that
/// need to inject a specific repository/dataset without going through the
/// login flow.
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
      child: const MainShell(),
    );
  }
}
