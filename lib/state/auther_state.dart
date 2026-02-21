import 'dart:async';
import 'dart:io';
import 'package:auther/models/person.dart';
import 'package:auther/models/result.dart';
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
class AutherState extends ChangeNotifier with WidgetsBindingObserver {
  final searchController = TextEditingController();

  final PersonRepository _personRepository;
  final PassphraseService _passphraseService;
  final AuthTicker _ticker;

  int _currentSeed = 0;
  StreamSubscription<int>? _tickerSub;

  // Initialization tracking
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  ThemeMode _themeMode = ThemeMode.system;
  static const _themeModeKey = 'theme_mode';
  String? _signupNotice;

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
    WidgetsBinding.instance.addObserver(this);
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
  Future<void> setUserHash(String hash) async {
    _personRepository.userHash = hash;
    final result = await _personRepository.persist();
    result.when(
      success: (_) {},
      failure: (msg, _) => logger.error(
          'Failed to persist after setting user hash: $msg',
          null,
          null,
          'AutherState'),
    );
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
  String? get signupNotice => _signupNotice;

  /// Whether biometric authentication is enabled
  bool get biometricEnabled => _biometricEnabled;

  /// Whether biometric is valid (enabled and within timeout window)
  bool get biometricValid {
    if (!_biometricEnabled || _biometricLastAuth == null) {
      logger.info(
          '[Biometric] biometricValid=false (enabled=$_biometricEnabled, lastAuth=$_biometricLastAuth)',
          'AutherState');
      return false;
    }
    final elapsed = DateTime.now().difference(_biometricLastAuth!);
    final valid = elapsed.inDays < _biometricTimeoutDays;
    logger.info(
        '[Biometric] biometricValid=$valid (elapsed=${elapsed.inDays} days, timeout=$_biometricTimeoutDays days)',
        'AutherState');
    return valid;
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
    logger.info('[Biometric] setBiometricEnabled($enabled)', 'AutherState');
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
    await prefs.setInt(
        _biometricLastAuthKey, _biometricLastAuth!.millisecondsSinceEpoch);
    logger.info(
        '[Biometric] recordBiometricAuth: $_biometricLastAuth (ms=${_biometricLastAuth!.millisecondsSinceEpoch})',
        'AutherState');
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
      if (hashResult.isFailure) {
        logger.warn(
            'getStoredHash failed: ${hashResult.errorOrNull}', 'AutherState');
      }
      final hash = hashResult.valueOr('');
      if (hash.isEmpty) {
        logger.info('getStoredHash returned empty (new user or storage issue)',
            'AutherState');
      }
      final loadResult = await _personRepository.load(hash);
      if (loadResult.isFailure) {
        logger.error('PersonRepository.load failed: ${loadResult.errorOrNull}',
            null, null, 'AutherState');
      }
      final hashIsPlausible = AutherAuth.isPlausibleHash(hash);
      final hasExistingPeople = _personRepository.people.isNotEmpty;
      if ((!hashIsPlausible && hash.isNotEmpty) ||
          (hash.isEmpty && hasExistingPeople)) {
        await _resetIdentityForFreshStart(
          'Security data was unavailable. Create a new passphrase to continue.',
        );
      }
      logger.info(
          'Initialization complete: userHash=${_personRepository.userHash.isEmpty ? "(empty)" : "present (${_personRepository.userHash.length} chars)"}',
          'AutherState');
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
      logger.info(
          '[Biometric] Loaded prefs: enabled=$_biometricEnabled, lastAuth=$_biometricLastAuth, lastAuthMs=$lastAuthMs',
          'AutherState');
    } catch (e) {
      logger.error(
          'Failed to load biometric preferences', e, null, 'AutherState');
    }

    _tickerSub = _ticker.seedStream.listen((seed) {
      _currentSeed = seed;
      notifyListeners();
    });
    _ticker.start();
    logger.info(
        '[Biometric] AutherState initialization complete', 'AutherState');
    _initCompleter.complete();
    notifyListeners();
  }

  // --- Person Operations ---

