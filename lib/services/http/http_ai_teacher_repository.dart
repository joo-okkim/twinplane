import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/allowance_policy.dart';
import '../../models/daily_plan_response.dart';
import '../../models/daily_review_request.dart';
import '../../models/daily_review_response.dart';
import '../../models/exam_info.dart';
import '../../models/incomplete_plan.dart';
import '../../models/modification_request.dart';
import '../../models/modification_result.dart';
import '../../models/parent_settings.dart';
import '../../models/recent_performance.dart';
import '../../models/sticker_policy.dart';
import '../../models/student_profile.dart';
import '../ai_teacher_repository.dart';

/// Talks to the real Node/LLM-backed AI Teacher API. Endpoint paths and JSON
/// shapes here MUST match docs/API_CONTRACT.md -- that file is the source of
/// truth shared with the backend team; update both together.
///
/// [initialize] fetches and caches the student's profile and policies once
/// (they rarely change within a session); [createDailyPlan] /
/// [requestModification] / [submitDailyReview] hit the server on every call
/// since their results depend on that day's state.
class HttpAiTeacherRepository implements AiTeacherRepository {
  HttpAiTeacherRepository({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  StudentProfile? _studentProfile;
  RecentPerformance? _recentPerformance;
  List<ExamInfo> _exams = const [];
  List<SubjectLevel> _subjectLevels = const [];
  StickerPolicy? _stickerPolicy;
  AllowancePolicy? _allowancePolicy;
  ParentSettings? _parentSettings;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, dynamic> _decodeObject(http.Response response, String path) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('GET $path failed with ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<dynamic> _decodeArray(http.Response response, String path) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('GET $path failed with ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  @override
  Future<void> initialize() async {
    final results = await Future.wait([
      _client.get(_uri('/api/student/profile')),
      _client.get(_uri('/api/student/subject-levels')),
      _client.get(_uri('/api/student/exams')),
      _client.get(_uri('/api/student/performance')),
      _client.get(_uri('/api/parent/settings')),
      _client.get(_uri('/api/policy/sticker')),
      _client.get(_uri('/api/policy/allowance')),
    ]);

    _studentProfile = StudentProfile.fromJson(_decodeObject(results[0], '/api/student/profile'));
    _subjectLevels = _decodeArray(results[1], '/api/student/subject-levels')
        .map((e) => SubjectLevel.fromJson(e as Map<String, dynamic>))
        .toList();
    _exams =
        _decodeArray(results[2], '/api/student/exams').map((e) => ExamInfo.fromJson(e as Map<String, dynamic>)).toList();
    _recentPerformance = RecentPerformance.fromJson(_decodeObject(results[3], '/api/student/performance'));
    _parentSettings = ParentSettings.fromJson(_decodeObject(results[4], '/api/parent/settings'));
    _stickerPolicy = StickerPolicy.fromJson(_decodeObject(results[5], '/api/policy/sticker'));
    _allowancePolicy = AllowancePolicy.fromJson(_decodeObject(results[6], '/api/policy/allowance'));
  }

  StudentProfile get _profileOrThrow =>
      _studentProfile ?? (throw StateError('HttpAiTeacherRepository.initialize() was not awaited before use.'));
  RecentPerformance get _performanceOrThrow =>
      _recentPerformance ?? (throw StateError('HttpAiTeacherRepository.initialize() was not awaited before use.'));

  @override
  String get studentName => _profileOrThrow.name;

  @override
  int get streakDays => _performanceOrThrow.consecutiveCompletionDays;

  @override
  double get weeklyAchievementRate => _performanceOrThrow.weeklyAchievementRate;

  @override
  List<ExamInfo> get exams => _exams;

  @override
  List<SubjectLevel> get subjectLevels => _subjectLevels;

  @override
  StickerPolicy get stickerPolicy =>
      _stickerPolicy ?? (throw StateError('HttpAiTeacherRepository.initialize() was not awaited before use.'));

  @override
  AllowancePolicy get allowancePolicy =>
      _allowancePolicy ?? (throw StateError('HttpAiTeacherRepository.initialize() was not awaited before use.'));

  @override
  StudentProfile get studentProfile => _profileOrThrow;

  @override
  ParentSettings get parentSettings =>
      _parentSettings ?? (throw StateError('HttpAiTeacherRepository.initialize() was not awaited before use.'));

  String _dateStr(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Future<DailyPlanResponse> createDailyPlan({
    required DateTime date,
    List<IncompletePlan> carryOver = const [],
    StudentCondition? condition,
  }) async {
    final response = await _client.post(
      _uri('/api/plans/daily'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': _dateStr(date),
        if (condition != null) 'condition': condition.wireValue,
      }),
    );
    return DailyPlanResponse.fromJson(_decodeObject(response, '/api/plans/daily'));
  }

  @override
  Future<ModificationResult> requestModification(ModificationRequest request) async {
    final response = await _client.post(
      _uri('/api/plans/modify'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    return ModificationResult.fromJson(_decodeObject(response, '/api/plans/modify'));
  }

  @override
  Future<DailyReviewResponse> submitDailyReview({
    required DateTime date,
    required List<PlanItemCompletion> completions,
  }) async {
    final response = await _client.post(
      _uri('/api/reviews/daily'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': _dateStr(date),
        'completions': completions.map((c) => c.toJson()).toList(),
      }),
    );
    return DailyReviewResponse.fromJson(_decodeObject(response, '/api/reviews/daily'));
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}
