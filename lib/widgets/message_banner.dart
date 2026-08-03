import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MessageBanner extends StatelessWidget {
  const MessageBanner({super.key, required this.title, required this.message, required this.tone});

  final String title;
  final String message;
  final String tone;

  @override
  Widget build(BuildContext context) {
    final (bg, border, accent) = switch (tone) {
      'encouraging' => (AppColors.greenBg, AppColors.isDark ? const Color(0xFF265C40) : const Color(0xFFBFE8CE), AppColors.greenText),
      'concerned' => (AppColors.orangeBg, AppColors.isDark ? const Color(0xFF6B4A1E) : const Color(0xFFF6D5A8), AppColors.orange),
      _ => (AppColors.blueBg, AppColors.isDark ? const Color(0xFF2C4770) : const Color(0xFFBFDBFE), AppColors.blue),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: const Center(
              child: Text('AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent)),
                const SizedBox(height: 6),
                Text(message, style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.6), shape: BoxShape.circle),
            child: Icon(Icons.smart_toy_outlined, color: accent, size: 24),
          ),
        ],
      ),
    );
  }
}
