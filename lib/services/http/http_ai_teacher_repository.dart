import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/allowance_policy.dart';
import '../../models/assessment_generate_request.dart';
import '../../models/assessment_generate_response.dart';
import '../../models/assessment_submit_request.dart';
import '../../models/assessment_submit_response.dart';
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
/// Every request carries `Authorization: Bearer $token` -- [token] is
/// obtained via a separate login step (see `lib/services/auth/`) before
/// this repository is constructed. [initialize] fetches and caches the
/// student's profile and policies once (they rarely change within a
/// session); [createDailyPlan] / [requestModification] / [submitDailyReview]
/// hit the server on every call since their results depend on that day's
/// state.
class HttpAiTeacherRepository implements AiTeacherRepository {
  HttpAiTeacherRepository({required this.baseUrl, required this.token, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _client;

  StudentProfile? _studentProfile;
  RecentPerformance? _recentPerformance;
  List<ExamInfo> _exams = const [];
  List<SubjectLevel> _subjectLevels = const [];
  StickerPolicy? _stickerPolicy;
  AllowancePolicy? _allowancePolicy;
  ParentSettings? _parentSettings;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

  Map<String, dynamic> _decodeObject(http.Response response, String path) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('GET $path failed with ${response.statusCode}: ${response.body}', statusCode: response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<dynamic> _decodeArray(http.Response response, String path) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('GET $path failed with ${response.statusCode}: ${response.body}', statusCode: response.statusCode);
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  @override
  Future<void> initialize() async {
    final results = await Future.wait([
      _client.get(_uri('/api/student/profile'), headers: _headers),
      _client.get(_uri('/api/student/subject-levels'), headers: _headers),
      _client.get(_uri('/api/student/exams'), headers: _headers),
      _client.get(_uri('/api/student/performance'), headers: _headers),
      _client.get(_uri('/api/parent/settings'), headers: _headers),
      _client.get(_uri('/api/policy/sticker'), headers: _headers),
      _client.get(_uri('/api/policy/allowance'), headers: _headers),
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
      headers: _headers,
      body: jsonEncode({
        'date': _dateStr(date),
        if (condition != null) 'condition': condition.wireValue,
      }),
    );
    return DailyPlanResponse.fromJson(_decodeObject(response, '/api/plans/daily'));
  }

  @override
  Future<ModificationResult> requestModification(ModificationRequest request) async {
    final response = await _client.post(_uri('/api/plans/modify'), headers: _headers, body: jsonEncode(request.toJson()));
    return ModificationResult.fromJson(_decodeObject(response, '/api/plans/modify'));
  }

  @override
  Future<DailyReviewResponse> submitDailyReview({
    required DateTime date,
    required List<PlanItemCompletion> completions,
  }) async {
    final response = await _client.post(
      _uri('/api/reviews/daily'),
      headers: _headers,
      body: jsonEncode({
        'date': _dateStr(date),
        'completions': completions.map((c) => c.toJson()).toList(),
      }),
    );
    return DailyReviewResponse.fromJson(_decodeObject(response, '/api/reviews/daily'));
  }

  @override
  Future<AssessmentGenerateResponse> generateAssessment(AssessmentGenerateRequest request) async {
    final response = await _client.post(
      _uri('/api/assessments/generate'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );
    return AssessmentGenerateResponse.fromJson(_decodeObject(response, '/api/assessments/generate'));
  }

  @override
  Future<AssessmentSubmitResponse> submitAssessment(AssessmentSubmitRequest request) async {
    final path = '/api/assessments/${request.assessmentId}/submit';
    final response = await _client.post(_uri(path), headers: _headers, body: jsonEncode(request.toJson()));
    return AssessmentSubmitResponse.fromJson(_decodeObject(response, path));
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException: $message';
}
