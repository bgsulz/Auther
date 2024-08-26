import 'dart:async';

import 'package:auther/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'codes.dart';
import 'style.dart';

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
          '/': (context) => LoginPage(),
          '/codes': (context) => CodeListPage(),
          // '/codes/settings': (context) => SettingsPage(),
        },
      ),
    );
  }
}

class AutherState extends ChangeNotifier {
  List<Person> codes = [
    Person(name: "Aunt Amy", personHash: "aaa"),
    Person(name: "Uncle Rob", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "aaa"),
    Person(name: "Uncle Rob", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "aaa"),
    Person(name: "Uncle Rob", personHash: "bbb"),
    Person(name: "Aunt Amy", personHash: "aaa"),
    Person(name: "Uncle Rob", personHash: "bbb"),
  ];
  String userHash = "";
  int initialSeed = 0;
  int offsetCount = 0;

  static int refreshIntervalSeconds = 1;

  // ignore: unused_field
  Timer? _timer;

  AutherState() {
    refresh();
  }

  void refresh() {
    _timer?.cancel();
    int nowMilliseconds = DateTime.now().millisecondsSinceEpoch;
    int timeUntilNextMultiple = (refreshIntervalSeconds * 1000) -
        (nowMilliseconds % (refreshIntervalSeconds * 1000));
    initialSeed = nowMilliseconds + timeUntilNextMultiple;
    _timer = Timer(Duration(milliseconds: timeUntilNextMultiple), () {
      increment();
      _timer =
          Timer.periodic(Duration(seconds: refreshIntervalSeconds), (timer) {
        increment();
      });
    });
  }

  void addPerson(Person person) {
    codes.add(person);
    notifyListeners();
  }

  void increment() {
    offsetCount++;
    notifyListeners();
  }

  int getSeed() {
    return initialSeed + 1000 * offsetCount;
  }
}
