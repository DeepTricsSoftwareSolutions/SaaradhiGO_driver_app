
/// FAANG-Standard Kalman Filter for Flutter.
/// Ensures the vehicle marker doesn't jump in low GPS accuracy zones.
class KalmanFilter {
  double _lastEstPosition = 0;
  double _lastEstError = 1;
  final double _processNoise = 0.008;
  final double _measurementNoise = 0.1;

  double filter(double measurement) {
    double priorEst = _lastEstPosition;
    double priorError = _lastEstError + _processNoise;

    double gain = priorError / (priorError + _measurementNoise);
    double currentEst = priorEst + gain * (measurement - priorEst);
    double currentError = (1 - gain) * priorError;

    _lastEstPosition = currentEst;
    _lastEstError = currentError;

    return currentEst;
  }
}

/// Adaptive Location Logic for Battery Optimization.
int getAdaptivePingInterval(double speedKmph) {
  if (speedKmph == 0) return 30000; // 30s
  if (speedKmph < 10) return 10000; // 10s
  return 2000; // 2s high freq
}
