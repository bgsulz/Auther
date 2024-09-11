import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auther/hash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  static int refreshIntervalSeconds = 30;

  final searchController = TextEditingController();

  String userHash = "";
  List<Person> codes = [];

  Timer? timer;
  int initialSeed = 0;
  int offsetCount = 0;
  int millisecondsNextRefresh = 0;

  AutherState() {
    if (kDebugMode) {
      print("Filling codes with stock.");
      codes = [
        Person(name: "Zachary", personHash: AutherHash.hashPassphrase("1234")),
        Person(name: "Samantha", personHash: AutherHash.hashPassphrase("5678")),
        Person(name: "Elijah", personHash: AutherHash.hashPassphrase("9012")),
        Person(name: "Lillian", personHash: AutherHash.hashPassphrase("3456")),
        Person(name: "Logan", personHash: AutherHash.hashPassphrase("7890")),
        Person(name: "Ava", personHash: AutherHash.hashPassphrase("2468")),
        Person(name: "William", personHash: AutherHash.hashPassphrase("1357")),
        Person(name: "Sophia", personHash: AutherHash.hashPassphrase("4680")),
        Person(name: "Oliver", personHash: AutherHash.hashPassphrase("7531")),
        Person(name: "Mia", personHash: AutherHash.hashPassphrase("8629")),
      ];
      notifyListeners();
      // _saveData();
    }
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    int nowMilliseconds = DateTime.now().millisecondsSinceEpoch;
    int timeUntilNextMultiple = (refreshIntervalSeconds * 1000) -
        (nowMilliseconds % (refreshIntervalSeconds * 1000));
    initialSeed = nowMilliseconds + timeUntilNextMultiple;
    timer = Timer(Duration(milliseconds: timeUntilNextMultiple), () {
      _increment();
      timer =
          Timer.periodic(Duration(seconds: refreshIntervalSeconds), (timer) {
        _increment();
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
    codes.sort((a, b) => a.name.compareTo(b.name));
    // print("ADDED PERSON: ${person.name}");
    notifyListeners();
    _saveData();
  }

  void removePersonAt(int index) {
    codes.removeAt(index);
    notifyListeners();
    _saveData();
  }

  void editPersonName(Person person, String text) {
    final index = codes.indexOf(person);
    if (index != -1) {
      codes[index] = Person(name: text, personHash: person.personHash);
      codes.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      _saveData();
    }
  }

  bool checkEmergency(Person person, String passphrase) {
    var personHash = AutherHash.hashPassphrase(passphrase);
    var isSame = personHash == person.personHash;
    if (isSame) {
      final index =
          codes.indexWhere((curr) => curr.personHash == person.personHash);
      if (index != -1) {
        codes[index].breakConnection();
        notifyListeners();
        _saveData();
      } else {
        print("INDEX NOT FOUND");
      }
    }
    return isSame;
  }

  void reset() {
    userHash = '';
    codes.clear();
    notifyListeners();
    _saveData();
  }

  void setUserHash(String hash) {
    userHash = hash;
    notifyListeners();
    _saveData();
  }

  int getSeed() {
    return initialSeed + (refreshIntervalSeconds * 1000 * offsetCount);
  }

  void _increment() {
    offsetCount++;
    notifyListeners();
  }

  void editSearch() {
    notifyListeners();
  }

  Future<void> _saveData() async {
    print("Saving shortly...");
    var data = {
      'codes': codes.map((p) => p.toJson()).toList(),
      'userHash': userHash,
    };
    var json = jsonEncode(data);
    print("Saving file: $json");
    var file = await _dataFile;
    await file.writeAsString(json);
  }

  Future<void> loadData() async {
    print("Loading data.");
    try {
      var file = await _dataFile;
      var json = await file.readAsString();
      var data = jsonDecode(json);
      codes =
          (data['codes'] as List).map((json) => Person.fromJson(json)).toList();
      userHash = data['userHash'];
      print("Set userhash to $userHash.");
    } on FileSystemException {
      print("No data file found.");
    } on Exception {
      print("Error loading data:");
      rethrow;
    }
  }

  static bool _clearData = true;

  Future<File> get _dataFile async {
    var dir = await getApplicationDocumentsDirectory();
    var file = File('${dir.path}/data.json');
    if (_clearData) {
      _clearData = false;
      await file.delete();
    }
    return file;
  }
}
