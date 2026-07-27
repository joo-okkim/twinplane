/// Runtime switches for choosing between the mock data layer and the real
/// Node backend, set via --dart-define at build/run time so no code change
/// is needed to point the app at a live server.
///
/// Examples:
///   flutter run                                              (mock, default)
///   flutter run --dart-define=USE_MOCK=false \
///     --dart-define=API_BASE_URL=https://api.example.com     (real backend)
class AppConfig {
  AppConfig._();

  static const bool useMockBackend = bool.fromEnvironment('USE_MOCK', defaultValue: true);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );
}
