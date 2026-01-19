import 'dart:async';
import 'dart:io';
import 'package:auther/models/person.dart';
import 'package:auther/repositories/person_repository.dart';
import 'package:auther/repositories/secure_storage_repository.dart';
import 'package:auther/services/auth_service.dart';
import 'package:auther/services/passphrase_service.dart';
import 'package:auther/services/biometric_service.dart';
import 'package:auther/repositories/auth_ticker_service.dart';
import 'package:auther/services/logger.dart';
import 'package:flutter/material.dart';
import 'package:auther/repositories/auther_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../customization/config.dart';

/// Main application state that coordinates services and notifies UI.
/// Refactored to delegate to focused services rather than implementing
/// all logic directly.
class AutherState extends ChangeNotifier {
  final searchController = TextEditingController();

  final PersonRepository _personRepository;
  final PassphraseService _passphraseService;
  final AuthTicker _ticker;

  int _currentSeed = 0;
  StreamSubscription<int>? _tickerSub;

  ThemeMode _themeMode = ThemeMode.system;
  static const _themeModeKey = 'theme_mode';

  // Biometric authentication
  final BiometricService _biometricService = BiometricService();
  bool _biometricEnabled = false;
  DateTime? _biometricLastAuth;
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _biometricLastAuthKey = 'biometric_last_auth';
  static const _biometricTimeoutDays = 7;

  AutherState({
    required AutherRepository repository,
    required SecureStorageService secureStorage,
    required AuthTicker ticker,
  })  : _personRepository = PersonRepository(dataRepository: repository),
        _passphraseService = PassphraseService(secureStorage: secureStorage),
        _ticker = ticker {
    _init();
  }

  // --- Getters for UI compatibility ---

  /// List of all people
  List<Person> get codes => _personRepository.people;

  /// List of people filtered by search text
  List<Person> get visibleCodes =>
      _personRepository.getVisibleCodes(searchController.text);

  /// Current user hash
  String get userHash => _personRepository.userHash;

  /// Sets user hash (triggers persist)
  set userHash(String hash) {
    _personRepository.userHash = hash;
    _personRepository.persist();
    notifyListeners();
  }

  /// Current seed for code generation
  int get seed => _currentSeed;

  /// Progress until next code refresh (0.0 to 1.0)
  double get progress {
    if (_currentSeed == 0) return 1.0;
    final millisUntilRefresh =
        _currentSeed - DateTime.now().millisecondsSinceEpoch;
    return millisUntilRefresh / (Config.intervalSec * 1000);
  }

  /// JSON representation of data (for export)
  String get dataJson => _personRepository.toJsonString();

  /// Current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Whether biometric authentication is enabled
  bool get biometricEnabled => _biometricEnabled;

  /// Whether biometric is valid (enabled and within timeout window)
  bool get biometricValid {
    if (!_biometricEnabled || _biometricLastAuth == null) return false;
    final elapsed = DateTime.now().difference(_biometricLastAuth!);
    return elapsed.inDays < _biometricTimeoutDays;
  }

  /// Check if device supports biometrics
  Future<bool> get biometricAvailable => _biometricService.isAvailable();

  /// Set theme mode and persist
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
    if (enabled) {
      await recordBiometricAuth();
    }
    notifyListeners();
  }

  /// Record successful biometric authentication timestamp
  Future<void> recordBiometricAuth() async {
    _biometricLastAuth = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_biometricLastAuthKey, _biometricLastAuth!.millisecondsSinceEpoch);
  }

  /// Attempt biometric login, returns true if successful
  Future<bool> attemptBiometricLogin() async {
    if (!biometricValid) return false;
    final success = await _biometricService.authenticate();
    if (success) {
      await recordBiometricAuth();
    }
    return success;
  }

  // --- Initialization ---

  Future<void> _init() async {
    try {
      final hashResult = await _passphraseService.getStoredHash();
      final hash = hashResult.valueOr('');
      await _personRepository.load(hash);
    } catch (e) {
      logger.error('Failed to initialize state', e, null, 'AutherState');
    }

    // Load theme preference
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeModeKey);
      if (themeName != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (m) => m.name == themeName,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      logger.error('Failed to load theme preference', e, null, 'AutherState');
    }

    // Load biometric preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      _biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      final lastAuthMs = prefs.getInt(_biometricLastAuthKey);
      if (lastAuthMs != null) {
        _biometricLastAuth = DateTime.fromMillisecondsSinceEpoch(lastAuthMs);
      }
    } catch (e) {
      logger.error('Failed to load biometric preferences', e, null, 'AutherState');
    }

    _tickerSub = _ticker.seedStream.listen((seed) {
      _currentSeed = seed;
      notifyListeners();
    });
    _ticker.start();
    notifyListeners();
  }

  // --- Person Operations ---

  void addPerson(Person person) {
    final result = _personRepository.addPerson(person);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) => logger.warn('Failed to add person: $msg', 'AutherState'),
    );
  }

  void removePersonAt(int index) {
    final result = _personRepository.removePersonAt(index);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) => logger.warn('Failed to remove person: $msg', 'AutherState'),
    );
  }

  void removePerson(Person person) {
    final result = _personRepository.removePerson(person.personHash);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) => logger.warn('Failed to remove person: $msg', 'AutherState'),
    );
  }

  void reorderPerson(int oldIndex, int newIndex) {
    final result = _personRepository.reorderPerson(oldIndex, newIndex);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) => logger.warn('Failed to reorder person: $msg', 'AutherState'),
    );
  }

  void editPersonName(Person person, String text) {
    final result = _personRepository.editPersonName(person.personHash, text);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) => logger.warn('Failed to edit person name: $msg', 'AutherState'),
    );
  }

  bool checkEmergency(Person person, String passphrase) {
    final personHash = AutherAuth.hashPassphrase(passphrase);
    final isSame = personHash == person.personHash;
    if (isSame) {
      final result = _personRepository.markAsBroken(person.personHash);
      result.when(
        success: (_) => notifyListeners(),
        failure: (_, __) {},
      );
    }
    return isSame;
  }

  // --- Passphrase Operations ---

  Future<void> setPassphrase(String passphrase) async {
    final result = await _passphraseService.setPassphrase(passphrase);
    result.when(
      success: (derivedKeyHex) {
        _personRepository.userHash = derivedKeyHex;
        _personRepository.persist();
        notifyListeners();
      },
      failure: (msg, _) => logger.error('Failed to set passphrase: $msg', null, null, 'AutherState'),
    );
  }

  Future<bool> validatePassphrase(String passphrase) async {
    final result = await _passphraseService.validatePassphrase(passphrase);
    return result.valueOr(false);
  }

  // --- Data Operations ---

  Future<void> loadFromFile(File file) async {
    final hashResult = await _passphraseService.getStoredHash();
    final hash = hashResult.valueOr('');
    final result = await _personRepository.loadFromFile(file, hash);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) => logger.warn('Failed to load from file: $msg', 'AutherState'),
    );
  }

  Future<void> resetAll() async {
    await _passphraseService.deletePassphrase();
    await _personRepository.clearAll();
    notifyListeners();
  }

  void update() {
    _personRepository.persist();
    notifyListeners();
  }

  void notifyManual() => notifyListeners();

  @override
  void dispose() {
    _tickerSub?.cancel();
    _ticker.dispose();
    searchController.dispose();
    super.dispose();
  }
}
