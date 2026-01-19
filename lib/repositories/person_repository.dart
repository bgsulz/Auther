import 'dart:convert';
import 'dart:io';
import '../models/auther_data.dart';
import '../models/person.dart';
import '../models/result.dart';
import '../services/logger.dart';
import '../services/validators.dart';
import 'auther_repository.dart';

/// Repository for person CRUD operations and persistence.
/// Extracted from AutherState to provide a focused, testable repository.
class PersonRepository {
  final AutherRepository _dataRepository;
  List<Person> _people = [];
  String _userHash = '';

  PersonRepository({required AutherRepository dataRepository})
      : _dataRepository = dataRepository;

  /// Current list of people (read-only view)
  List<Person> get people => List.unmodifiable(_people);

  /// Current user hash
  String get userHash => _userHash;

  /// Sets the user hash
  set userHash(String hash) {
    _userHash = hash;
  }

  /// Loads data from storage with the given user hash.
  Future<Result<void>> load(String hash) async {
    try {
      final content = await _dataRepository.loadData();
      final Map<String, dynamic> json = jsonDecode(content ?? '{}');
      final data = AutherData.fromJson(json, hash);
      _people = data.codes;
      _userHash = data.userHash;
      logger.info('Loaded ${_people.length} people', 'PersonRepository');
      return const Success(null);
    } catch (e) {
      logger.error('Failed to load people', e, null, 'PersonRepository');
      _people = [];
      _userHash = '';
      return Failure('Failed to load data', e);
    }
  }

  /// Loads data from an external file (for import).
  Future<Result<void>> loadFromFile(File file, String hash) async {
    try {
      final str = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(str.isEmpty ? '{}' : str);
      final data = AutherData.fromJson(json, hash);
      _people = data.codes;
      _userHash = data.userHash;
      await _persist();
      logger.info('Imported ${_people.length} people from file', 'PersonRepository');
      return const Success(null);
    } catch (e) {
      logger.error('Failed to import from file', e, null, 'PersonRepository');
      return Failure('Failed to import data', e);
    }
  }

  /// Adds a new person.
  Result<void> addPerson(Person person) {
    final validation = Validators.validatePersonName(person.name);
    if (validation.isFailure) {
      return Failure(validation.errorOrNull ?? 'Invalid name');
    }

    final hashValidation = Validators.validateHash(person.personHash);
    if (hashValidation.isFailure) {
      return Failure(hashValidation.errorOrNull ?? 'Invalid hash');
    }

    // Check for duplicate hash
    if (_people.any((p) => p.personHash == person.personHash)) {
      return const Failure('Person already exists');
    }

    _people.add(person);
    _persist();
    logger.info('Added person: ${person.name}', 'PersonRepository');
    return const Success(null);
  }

  /// Removes a person by their hash.
  Result<void> removePerson(String personHash) {
    final index = _people.indexWhere((p) => p.personHash == personHash);
    if (index == -1) {
      return const Failure('Person not found');
    }

    final removed = _people.removeAt(index);
    _persist();
    logger.info('Removed person: ${removed.name}', 'PersonRepository');
    return const Success(null);
  }

  /// Removes a person at the given index.
  Result<void> removePersonAt(int index) {
    if (index < 0 || index >= _people.length) {
      return const Failure('Invalid index');
    }

    final removed = _people.removeAt(index);
    _persist();
    logger.info('Removed person at index $index: ${removed.name}', 'PersonRepository');
    return const Success(null);
  }

  /// Edits a person's name by their hash.
  /// Uses indexWhere to find by hash (fixes indexOf bug from original).
  Result<void> editPersonName(String personHash, String newName) {
    final validation = Validators.validatePersonName(newName);
    if (validation.isFailure) {
      return Failure(validation.errorOrNull ?? 'Invalid name');
    }

    final index = _people.indexWhere((p) => p.personHash == personHash);
    if (index == -1) {
      return const Failure('Person not found');
    }

    _people[index] = Person(name: validation.valueOrNull!, personHash: personHash);
    _people.sort((a, b) => a.name.compareTo(b.name));
    _persist();
    logger.info('Edited person name to: ${validation.valueOrNull}', 'PersonRepository');
    return const Success(null);
  }

  /// Reorders a person from oldIndex to newIndex.
  Result<void> reorderPerson(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _people.length) {
      return const Failure('Invalid old index');
    }
    if (newIndex < 0 || newIndex > _people.length) {
      return const Failure('Invalid new index');
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = _people.removeAt(oldIndex);
    _people.insert(newIndex, item);
    _persist();
    return const Success(null);
  }

  /// Marks a person as broken (emergency passphrase match).
  Result<void> markAsBroken(String personHash) {
    final index = _people.indexWhere((p) => p.personHash == personHash);
    if (index == -1) {
      return const Failure('Person not found');
    }

    _people[index] = _people[index].copyWith(isBroken: true);
    _persist();
    logger.info('Marked person as broken', 'PersonRepository');
    return const Success(null);
  }

  /// Clears all people.
  Future<Result<void>> clearAll() async {
    _people.clear();
    _userHash = '';
    try {
      await _dataRepository.deleteAll();
      logger.info('Cleared all data', 'PersonRepository');
      return const Success(null);
    } catch (e) {
      logger.error('Failed to clear data', e, null, 'PersonRepository');
      return Failure('Failed to clear data', e);
    }
  }

  /// Returns the data as a JSON string (for export).
  String toJsonString() {
    final data = AutherData(codes: _people)..userHash = _userHash;
    return data.toJsonString();
  }

  /// Persists current state to storage.
  Future<void> _persist() async {
    try {
      final data = AutherData(codes: _people)..userHash = _userHash;
      await _dataRepository.saveData(data.toJsonString());
    } catch (e) {
      logger.error('Failed to persist data', e, null, 'PersonRepository');
    }
  }

  /// Forces a persist (for external callers when userHash changes).
  Future<void> persist() => _persist();

  /// Gets visible codes filtered by search text.
  List<Person> getVisibleCodes(String searchText) {
    if (searchText.isEmpty) return _people;
    final textClean = searchText.toLowerCase().trim();
    return _people.where((e) => e.name.toLowerCase().contains(textClean)).toList();
  }
}
