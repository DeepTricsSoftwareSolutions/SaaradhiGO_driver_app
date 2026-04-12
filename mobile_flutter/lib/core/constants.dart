/// App-wide constants — change these for your environment
class AppConstants {
  AppConstants._();

  // ── Backend URLs ───────────────────────────────────────────────────────────
  /// REST API base URL (without trailing slash)
  static const String apiUrl = 'https://dev.api.saaradhigo.in';

  /// WebSocket server URL
  static const String wsUrl = 'wss://dev.api.saaradhigo.in';

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
