import 'package:auther/data.dart';

import '../customization/config.dart';
import '../auther_widgets/codes.dart';
import 'auth.dart';
import '../secure.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AutherState extends ChangeNotifier {
  final searchController = TextEditingController();

  AutherData _data = AutherData(codes: []);
  String get dataJson => _data.toJsonString();

  AutherTimer _timer = AutherTimer();

  String get userHash => _data.userHash;
  set userHash(String hash) {
    _data.userHash = hash;
    storage.setPassphrase(hash);
    update();
  }

  List<Person> get codes => _data.codes;
  List<Person> get visibleCodes => _data.getVisibleCodes(searchController.text);

  AutherState() {
    _timer.start(this);
    notifyListeners();
  }

  Future<File> get _dataFile async {
    var dir = await getApplicationDocumentsDirectory();
    var file = File('${dir.path}/data.json');
    if (await file.exists() == false) {
      await file.create();
      _saveData();
    }
    return file;
  }

  Future<void> _saveData() async {
    var file = await _dataFile;
    var str = _data.toJsonString();
    await file.writeAsString(str);
  }

  Future<void> init() async {
    await loadFromFile(await _dataFile);
  }

  Future<void> loadFromFile(File file) async {
    var str = await file.readAsString();
    dynamic data;
    try {
      data = jsonDecode(str);
    } on Exception {
      data = AutherData.empty();
    }
    var hash = await storage.getPassphrase() ?? "";
    _data = AutherData.fromJson(data, hash);
    await _saveData();
    notifyListeners();
  }

  int get seed => _timer.seed;
  double get progress {
    var millisUntilRefresh =
        _timer.seed - DateTime.now().millisecondsSinceEpoch;
    return millisUntilRefresh / (Config.intervalSec * 1000);
  }

  void notifyManual() => notifyListeners();

  void update() {
    notifyListeners();
    _saveData();
  }

  void addPerson(Person person) {
    _data.codes.add(person);
    _data.codes.sort((a, b) => a.name.compareTo(b.name));
    update();
  }

  void removePersonAt(int index) {
    _data.codes.removeAt(index);
    update();
  }

  void editPersonName(Person person, String text) {
    final index = codes.indexOf(person);
    if (index != -1) {
      codes[index] = Person(name: text, personHash: person.personHash);
      codes.sort((a, b) => a.name.compareTo(b.name));
      update();
    }
  }

  bool checkEmergency(Person person, String passphrase) {
    var personHash = AutherAuth.hashPassphrase(passphrase);
    var isSame = personHash == person.personHash;
    if (isSame) {
      final index =
          codes.indexWhere((curr) => curr.personHash == person.personHash);
      if (index != -1) {
        codes[index].breakConnection();
        notifyListeners();
        _saveData();
      }
    }
    return isSame;
  }

  void resetAll() {
    _data.userHash = '';
    storage.deletePassphrase();
    codes.clear();
    update();
  }

  Future<void> _deleteFile() async {
    var file = await _dataFile;
    await file.delete();
    storage.deletePassphrase();
  }
}
