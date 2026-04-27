/// App-wide constants — change these for your environment
class AppConstants {
  AppConstants._();

  // ── Backend URLs ───────────────────────────────────────────────────────────
  /// REST API base URL (without trailing slash)
  ///
  /// Override at build/run time with:
  /// - `--dart-define=API_URL=https://dev.api.saaradhigo.in`
  /// - `--dart-define=API_URL=http://10.0.2.2:8000` (Android emulator -> host)
  /// - `--dart-define=API_URL=http://<your-lan-ip>:8000` (physical device -> host)
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    // Server mounts routes under /api and /api/v1. Default to /api.
    defaultValue: 'https://dev.api.saaradhigo.in/api',
  );

  /// WebSocket server URL
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://dev.api.saaradhigo.in',
  );

  /// If true, auth will fall back to a demo OTP when backend is unreachable.
  /// Keep this OFF when you want strict end-to-end backend testing.
  static const bool allowDemoOtp = bool.fromEnvironment(
    'ALLOW_DEMO_OTP',
    defaultValue: false,
  );

  // ── Timing ────────────────────────────────────────────────────────────────
  /// How long a ride request is visible before expiring (seconds)
  static const int rideRequestTimeoutSeconds = 30;

  /// GPS update interval (milliseconds)
  static const int locationIntervalMs = 3000;

  /// Rider no-show auto-cancel timer (minutes)
  static const int noShowCancelMinutes = 5;

  // ── Fare Config ───────────────────────────────────────────────────────────
  static const double baseFare = 30.0;
  static const double perKmRate = 14.0;
  static const double perMinRate = 1.5;
  static const double commissionPercent = 20.0; // 20% platform cut

  // ── Safety ────────────────────────────────────────────────────────────────
  static const double maxSpeedKmh = 250.0; // GPS spoof detection threshold
  static const double minGpsAccuracyMeters = 100.0;

  // ── Storage Keys ─────────────────────────────────────────────────────────
  static const String keyJwtToken = 'jwt_token';
  static const String keyDriverId = 'driver_id';
  static const String keyUserId = 'user_id';
  static const String keyOnboardingDone = 'onboarding_done';

  // ── App Meta ──────────────────────────────────────────────────────────────
  static const String appName = 'SaaradhiGO Driver';
  static const String appVersion = '1.0.0';
  static const String supportPhone = '+91-9000000000';
  static const String supportEmail = 'support@saaradhigo.com';
}
