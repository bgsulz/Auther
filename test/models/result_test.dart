import 'package:flutter_test/flutter_test.dart';
import 'package:auther/models/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('isSuccess returns true', () {
        const result = Success(42);
        expect(result.isSuccess, true);
        expect(result.isFailure, false);
      });

      test('valueOrNull returns the value', () {
        const result = Success('hello');
        expect(result.valueOrNull, 'hello');
      });

      test('valueOr returns the value', () {
        const result = Success(42);
        expect(result.valueOr(0), 42);
      });

      test('errorOrNull returns null', () {
        const result = Success('hello');
        expect(result.errorOrNull, null);
      });

      test('map transforms the value', () {
        const result = Success(5);
        final mapped = result.map((v) => v * 2);
        expect(mapped, isA<Success<int>>());
        expect(mapped.valueOrNull, 10);
      });

      test('flatMap transforms to new Result', () {
        const result = Success(5);
        final mapped = result.flatMap((v) => Success(v.toString()));
        expect(mapped, isA<Success<String>>());
        expect(mapped.valueOrNull, '5');
      });

      test('when calls success callback', () {
        const result = Success(42);
        int? capturedValue;
        result.when(
          success: (v) => capturedValue = v,
          failure: (m, e) => fail('Should not call failure'),
        );
        expect(capturedValue, 42);
      });

      test('equality works correctly', () {
        expect(const Success(42), const Success(42));
        expect(const Success(42), isNot(const Success(43)));
        expect(const Success(42), isNot(const Success('42')));
      });

      test('toString returns readable format', () {
        expect(const Success(42).toString(), 'Success(42)');
      });
    });

    group('Failure', () {
      test('isFailure returns true', () {
        const result = Failure<int>('error');
        expect(result.isFailure, true);
        expect(result.isSuccess, false);
      });

      test('valueOrNull returns null', () {
        const result = Failure<String>('error');
        expect(result.valueOrNull, null);
      });

      test('valueOr returns the default value', () {
        const result = Failure<int>('error');
        expect(result.valueOr(42), 42);
      });

      test('errorOrNull returns the error message', () {
        const result = Failure<String>('Something went wrong');
        expect(result.errorOrNull, 'Something went wrong');
      });

      test('map preserves the failure', () {
        const result = Failure<int>('error');
        final mapped = result.map((v) => v * 2);
        expect(mapped, isA<Failure<int>>());
        expect(mapped.errorOrNull, 'error');
      });

      test('flatMap preserves the failure', () {
        const result = Failure<int>('error');
        final mapped = result.flatMap((v) => Success(v.toString()));
        expect(mapped, isA<Failure<String>>());
        expect(mapped.errorOrNull, 'error');
      });

      test('when calls failure callback', () {
        const result = Failure<int>('error message', 'error object');
        String? capturedMessage;
        Object? capturedError;
        result.when(
          success: (v) => fail('Should not call success'),
          failure: (m, e) {
            capturedMessage = m;
            capturedError = e;
          },
        );
        expect(capturedMessage, 'error message');
        expect(capturedError, 'error object');
      });

      test('equality works correctly', () {
        expect(const Failure<int>('error'), const Failure<int>('error'));
        expect(const Failure<int>('error'), isNot(const Failure<int>('other')));
        expect(
          const Failure<int>('error', 'obj'),
          const Failure<int>('error', 'obj'),
        );
      });

      test('toString returns readable format', () {
        expect(const Failure<int>('error').toString(), 'Failure(error)');
        expect(
          const Failure<int>('error', 'obj').toString(),
          'Failure(error, obj)',
        );
      });
    });

    group('Pattern matching', () {
      test('switch expression works with Success', () {
        const Result<int> result = Success(42);
        final output = switch (result) {
          Success(value: final v) => 'Got $v',
          Failure(message: final m) => 'Error: $m',
        };
        expect(output, 'Got 42');
      });

      test('switch expression works with Failure', () {
        const Result<int> result = Failure('oops');
        final output = switch (result) {
          Success(value: final v) => 'Got $v',
          Failure(message: final m) => 'Error: $m',
        };
        expect(output, 'Error: oops');
      });
    });
  });
}
