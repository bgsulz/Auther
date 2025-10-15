import 'dart:async';
import 'package:auther/customization/config.dart';
import 'package:auther/state/auther_state.dart';

class AutherTimer {
  late AutherState appState;
  Timer? timer;
  int initialSeed = 0;
  int offsetCount = 0;
  int millisecondsNextRefresh = 0;

  int get seed => initialSeed + (Config.intervalMillis * offsetCount);

  void start(AutherState state) {
    appState = state;

    void resetTimer() {
      _increment();
      timer = Timer.periodic(
        Duration(seconds: Config.intervalSec),
        (timer) => _increment(),
      );
    }

    timer?.cancel();
    int nowMillis = DateTime.now().millisecondsSinceEpoch;
    int timeUntilNextMultiple =
        Config.intervalMillis - (nowMillis % Config.intervalMillis);
    initialSeed = nowMillis + timeUntilNextMultiple;
    timer = Timer(
      Duration(milliseconds: timeUntilNextMultiple),
      resetTimer,
    );
  }

  void _increment() {
    offsetCount++;
    appState.notifyManual();
  }
}