  Future<void> addPerson(Person person) async {
    final result = await _personRepository.addPerson(person);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) =>
          logger.warn('Failed to add person: $msg', 'AutherState'),
    );
  }

  Future<void> removePersonAt(int index) async {
    final result = await _personRepository.removePersonAt(index);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) =>
          logger.warn('Failed to remove person: $msg', 'AutherState'),
    );
  }

  Future<void> removePerson(Person person) async {
    final result = await _personRepository.removePerson(person.personHash);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) =>
          logger.warn('Failed to remove person: $msg', 'AutherState'),
    );
  }

  Future<void> reorderPerson(int oldIndex, int newIndex) async {
    final result = await _personRepository.reorderPerson(oldIndex, newIndex);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) =>
          logger.warn('Failed to reorder person: $msg', 'AutherState'),
    );
  }

  Future<void> editPersonName(Person person, String text) async {
    final result =
        await _personRepository.editPersonName(person.personHash, text);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) =>
          logger.warn('Failed to edit person name: $msg', 'AutherState'),
    );
  }

  bool checkEmergency(Person person, String passphrase) {
    final personHash = AutherAuth.hashPassphrase(passphrase);
    final isSame = personHash == person.personHash;
    if (isSame) {
      _personRepository.markAsBroken(person.personHash).then((result) {
        result.when(
          success: (_) => notifyListeners(),
          failure: (_, __) {},
        );
      });
    }
    return isSame;
  }

  // --- Passphrase Operations ---

  Future<Result<void>> setPassphrase(String passphrase) async {
    final result = await _passphraseService.setPassphrase(passphrase);
    if (result.isFailure) {
      logger.error('Failed to set passphrase: ${result.errorOrNull}', null,
          null, 'AutherState');
      return Failure(result.errorOrNull ?? 'Failed to set passphrase');
    }
    _personRepository.userHash = result.valueOrNull!;
    final persistResult = await _personRepository.persist();
    if (persistResult.isFailure) {
      return Failure(
          persistResult.errorOrNull ??
              'Failed to persist data after setting passphrase');
    }
    persistResult.when(
      success: (_) {},
      failure: (msg, _) => logger.error(
          'Failed to persist after setting passphrase: $msg',
          null,
          null,
          'AutherState'),
    );
    _signupNotice = null;
    notifyListeners();
    return const Success(null);
  }

  Future<bool> validatePassphrase(String passphrase) async {
    final result = await _passphraseService.validatePassphrase(passphrase);
    return result.valueOr(false);
  }

  Future<void> markIdentityUnavailable() async {
    await _resetIdentityForFreshStart(
      'Security data was unavailable. Create a new passphrase to continue.',
    );
  }

  // --- Data Operations ---

  Future<void> loadFromFile(File file) async {
    final hashResult = await _passphraseService.getStoredHash();
    final hash = hashResult.valueOr('');
    final result = await _personRepository.loadFromFile(file, hash);
    result.when(
      success: (_) => notifyListeners(),
      failure: (msg, _) =>
          logger.warn('Failed to load from file: $msg', 'AutherState'),
    );
  }

  Future<void> resetAll() async {
    await _resetIdentityForFreshStart(null);
  }

  Future<void> update() async {
    final result = await _personRepository.persist();
    result.when(
      success: (_) {},
      failure: (msg, _) => logger.error(
          'Failed to persist during update: $msg', null, null, 'AutherState'),
    );
    notifyListeners();
  }

  void notifyManual() => notifyListeners();

  void onAppResumed() {
    _ticker.restart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerSub?.cancel();
    _ticker.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _resetIdentityForFreshStart(String? notice) async {
    final deleteResult = await _passphraseService.deletePassphrase();
    if (deleteResult.isFailure) {
      logger.warn(
          'Failed to clear secure storage: ${deleteResult.errorOrNull}',
          'AutherState');
    }
    final clearResult = await _personRepository.clearAll();
    if (clearResult.isFailure) {
      logger.warn('Failed to clear local data: ${clearResult.errorOrNull}',
          'AutherState');
    }
    _signupNotice = notice;
    notifyListeners();
  }
}
