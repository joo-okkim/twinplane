import 'package:flutter/material.dart';

import '../models/daily_review_response.dart';

class SubjectResultCard extends StatelessWidget {
  const SubjectResultCard({super.key, required this.result});

  final SubjectResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(result.subject, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(result.analysis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${result.achievementRate}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${result.actualMinutes}/${result.plannedMinutes}분', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
