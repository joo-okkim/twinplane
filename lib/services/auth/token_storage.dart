import 'package:shared_preferences/shared_preferences.dart';

/// Persists the logged-in student's auth token across app restarts. Plain
/// bearer token in shared_preferences (not a cookie) -- see
/// docs/API_CONTRACT.md's Auth section for why.
class TokenStorage {
  TokenStorage._();

  static const _tokenKey = 'auth_token';
  static const _studentIdKey = 'auth_student_id';
  static const _nameKey = 'auth_student_name';

  static Future<void> save({required String token, required int studentId, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_studentIdKey, studentId);
    await prefs.setString(_nameKey, name);
  }

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_studentIdKey);
    await prefs.remove(_nameKey);
  }
}
