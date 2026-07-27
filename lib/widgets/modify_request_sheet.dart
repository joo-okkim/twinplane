import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/modification_request.dart';
import '../models/modification_result.dart';
import '../providers/daily_plan_provider.dart';

Future<void> showModifyRequestSheet(BuildContext context, {required String planItemId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ModifyRequestSheet(planItemId: planItemId),
  );
}

class _ModifyRequestSheet extends StatefulWidget {
  const _ModifyRequestSheet({required this.planItemId});

  final String planItemId;

  @override
  State<_ModifyRequestSheet> createState() => _ModifyRequestSheetState();
}

class _ModifyRequestSheetState extends State<_ModifyRequestSheet> {
  ModificationReason? _reason;
  final _freeTextController = TextEditingController();
  bool _submitting = false;

  static const _options = [
    (ModificationReason.tired, '힘들어요'),
    (ModificationReason.tooMuch, '너무 많아요'),
    (ModificationReason.wrongTime, '시간이 안 맞아요'),
    (ModificationReason.dontWant, '하기 싫어요'),
  ];

  @override
  void dispose() {
    _freeTextController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _submitting = true);
    final provider = context.read<DailyPlanProvider>();
    final result = await provider.requestModification(
      planItemId: widget.planItemId,
      reason: _reason!,
      freeText: _freeTextController.text.trim().isEmpty ? null : _freeTextController.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    if (result.status == ModificationStatus.parentApprovalRequired) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('부모님 확인이 필요해요'),
          content: Text(result.message),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('어떤 점이 힘든가요?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options
                .map((o) => ChoiceChip(
                      label: Text(o.$2),
                      selected: _reason == o.$1,
                      onSelected: (_) => setState(() => _reason = o.$1),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _freeTextController,
            decoration: const InputDecoration(
              labelText: '자세히 알려줄 수 있어요 (선택)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _reason == null || _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('요청 보내기'),
            ),
          ),
        ],
      ),
    );
  }
}
