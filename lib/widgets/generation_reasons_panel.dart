import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GenerationReasonsPanel extends StatelessWidget {
  const GenerationReasonsPanel({super.key, required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('왜 이렇게 계획했나요?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          leading: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          children: reasons
              .map((reason) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.circle, size: 5, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(reason, style: const TextStyle(fontSize: 12.5, height: 1.4))),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
