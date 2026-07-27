import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/parent_settings.dart';
import '../models/student_profile.dart';
import '../providers/daily_plan_provider.dart';
import '../theme/app_colors.dart';

/// The 마이 (My) tab: a read-only profile/settings view built from the same
/// fixed dataset the rest of the app already uses -- the student's own
/// learning preferences, plus the parent-controlled settings shown
/// transparently (never editable by the student, per spec section 10's
/// "부모는 백그라운드에서 관리한다" principle).
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<DailyPlanProvider>(
        builder: (context, planProvider, _) {
          final student = planProvider.studentProfile;
          final parentSettings = planProvider.parentSettings;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _ProfileHeader(student: student, streakDays: planProvider.streakDays),
              const SizedBox(height: 16),
              _SectionCard(
                title: '학습 설정',
                icon: Icons.schedule_rounded,
                rows: [
                  ('기상 시간', student.wakeUpTime),
                  ('취침 시간', student.bedTime),
                  ('선호 학습 시작 시간', student.preferredStudyStartTime),
                  ('최대 자기주도 학습시간', '${student.maxSelfStudyMinutes}분'),
                  ('최대 집중 시간', '${student.maxConcentrationMinutes}분'),
                ],
              ),
              const SizedBox(height: 14),
              _ParentSettingsCard(settings: parentSettings),
              const SizedBox(height: 14),
              const _AppInfoCard(),
            ],
          );
        },
      ),
    );
  }
}

String _gradeLabel(String gradeLevel) {
  final parts = gradeLevel.split('_');
  if (parts.length != 2) return gradeLevel;
  final grade = parts[1];
  return switch (parts[0]) {
    'ELEM' => '초등학교 $grade학년',
    'MIDDLE' => '중학교 $grade학년',
    'HIGH' => '고등학교 $grade학년',
    _ => gradeLevel,
  };
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.student, required this.streakDays});

  final StudentProfile student;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              student.name.isNotEmpty ? student.name.substring(0, 1) : '?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(_gradeLabel(student.gradeLevel), style: const TextStyle(fontSize: 12.5, color: AppColors.gray)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.orangeBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, size: 14, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text('$streakDays일 연속 학습', style: const TextStyle(fontSize: 11.5, color: AppColors.orange, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.rows});

  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in rows) _row(row.$1, row.$2),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _ParentSettingsCard extends StatelessWidget {
  const _ParentSettingsCard({required this.settings});

  final ParentSettings settings;

  @override
  Widget build(BuildContext context) {
    final toggles = <(String, bool)>[
      ('AI 자동 계획 조정', settings.allowPlanAutoAdjustment),
      ('학생의 시간 변경 요청', settings.allowStudentTimeChange),
      ('학생의 분량 변경 요청', settings.allowStudentQuantityChange),
      ('필수 계획 삭제 시 승인 필요', settings.requireParentApprovalForRequiredPlanDeletion),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('보호자 설정', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.grayBg, borderRadius: BorderRadius.circular(20)),
                child: const Text('읽기 전용', style: TextStyle(fontSize: 10.5, color: AppColors.gray, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Text('일일 최대 학습시간', style: TextStyle(fontSize: 13, color: AppColors.gray)),
                const Spacer(),
                Text('${settings.maxDailyStudyMinutes}분', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          for (final toggle in toggles)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(toggle.$1, style: const TextStyle(fontSize: 13))),
                  Icon(
                    toggle.$2 ? Icons.check_circle : Icons.cancel_outlined,
                    size: 18,
                    color: toggle.$2 ? AppColors.greenText : AppColors.gray,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.gray),
            title: Text('앱 버전', style: TextStyle(fontSize: 13.5)),
            trailing: Text('1.0.0 (Mock)', style: TextStyle(fontSize: 13, color: AppColors.gray)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.gray),
            title: const Text('로그아웃', style: TextStyle(fontSize: 13.5)),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('준비 중이에요.'))),
          ),
        ],
      ),
    );
  }
}
