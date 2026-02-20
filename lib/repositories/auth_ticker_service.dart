// services/auth_ticker.dart
import 'dart:async';
import '../customization/config.dart';

/// Ticker service that emits seed updates every 30 seconds for code generation.
/// Manages timer lifecycle to prevent memory leaks.
class AuthTicker {
  final StreamController<int> _seedController = StreamController.broadcast();
  Timer? _periodic;
  Timer? _initialTimer;
  bool _isDisposed = false;

  Stream<int> get seedStream => _seedController.stream;

  /// Whether the ticker has been disposed
  bool get isDisposed => _isDisposed;

  void start() {
    if (_isDisposed) return;

    // Cancel any existing timers
    _periodic?.cancel();
    _initialTimer?.cancel();

    final now = DateTime.now().millisecondsSinceEpoch;
    final timeUntilNextMultiple =
        Config.intervalMillis - (now % Config.intervalMillis);
    _emitNextSeed();

    // Fire first after the delay
    _initialTimer = Timer(Duration(milliseconds: timeUntilNextMultiple), () {
      if (_isDisposed) return;
      _emitNextSeed();
      _periodic =
          Timer.periodic(Duration(milliseconds: Config.intervalMillis), (_) {
        if (_isDisposed) return;
        _emitNextSeed();
      });
    });
  }

  void _emitNextSeed() {
    if (_isDisposed || _seedController.isClosed) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeUntilNextMultiple =
        Config.intervalMillis - (now % Config.intervalMillis);
    final seed = now + timeUntilNextMultiple;
    _seedController.add(seed);
  }

  void restart() {
    start();
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _periodic?.cancel();
    _periodic = null;
    _initialTimer?.cancel();
    _initialTimer = null;
    _seedController.close();
  }
}
