import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/ai_teacher_repository.dart';
import '../services/auth/auth_client.dart';
import '../services/auth/token_storage.dart';
import '../services/http/http_ai_teacher_repository.dart';
import '../services/mock/mock_ai_teacher_repository.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'twinplane_root.dart';

enum _AuthState { loading, needsLogin, error, ready }

/// Decides what the app shows before any tab/screen can build:
/// - USE_MOCK=true (default): skip auth entirely, exactly like before this
///   feature existed.
/// - USE_MOCK=false: try a saved token first; show [LoginScreen] if none
///   or if it's rejected (401); show a themed retry screen for any other
///   startup failure (server unreachable, etc).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  _AuthState _state = _AuthState.loading;
  AiTeacherRepository? _repository;
  String? _errorMessage;
  late final AuthClient _authClient = AuthClient(baseUrl: AppConfig.apiBaseUrl);

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (AppConfig.useMockBackend) {
      setState(() {
        _repository = MockAiTeacherRepository();
        _state = _AuthState.ready;
      });
      return;
    }

    final token = await TokenStorage.readToken();
    if (token == null) {
      setState(() => _state = _AuthState.needsLogin);
      return;
    }
    await _initializeWithToken(token);
  }

  Future<void> _initializeWithToken(String token) async {
    setState(() => _state = _AuthState.loading);
    final repository = HttpAiTeacherRepository(baseUrl: AppConfig.apiBaseUrl, token: token);
    try {
      await repository.initialize();
      if (!mounted) return;
      setState(() {
        _repository = repository;
        _state = _AuthState.ready;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await TokenStorage.clear();
        setState(() => _state = _AuthState.needsLogin);
      } else {
        setState(() {
          _errorMessage = e.message;
          _state = _AuthState.error;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _state = _AuthState.error;
      });
    }
  }

  Future<void> _onLoggedIn(LoginResult result) async {
    await TokenStorage.save(token: result.token, studentId: result.studentId, name: result.name);
    await _initializeWithToken(result.token);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _AuthState.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _AuthState.needsLogin:
        return LoginScreen(authClient: _authClient, onLoggedIn: _onLoggedIn);
      case _AuthState.error:
        return _StartupErrorScreen(message: _errorMessage ?? '알 수 없는 오류가 발생했어요.', onRetry: _start);
      case _AuthState.ready:
        return TwinplaneRoot(repository: _repository!);
    }
  }
}

/// Shown when USE_MOCK=false but the real API couldn't be reached (or
/// failed for a reason other than an expired/invalid token).
class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('AI Teacher 서버에 연결하지 못했어요', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'API_BASE_URL=${AppConfig.apiBaseUrl}\n$message',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
