import 'package:auther/models/result.dart';
import 'package:auther/repositories/secure_storage_repository.dart';
import 'package:auther/services/auth_service.dart';
import 'package:auther/services/passphrase_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecureStorageService extends SecureStorageService {
  String? value;
  bool failRead = false;
  bool failWrite = false;
  bool failDelete = false;

  @override
  Future<Result<void>> setPassphrase(String token) async {
    if (failWrite) {
      return const Failure('Failed to save passphrase');
    }
    value = token;
    return const Success(null);
  }

  @override
  Future<Result<String?>> getPassphrase() async {
    if (failRead) {
      return const Failure('Failed to read passphrase');
    }
    return Success(value);
  }

  @override
  Future<Result<void>> deletePassphrase() async {
    if (failDelete) {
      return const Failure('Failed to delete passphrase');
    }
    value = null;
    return const Success(null);
  }
}

void main() {
  group('PassphraseService', () {
    late FakeSecureStorageService storage;
    late PassphraseService service;

    setUp(() {
      storage = FakeSecureStorageService();
      service = PassphraseService(secureStorage: storage);
    });

    test('rejects non-JSON legacy storage format', () async {
      storage.value = AutherAuth.hashPassphrase('legacy-pass');

      final result = await service.validatePassphrase('legacy-pass');

      expect(result.isSuccess, true);
      expect(result.valueOr(false), false);
    });

    test('rejects malformed storage payload', () async {
      storage.value = 'not-json';

      final result = await service.validatePassphrase('wrong-pass');

      expect(result.isSuccess, true);
      expect(result.valueOr(false), false);
    });

    test('getStoredHash returns empty for malformed payload', () async {
      storage.value = 'not-json';

      final result = await service.getStoredHash();

      expect(result.isSuccess, true);
      expect(result.valueOr('fallback'), '');
    });
  });
}
