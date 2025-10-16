import 'package:auther/models/auther_data.dart';
import 'package:auther/models/person.dart';
import 'package:auther/repositories/secure_storage_repository.dart';
import 'package:auther/services/auth_service.dart';
import 'package:auther/repositories/auth_ticker_service.dart';

import '../customization/config.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:auther/repositories/auther_repository.dart';

class AutherState extends ChangeNotifier {
  final searchController = TextEditingController();

  final AutherRepository repository;
  final SecureStorageService secureStorage;
  final AuthTicker _ticker;

  List<Person> _people = [];
  String _userHash = '';
  int _currentSeed = 0;
  StreamSubscription<int>? _tickerSub;

  AutherState({
    required this.repository,
    required this.secureStorage,
    required AuthTicker ticker,
  }) : _ticker = ticker {
    _init();
  }

  // Legacy stuff for now
  List<Person> get codes => _people;
  List<Person> get visibleCodes {
    final text = searchController.text;
    if (text.isEmpty) return _people;
    final textClean = text.toLowerCase().trim();
    return _people.where((e) => e.name.toLowerCase().contains(textClean)).toList();
  }

  String get userHash => _userHash;
  set userHash(String hash) {
    _userHash = hash;
    _persist();
  }

  int get seed => _currentSeed;
  double get progress {
    if (_currentSeed == 0) return 1.0;
    final millisUntilRefresh = _currentSeed - DateTime.now().millisecondsSinceEpoch;
    return millisUntilRefresh / (Config.intervalSec * 1000);
  }

  Future<void> _init() async {
    try {
      final content = await repository.loadData();
      final Map<String, dynamic> json = jsonDecode(content ?? '{}');
      final String? stored = await secureStorage.getPassphrase();
      String hash = '';
      if (stored != null && stored.isNotEmpty) {
        try {
          final rec = jsonDecode(stored) as Map<String, dynamic>;
          hash = (rec['derivedKeyHex'] as String? ?? '');
        } catch (_) {
          hash = stored;
        }
      }
      final data = AutherData.fromJson(json, hash);
      _people = data.codes;
      _userHash = data.userHash;
    } catch (_) {
      _people = [];
      _userHash = '';
    }

    _tickerSub = _ticker.seedStream.listen((seed) {
      _currentSeed = seed;
      notifyListeners();
    });
    _ticker.start();
    notifyListeners();
  }

  String get dataJson {
    final data = AutherData(codes: _people)..userHash = _userHash;
    return data.toJsonString();
  }

  Future<void> loadFromFile(File file) async {
    try {
      final str = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(str.isEmpty ? '{}' : str);
      final String hash = await secureStorage.getPassphrase() ?? '';
      final data = AutherData.fromJson(json, hash);
      _people = data.codes;
      _userHash = data.userHash;
      await repository.saveData(data.toJsonString());
      notifyListeners();
    } catch (_) {
      // ignore malformed import
    }
  }

  void notifyManual() => notifyListeners();

  Future<void> _persist() async {
    final data = AutherData(codes: _people)..userHash = _userHash;
    await repository.saveData(data.toJsonString());
    notifyListeners();
  }

  void update() {
    _persist();
  }

  void addPerson(Person person) {
    _people.add(person);
    update();
  }

  void removePersonAt(int index) {
    if (index < 0 || index >= _people.length) return;
    _people.removeAt(index);
    update();
  }

  void reorderPerson(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _people.length || newIndex < 0 || newIndex > _people.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _people.removeAt(oldIndex);
    _people.insert(newIndex, item);
    update();
  }

  void editPersonName(Person person, String text) {
    final index = _people.indexOf(person);
    if (index != -1) {
      _people[index] = Person(name: text, personHash: person.personHash);
      _people.sort((a, b) => a.name.compareTo(b.name));
      update();
    }
  }

  bool checkEmergency(Person person, String passphrase) {
    final personHash = AutherAuth.hashPassphrase(passphrase);
    final isSame = personHash == person.personHash;
    if (isSame) {
      final index = _people.indexWhere((curr) => curr.personHash == person.personHash);
      if (index != -1) {
        _people[index] = _people[index].copyWith(isBroken: true);
        _persist();
      }
    }
    return isSame;
  }

  Future<void> resetAll() async {
    _userHash = '';
    await secureStorage.deletePassphrase();
    _people.clear();
    await repository.deleteAll();
    notifyListeners();
  }

  Future<void> setPassphrase(String passphrase) async {
    final rec = AutherAuth.deriveCredentials(passphrase);
    await secureStorage.setPassphrase(jsonEncode(rec));
    _userHash = rec['derivedKeyHex'] as String;
    await _persist();
  }

  Future<bool> validatePassphrase(String passphrase) async {
    final stored = await secureStorage.getPassphrase();
    if (stored == null || stored.isEmpty) return false;
    try {
      final rec = jsonDecode(stored) as Map<String, dynamic>;
      return AutherAuth.verifyPassphrase(passphrase, rec);
    } catch (_) {
      return AutherAuth.hashPassphrase(passphrase) == stored;
    }
  }

  @override
  void dispose() {
    _tickerSub?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
