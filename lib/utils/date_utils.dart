import 'package:intl/intl.dart';

String formatKoreanDate(DateTime date) => DateFormat('M월 d일 EEEE', 'ko_KR').format(date);
