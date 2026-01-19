import 'package:flutter_test/flutter_test.dart';
import 'package:auther/services/validators.dart';
import 'package:auther/models/result.dart';

void main() {
  group('Validators', () {
    group('validatePassphrase', () {
      test('returns Failure for null passphrase', () {
        final result = Validators.validatePassphrase(null);
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, 'Passphrase cannot be empty');
      });

      test('returns Failure for empty passphrase', () {
        final result = Validators.validatePassphrase('');
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, 'Passphrase cannot be empty');
      });

      test('returns Failure for passphrase shorter than minimum', () {
        final result = Validators.validatePassphrase('abc');
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, contains('at least'));
      });

      test('returns Failure for passphrase longer than maximum', () {
        final longPassphrase = 'a' * 1001;
        final result = Validators.validatePassphrase(longPassphrase);
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, contains('at most'));
      });

      test('returns Success for valid passphrase', () {
        final result = Validators.validatePassphrase('validpassphrase');
        expect(result, isA<Success<String>>());
        expect(result.valueOrNull, 'validpassphrase');
      });

      test('trims whitespace from passphrase', () {
        final result = Validators.validatePassphrase('  validpassphrase  ');
        expect(result, isA<Success<String>>());
        expect(result.valueOrNull, 'validpassphrase');
      });
    });

    group('validatePersonName', () {
      test('returns Failure for null name', () {
        final result = Validators.validatePersonName(null);
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, 'Name cannot be empty');
      });

      test('returns Failure for empty name', () {
        final result = Validators.validatePersonName('');
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, 'Name cannot be empty');
      });

      test('returns Failure for whitespace-only name', () {
        final result = Validators.validatePersonName('   ');
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, 'Name cannot be empty');
      });

      test('returns Failure for name longer than maximum', () {
        final longName = 'a' * 101;
        final result = Validators.validatePersonName(longName);
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, contains('at most'));
      });

      test('returns Success for valid name', () {
        final result = Validators.validatePersonName('John Doe');
        expect(result, isA<Success<String>>());
        expect(result.valueOrNull, 'John Doe');
      });

      test('trims whitespace from name', () {
        final result = Validators.validatePersonName('  John Doe  ');
        expect(result, isA<Success<String>>());
        expect(result.valueOrNull, 'John Doe');
      });
    });

    group('validateHash', () {
      test('returns Failure for null hash', () {
        final result = Validators.validateHash(null);
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, 'Hash cannot be empty');
      });

      test('returns Failure for empty hash', () {
        final result = Validators.validateHash('');
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, 'Hash cannot be empty');
      });

      test('returns Failure for invalid hash format', () {
        final result = Validators.validateHash('not-a-valid-hash');
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, 'Invalid hash format');
      });

      test('returns Failure for hash with wrong length', () {
        final result = Validators.validateHash('abc123');
        expect(result, isA<Failure<String>>());
        expect(result.errorOrNull, 'Invalid hash format');
      });

      test('returns Success for valid 64-character hex hash', () {
        final validHash = 'a' * 64;
        final result = Validators.validateHash(validHash);
        expect(result, isA<Success<String>>());
        expect(result.valueOrNull, validHash);
      });
    });

    group('validateQrData', () {
      test('returns Failure for null QR data', () {
        final result = Validators.validateQrData(null);
        expect(result, isA<Failure<Map<String, dynamic>>>());
        expect(result.errorOrNull, 'QR code data is empty');
      });

      test('returns Failure for empty QR data', () {
        final result = Validators.validateQrData('');
        expect(result, isA<Failure<Map<String, dynamic>>>());
        expect(result.errorOrNull, 'QR code data is empty');
      });

      test('returns Failure for invalid QR format', () {
        final result = Validators.validateQrData('invalid-qr-code');
        expect(result, isA<Failure<Map<String, dynamic>>>());
        expect(result.errorOrNull, 'Invalid Auther QR code format');
      });

      test('returns Success for valid QR data', () {
        final validHash = 'a' * 64;
        final qrData = 'AutherX:12345:$validHash';
        final result = Validators.validateQrData(qrData);
        expect(result, isA<Success<Map<String, dynamic>>>());
        expect(result.valueOrNull?['slot'], 12345);
        expect(result.valueOrNull?['userHash'], validHash);
      });
    });
  });
}
