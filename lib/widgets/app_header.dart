import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/date_utils.dart';

/// Shared greeting header used at the top of every tab: date, a
/// screen-specific subtitle, the student's streak badge, and an avatar.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.date,
    required this.studentName,
    required this.streakDays,
    required this.subtitle,
  });

  final DateTime date;
  final String studentName;
  final int streakDays;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatKoreanDate(date), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12.5, color: AppColors.gray)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppColors.orangeBg, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, size: 15, color: AppColors.orange),
              const SizedBox(width: 4),
              Text('$streakDays일 연속', style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            studentName.isNotEmpty ? studentName.substring(0, 1) : '?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
