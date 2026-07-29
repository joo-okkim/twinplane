import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/assessment_question.dart';
import '../providers/assessment_provider.dart';
import '../theme/app_colors.dart';
import 'assessment_result_screen.dart';

/// 이해도 확인 (comprehension check) quiz screen for a completed,
/// evidence-required plan item. Generates on entry, lets the student answer,
/// then submits for grading and pushes [AssessmentResultScreen].
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key, required this.planItemId});

  final String planItemId;

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AssessmentProvider>();
      provider.reset();
      provider.generate(widget.planItemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('이해도 확인')),
      body: SafeArea(
        child: Consumer<AssessmentProvider>(
          builder: (context, provider, _) {
            switch (provider.phase) {
              case AssessmentPhase.idle:
              case AssessmentPhase.generating:
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('AI가 문제를 만들고 있어요...', style: TextStyle(color: AppColors.gray)),
                    ],
                  ),
                );
              case AssessmentPhase.error:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(provider.error ?? '문제가 발생했어요.', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => provider.generate(widget.planItemId),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                );
              case AssessmentPhase.answering:
              case AssessmentPhase.submitting:
                return _AnsweringBody(provider: provider, planItemId: widget.planItemId);
              case AssessmentPhase.result:
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  Navigator.of(context)
                      .pushReplacement(MaterialPageRoute(builder: (_) => AssessmentResultScreen(result: provider.result!)));
                });
                return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

class _AnsweringBody extends StatelessWidget {
  const _AnsweringBody({required this.provider, required this.planItemId});

  final AssessmentProvider provider;
  final String planItemId;

  @override
  Widget build(BuildContext context) {
    final assessment = provider.assessment!;
    final submitting = provider.phase == AssessmentPhase.submitting;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  '${assessment.subject} · ${assessment.scope}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              for (final q in assessment.questions) _QuestionCard(question: q, provider: provider),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              onPressed: provider.allAnswered && !submitting ? () => provider.submit() : null,
              child: submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('채점하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.provider});

  final AssessmentQuestion question;
  final AssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${question.sequence}. ${question.question}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          const SizedBox(height: 12),
          if (question.type == AssessmentQuestionType.multipleChoice)
            for (final choice in question.choices) _ChoiceOption(question: question, choice: choice, provider: provider)
          else
            TextField(
              decoration: const InputDecoration(
                hintText: '답을 입력해주세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              minLines: 1,
              maxLines: 3,
              onChanged: (value) => provider.setAnswer(question.id, value),
            ),
        ],
      ),
    );
  }
}

class _ChoiceOption extends StatelessWidget {
  const _ChoiceOption({required this.question, required this.choice, required this.provider});

  final AssessmentQuestion question;
  final String choice;
  final AssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final selected = provider.draftAnswerFor(question.id) == choice;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => provider.setAnswer(question.id, choice),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.grayBg,
            borderRadius: BorderRadius.circular(12),
            border: selected ? Border.all(color: AppColors.primary, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? AppColors.primary : AppColors.gray,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(choice, style: const TextStyle(fontSize: 13.5))),
            ],
          ),
        ),
      ),
    );
  }
}
