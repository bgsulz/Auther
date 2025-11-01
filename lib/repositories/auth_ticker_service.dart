// services/auth_ticker.dart
import 'dart:async';
import '../customization/config.dart';

class AuthTicker {
  final StreamController<int> _seedController = StreamController.broadcast();
  Timer? _periodic;
  int _initialSeed = 0;
  int _offsetCount = 0;

  Stream<int> get seedStream => _seedController.stream;

  void start() {
    _periodic?.cancel();
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeUntilNextMultiple = Config.intervalMillis - (now % Config.intervalMillis);
    _initialSeed = now + timeUntilNextMultiple;
    _offsetCount = 0;
    // Emit the first seed immediately so consumers can render a determinate countdown.
    _seedController.add(_initialSeed);
    // fire first after the delay
    Timer(Duration(milliseconds: timeUntilNextMultiple), () {
      _tick();
      _periodic = Timer.periodic(Duration(milliseconds: Config.intervalMillis), (_) {
        _tick();
      });
    });
  }

  void _tick() {
    _offsetCount++;
    final seed = _initialSeed + (Config.intervalMillis * _offsetCount);
    _seedController.add(seed);
  }

  void dispose() {
    _periodic?.cancel();
    _seedController.close();
  }
}
