import '../../customization/config.dart';
import '../models/result.dart';
import '../services/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = SecureStorageService();

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<Result<void>> setPassphrase(String token) async {
    try {
      await _storage.write(key: Config.passphraseKey, value: token);
      return const Success(null);
    } catch (e) {
      logger.error('Failed to save passphrase', e, null, 'SecureStorageService');
      return Failure('Failed to save passphrase', e);
    }
  }

  Future<Result<String?>> getPassphrase() async {
    try {
      final value = await _storage.read(key: Config.passphraseKey);
      return Success(value);
    } catch (e) {
      logger.error('Failed to read passphrase', e, null, 'SecureStorageService');
      return Failure('Failed to read passphrase', e);
    }
  }

  Future<Result<void>> deletePassphrase() async {
    try {
      await _storage.delete(key: Config.passphraseKey);
      return const Success(null);
    } catch (e) {
      logger.error('Failed to delete passphrase', e, null, 'SecureStorageService');
      return Failure('Failed to delete passphrase', e);
    }
  }
}
