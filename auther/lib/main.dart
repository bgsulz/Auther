import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'style.dart';
import 'splash.dart';
import 'login.dart';
import 'codes.dart';
import 'qr.dart';
import 'scanner.dart';
import 'settings.dart';

void main() {
  runApp(AutherApp());
}

class AutherApp extends StatelessWidget {
  const AutherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AutherState(),
      child: MaterialApp(
        title: 'Auther',
        theme: ThemeData(
          brightness: Brightness.dark,
          textTheme: TextTheme(
            displayLarge: Style.serif(),
            displayMedium: Style.serif(),
            displaySmall: Style.serif(),
            headlineLarge: Style.serif(),
            headlineMedium: Style.serif(),
            headlineSmall: Style.serif(),
            titleLarge: Style.serif(),
            titleMedium: Style.serif(),
            titleSmall: Style.serif(),
          ),
        ),
        routes: {
          '/': (context) => SplashScreen(),
          '/intro': (context) => IntroPage(),
          '/login': (context) => LoginPage(),
          '/codes': (context) => CodeListPage(),
          '/codes/scan': (context) => CodeScanPage(),
          '/codes/qr': (context) => QRCodePage(),
          '/codes/settings': (context) => SettingsPage(),
        },
      ),
    );
  }
}

class AutherState extends ChangeNotifier {
  static int refreshIntervalSeconds = 10;

  List<Person> codes = [
    Person(name: "Aunt Amy", personHash: "aaa"),
    Person(name: "Aunt Amy", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "bbb"),
  ];
  String userHash =
      "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08";
  int initialSeed = 0;
  int offsetCount = 0;
  int millisecondsNextRefresh = 0;

  Timer? timer;

  AutherState() {
    refresh();
  }

  void refresh() {
    timer?.cancel();
    int nowMilliseconds = DateTime.now().millisecondsSinceEpoch;
    int timeUntilNextMultiple = (refreshIntervalSeconds * 1000) -
        (nowMilliseconds % (refreshIntervalSeconds * 1000));
    initialSeed = nowMilliseconds + timeUntilNextMultiple;
    timer = Timer(Duration(milliseconds: timeUntilNextMultiple), () {
      increment();
      timer =
          Timer.periodic(Duration(seconds: refreshIntervalSeconds), (timer) {
        increment();
      });
    });
    notifyListeners();
  }

  int getMillisecondsUntilRefresh() {
    return getSeed() - DateTime.now().millisecondsSinceEpoch;
  }

  double getProgress() {
    return getMillisecondsUntilRefresh() / (refreshIntervalSeconds * 1000);
  }

  void addPerson(Person person) {
    codes.add(person);
    print("ADDED PERSON: ${person.name}");
    notifyListeners();
  }

  void increment() {
    offsetCount++;
    notifyListeners();
  }

  int getSeed() {
    return initialSeed + (refreshIntervalSeconds * 1000 * offsetCount);
  }
}
