import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:twinplane/models/student_dataset.dart';
import 'package:twinplane/models/student_profile.dart';
import 'package:twinplane/screens/twinplane_root.dart';
import 'package:twinplane/services/mock/mock_ai_teacher_repository.dart';
import 'package:twinplane/services/mock/mock_student_data.dart';

StudentDataset _datasetWithCondition(StudentCondition condition) {
  final base = MockStudentData.dataset;
  return StudentDataset(
    student: StudentProfile(
      studentId: base.student.studentId,
      name: base.student.name,
      gradeLevel: base.student.gradeLevel,
      wakeUpTime: base.student.wakeUpTime,
      bedTime: base.student.bedTime,
      preferredStudyStartTime: base.student.preferredStudyStartTime,
      maxSelfStudyMinutes: base.student.maxSelfStudyMinutes,
      maxConcentrationMinutes: base.student.maxConcentrationMinutes,
      condition: condition,
      conditionMemo: base.student.conditionMemo,
    ),
    subjectLevels: base.subjectLevels,
    fixedSchedules: base.fixedSchedules,
    assignments: base.assignments,
    incompletePlans: base.incompletePlans,
    exams: base.exams,
    recentPerformance: base.recentPerformance,
    parentSettings: base.parentSettings,
    stickerPolicy: base.stickerPolicy,
    allowancePolicy: base.allowancePolicy,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  testWidgets('parent-attention banner is hidden for a normal condition', (WidgetTester tester) async {
    await tester.pumpWidget(
      TwinplaneRoot(repository: MockAiTeacherRepository(dataset: _datasetWithCondition(StudentCondition.normal))),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('학습'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('보호자 확인이 필요해요'), findsNothing);
  });

  testWidgets('parent-attention banner shows plan summary/attention items when the backend flags approval', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TwinplaneRoot(repository: MockAiTeacherRepository(dataset: _datasetWithCondition(StudentCondition.sick))),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('학습'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('보호자 확인이 필요해요'), findsOneWidget);
  });
}