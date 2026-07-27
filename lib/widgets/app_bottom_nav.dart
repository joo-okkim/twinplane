import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom nav with 4 real tabs (홈/학습/보상/마이) plus a floating "AI 코치"
/// action docked between 보상 and 마이, matching the 메인디자인시안 reference.
/// The AI slot is not a navigable tab -- it always opens the AI quick-action
/// sheet via [onAiTap], regardless of [currentIndex].
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap, required this.onAiTap});

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAiTap;

  static const _tabs = [
    (Icons.home_outlined, '홈'),
    (Icons.menu_book_outlined, '학습'),
    (Icons.card_giftcard_outlined, '보상'),
    (Icons.person_outline, '마이'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0),
            _navItem(1),
            _navItem(2),
            _AiFloatingButton(onTap: onAiTap),
            _navItem(3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index) {
    final (icon, label) = _tabs[index];
    final selected = index == currentIndex;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.gray),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.primary : AppColors.gray,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiFloatingButton extends StatelessWidget {
  const _AiFloatingButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF5B4FE9)],
                ),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(height: 2),
          const Text('AI 코치', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
