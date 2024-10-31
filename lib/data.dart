import 'dart:async';
import 'dart:convert';
import 'package:auther/auther_widgets/codes.dart';
import 'package:auther/customization/config.dart';
import 'package:auther/state.dart';

class AutherData {
  AutherData.empty() : this(userHash: '', codes: []);
  bool get isEmpty => userHash.isEmpty && codes.isEmpty;

  String userHash = '';
  List<Person> codes = [];

  AutherData({
    this.userHash = '',
    this.codes = const [],
  });

  factory AutherData.fromJson(Map<String, dynamic> json, String hash) {
    try {
      return AutherData(
        userHash: hash,
        codes: List<Person>.from(json['codes'].map((x) => Person.fromJson(x))),
      );
    } catch (e) {
      return AutherData.empty();
    }
  }

  Map<String, dynamic> toJson() => {
        'codes': List<dynamic>.from(codes.map((x) => x.toJson())),
      };

  String toJsonString() => jsonEncode(toJson());

  List<Person> getVisibleCodes(String text) {
    if (text.isEmpty) {
      return codes;
    } else {
      final textClean = text.toLowerCase().trim();
      return codes
          .where((e) => e.name.toLowerCase().contains(textClean))
          .toList();
    }
  }
}

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
