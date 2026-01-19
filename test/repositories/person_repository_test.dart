import 'package:flutter_test/flutter_test.dart';
import 'package:auther/repositories/person_repository.dart';
import 'package:auther/repositories/auther_repository.dart';
import 'package:auther/models/person.dart';
import 'package:auther/models/result.dart';

/// Mock repository for testing
class MockAutherRepository implements AutherRepository {
  String? _data;

  @override
  Future<void> saveData(String json) async {
    _data = json;
  }

  @override
  Future<String?> loadData() async {
    return _data ?? '{}';
  }

  @override
  Future<void> deleteAll() async {
    _data = null;
  }
}

void main() {
  group('PersonRepository', () {
    late PersonRepository repository;
    late MockAutherRepository mockDataRepo;

    setUp(() {
      mockDataRepo = MockAutherRepository();
      repository = PersonRepository(dataRepository: mockDataRepo);
    });

    group('addPerson', () {
      test('adds person with valid data', () {
        final person = Person(
          name: 'John',
          personHash: 'a' * 64,
        );

        final result = repository.addPerson(person);
        expect(result, isA<Success<void>>());
        expect(repository.people.length, 1);
        expect(repository.people.first.name, 'John');
      });

      test('fails with empty name', () {
        final person = Person(
          name: '',
          personHash: 'a' * 64,
        );

        final result = repository.addPerson(person);
        expect(result, isA<Failure<void>>());
        expect(repository.people.length, 0);
      });

      test('fails with invalid hash', () {
        final person = Person(
          name: 'John',
          personHash: 'invalid',
        );

        final result = repository.addPerson(person);
        expect(result, isA<Failure<void>>());
        expect(repository.people.length, 0);
      });

      test('fails with duplicate hash', () {
        final hash = 'a' * 64;
        final person1 = Person(name: 'John', personHash: hash);
        final person2 = Person(name: 'Jane', personHash: hash);

        repository.addPerson(person1);
        final result = repository.addPerson(person2);

        expect(result, isA<Failure<void>>());
        expect(result.errorOrNull, 'Person already exists');
        expect(repository.people.length, 1);
      });
    });

    group('removePerson', () {
      test('removes person by hash', () {
        final hash = 'a' * 64;
        repository.addPerson(Person(name: 'John', personHash: hash));

        final result = repository.removePerson(hash);
        expect(result, isA<Success<void>>());
        expect(repository.people.length, 0);
      });

      test('fails for non-existent person', () {
        final result = repository.removePerson('nonexistent');
        expect(result, isA<Failure<void>>());
        expect(result.errorOrNull, 'Person not found');
      });
    });

    group('removePersonAt', () {
      test('removes person at valid index', () {
        repository.addPerson(Person(name: 'John', personHash: 'a' * 64));
        repository.addPerson(Person(name: 'Jane', personHash: 'b' * 64));

        final result = repository.removePersonAt(0);
        expect(result, isA<Success<void>>());
        expect(repository.people.length, 1);
        expect(repository.people.first.name, 'Jane');
      });

      test('fails for negative index', () {
        repository.addPerson(Person(name: 'John', personHash: 'a' * 64));

        final result = repository.removePersonAt(-1);
        expect(result, isA<Failure<void>>());
        expect(result.errorOrNull, 'Invalid index');
      });

      test('fails for index out of bounds', () {
        repository.addPerson(Person(name: 'John', personHash: 'a' * 64));

        final result = repository.removePersonAt(5);
        expect(result, isA<Failure<void>>());
        expect(result.errorOrNull, 'Invalid index');
      });
    });

    group('editPersonName', () {
      test('edits person name by hash', () {
        final hash = 'a' * 64;
        repository.addPerson(Person(name: 'John', personHash: hash));

        final result = repository.editPersonName(hash, 'Johnny');
        expect(result, isA<Success<void>>());
        expect(repository.people.first.name, 'Johnny');
      });

      test('fails for non-existent person', () {
        final result = repository.editPersonName('nonexistent', 'New Name');
        expect(result, isA<Failure<void>>());
        expect(result.errorOrNull, 'Person not found');
      });

      test('fails for empty name', () {
        final hash = 'a' * 64;
        repository.addPerson(Person(name: 'John', personHash: hash));

        final result = repository.editPersonName(hash, '');
        expect(result, isA<Failure<void>>());
      });

      test('sorts people after name change', () {
        repository.addPerson(Person(name: 'Alice', personHash: 'a' * 64));
        repository.addPerson(Person(name: 'Bob', personHash: 'b' * 64));

        // Change Bob to Zack
        repository.editPersonName('b' * 64, 'Zack');

        expect(repository.people[0].name, 'Alice');
        expect(repository.people[1].name, 'Zack');

        // Change Zack to Aaron
        repository.editPersonName('b' * 64, 'Aaron');

        expect(repository.people[0].name, 'Aaron');
        expect(repository.people[1].name, 'Alice');
      });
    });

    group('reorderPerson', () {
      test('reorders from lower to higher index', () {
        repository.addPerson(Person(name: 'A', personHash: 'a' * 64));
        repository.addPerson(Person(name: 'B', personHash: 'b' * 64));
        repository.addPerson(Person(name: 'C', personHash: 'c' * 64));

        final result = repository.reorderPerson(0, 2);
        expect(result, isA<Success<void>>());
        expect(repository.people.map((p) => p.name).toList(), ['B', 'A', 'C']);
      });

      test('reorders from higher to lower index', () {
        repository.addPerson(Person(name: 'A', personHash: 'a' * 64));
        repository.addPerson(Person(name: 'B', personHash: 'b' * 64));
        repository.addPerson(Person(name: 'C', personHash: 'c' * 64));

        final result = repository.reorderPerson(2, 0);
        expect(result, isA<Success<void>>());
        expect(repository.people.map((p) => p.name).toList(), ['C', 'A', 'B']);
      });

      test('fails for invalid old index', () {
        repository.addPerson(Person(name: 'A', personHash: 'a' * 64));

        final result = repository.reorderPerson(-1, 0);
        expect(result, isA<Failure<void>>());
      });

      test('fails for invalid new index', () {
        repository.addPerson(Person(name: 'A', personHash: 'a' * 64));

        final result = repository.reorderPerson(0, -1);
        expect(result, isA<Failure<void>>());
      });
    });

    group('markAsBroken', () {
      test('marks person as broken', () {
        final hash = 'a' * 64;
        repository.addPerson(Person(name: 'John', personHash: hash));

        expect(repository.people.first.isBroken, false);

        final result = repository.markAsBroken(hash);
        expect(result, isA<Success<void>>());
        expect(repository.people.first.isBroken, true);
      });

      test('fails for non-existent person', () {
        final result = repository.markAsBroken('nonexistent');
        expect(result, isA<Failure<void>>());
      });
    });

    group('getVisibleCodes', () {
      test('returns all people when search is empty', () {
        repository.addPerson(Person(name: 'Alice', personHash: 'a' * 64));
        repository.addPerson(Person(name: 'Bob', personHash: 'b' * 64));

        final visible = repository.getVisibleCodes('');
        expect(visible.length, 2);
      });

      test('filters by name case-insensitively', () {
        repository.addPerson(Person(name: 'Alice', personHash: 'a' * 64));
        repository.addPerson(Person(name: 'Bob', personHash: 'b' * 64));

        expect(repository.getVisibleCodes('alice').length, 1);
        expect(repository.getVisibleCodes('ALICE').length, 1);
        expect(repository.getVisibleCodes('Ali').length, 1);
        expect(repository.getVisibleCodes('xyz').length, 0);
      });

      test('trims search text', () {
        repository.addPerson(Person(name: 'Alice', personHash: 'a' * 64));

        final visible = repository.getVisibleCodes('  alice  ');
        expect(visible.length, 1);
      });
    });
  });
}
