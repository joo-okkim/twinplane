import 'package:flutter/material.dart';

import '../models/plan_item.dart';
import '../theme/app_colors.dart';

String formatDuration(int minutes) => '$minutes분';

String formatTimeRange(String start, String end) => '$start - $end';

String difficultyLabel(Difficulty difficulty) => switch (difficulty) {
      Difficulty.easy => '쉬움',
      Difficulty.normal => '보통',
      Difficulty.hard => '어려움',
    };

Color difficultyColor(Difficulty difficulty) => switch (difficulty) {
      Difficulty.easy => Colors.green,
      Difficulty.normal => Colors.blue,
      Difficulty.hard => Colors.deepOrange,
    };

BadgeStyle difficultyBadgeStyle(Difficulty difficulty) => switch (difficulty) {
      Difficulty.easy => const BadgeStyle(AppColors.greenBg, AppColors.greenText),
      Difficulty.normal => const BadgeStyle(AppColors.blueBg, AppColors.blue),
      Difficulty.hard => const BadgeStyle(AppColors.coralBg, AppColors.coral),
    };

String planTypeLabel(PlanType type) => switch (type) {
      PlanType.required => '필수',
      PlanType.recommended => '권장',
      PlanType.optional => '선택',
      PlanType.bonus => '보너스',
      PlanType.routine => '생활습관',
      PlanType.breakTime => '휴식',
      PlanType.fixed => '고정 일정',
    };

BadgeStyle planTypeBadgeStyle(PlanType type) => switch (type) {
      PlanType.required => const BadgeStyle(AppColors.primaryLight, AppColors.primary),
      PlanType.recommended => const BadgeStyle(AppColors.greenBg, AppColors.greenText),
      PlanType.optional => const BadgeStyle(AppColors.blueBg, AppColors.blue),
      PlanType.bonus => const BadgeStyle(AppColors.orangeBg, AppColors.orange),
      PlanType.routine => const BadgeStyle(AppColors.grayBg, AppColors.gray),
      PlanType.breakTime => const BadgeStyle(AppColors.tealBg, AppColors.teal),
      PlanType.fixed => const BadgeStyle(AppColors.grayBg, AppColors.gray),
    };

/// Icon + tint shown in each timeline row's leading icon box, guessed from
/// the item's subject/title so fixed schedules and study items get a
/// recognizable glyph without needing bundled illustration assets.
(IconData, Color, Color) planItemVisual(PlanItem item) {
  if (item.planType == PlanType.breakTime) {
    return (Icons.local_cafe_outlined, AppColors.tealBg, AppColors.teal);
  }
  if (item.planType == PlanType.fixed) {
    final title = item.title;
    if (title.contains('학교')) {
      return (Icons.school, AppColors.primaryLight, AppColors.primary);
    }
    if (title.contains('학원')) {
      return (Icons.menu_book_outlined, AppColors.grayBg, AppColors.gray);
    }
    if (title.contains('식사')) {
      return (Icons.restaurant_outlined, AppColors.grayBg, AppColors.gray);
    }
    return (Icons.event_outlined, AppColors.grayBg, AppColors.gray);
  }
  final subject = item.subject ?? '';
  if (subject.contains('수학')) {
    return (Icons.calculate_outlined, AppColors.primaryLight, AppColors.primary);
  }
  if (subject.contains('영어')) {
    return (Icons.menu_book_outlined, AppColors.blueBg, AppColors.blue);
  }
  if (subject.contains('과학')) {
    return (Icons.science_outlined, AppColors.greenBg, AppColors.greenText);
  }
  return (Icons.edit_note_outlined, AppColors.grayBg, AppColors.gray);
}
