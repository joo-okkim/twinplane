import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of a successful login (POST /api/auth/login) -- see
/// docs/API_CONTRACT.md.
class LoginResult {
  const LoginResult({required this.token, required this.studentId, required this.name});

  final String token;
  final int studentId;
  final String name;
}

class AuthException implements Exception {
  AuthException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'AuthException: $message';
}

/// Thin client for the one unauthenticated endpoint
/// (POST /api/auth/login) -- every other call goes through
/// HttpAiTeacherRepository once a token is obtained.
class AuthClient {
  AuthClient({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<LoginResult> login(String username, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = '로그인에 실패했어요.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['error'] is String) message = body['error'] as String;
      } catch (_) {
        // response body wasn't JSON; fall back to the generic message above.
      }
      throw AuthException(message, statusCode: response.statusCode);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult(
      token: json['token'] as String,
      studentId: json['studentId'] as int,
      name: json['name'] as String,
    );
  }
}
